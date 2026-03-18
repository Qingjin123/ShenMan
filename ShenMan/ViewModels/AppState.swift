import Foundation
import SwiftUI

/// 应用全局状态
/// 管理应用的导航、当前任务和用户设置
@MainActor
final class AppState: ObservableObject {

    // MARK: - 导航状态

    /// 当前视图
    @Published var currentView: AppView = .home

    /// 是否显示文件导入器
    @Published var showFileImporter = false

    /// 是否显示设置页面
    @Published var showSettings = false

    /// 是否显示导出对话框
    @Published var showExportSheet = false

    /// 是否显示历史记录页面
    @Published var showHistory = false

    /// 是否显示模型选择页面
    @Published var showModelPicker = false

    /// 是否显示批量导入页面
    @Published var showBatchImport = false

    /// 是否显示批量导出页面
    @Published var showBatchExport = false
    
    /// 批量导出的结果
    @Published var batchExportResults: [TranscriptionResult] = []

    // MARK: - 转录状态

    /// 当前音频文件
    @Published var currentAudioFile: AudioFile?

    /// 当前转录结果
    @Published var currentResult: TranscriptionResult?

    /// 转录进度 (0.0 - 1.0)
    @Published var transcriptionProgress: Double = 0

    /// 转录状态消息
    @Published var transcriptionStatusMessage: String = ""

    /// 预计剩余时间
    @Published var estimatedTimeRemaining: TimeInterval = 0

    /// 是否正在转录
    @Published var isTranscribing: Bool = false

    /// 错误消息
    @Published var errorMessage: String?

    /// 上次导出路径
    @Published var lastExportPath: URL?

    /// 当前转录任务
    var currentTask: Task<Void, Never>?

    /// 转录服务
    private let transcriptionService = TranscriptionService()

    /// 历史记录仓库
    private let historyRepository = HistoryRepository.shared

    /// 设置
    @Published var settings: AppSettings = .shared

    // MARK: - 历史记录

    /// 转录历史（内存缓存）
    @Published var transcriptionHistory: [TranscriptionResult] = []

    // MARK: - 嵌套类型

    /// 应用视图枚举
    enum AppView: Equatable {
        case home           // 主页
        case transcribing   // 转录中
        case result         // 结果展示
    }

    // MARK: - 初始化

    /// 加载历史记录的 Task
    private var loadHistoryTask: Task<Void, Never>?

    init() {
        // 从持久化存储加载历史记录
        loadHistoryTask = Task {
            await loadHistoryFromRepository()
        }
    }

    deinit {
        // 清理 Task
        loadHistoryTask?.cancel()
        currentTask?.cancel()
    }

    // MARK: - 公开方法

    /// 加载音频文件
    /// - Parameter url: 文件 URL
    func loadAudioFile(url: URL) async {
        do {
            let audioFile = try await AudioMetadataReader.readMetadata(from: url)
            currentAudioFile = audioFile
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// 加载音频文件并开始转录
    /// - Parameter url: 文件 URL
    func loadAndTranscribeAudioFile(url: URL) async {
        await loadAudioFile(url: url)
        
        // 如果加载成功，开始转录
        if currentAudioFile != nil {
            await MainActor.run {
                startTranscription()
            }
        }
    }

    /// 开始转录
    func startTranscription() {
        guard let audioFile = currentAudioFile else { return }

        currentView = .transcribing
        isTranscribing = true
        transcriptionProgress = 0
        transcriptionStatusMessage = "准备转录..."
        errorMessage = nil
        transcriptionStartDate = Date()

        // 使用明确的捕获列表，避免内存泄漏
        currentTask = Task { [weak self] in
            guard let strongSelf = self else { return }

            do {
                // 创建模型
                let model = TranscriptionService.createModel(
                    huggingFaceId: strongSelf.settings.selectedModel
                )

                // 执行转录
                let result = try await strongSelf.transcriptionService.transcribe(
                    audioFile: audioFile,
                    model: model,
                    language: strongSelf.settings.defaultLanguage
                ) { progress, message in
                    Task { @MainActor in
                        // 使用 weak self 避免循环引用
                        guard let self = self else { return }
                        self.transcriptionProgress = progress
                        self.transcriptionStatusMessage = message

                        // 计算预计剩余时间
                        if progress > 0.1 {
                            let elapsed = Date().timeIntervalSince(self.transcriptionStartDate)
                            let totalEstimated = elapsed / progress
                            self.estimatedTimeRemaining = totalEstimated * (1 - progress)
                        }
                    }
                }

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.currentResult = result
                    self.currentView = .result
                    self.isTranscribing = false
                    
                    // 保存到历史记录
                    Task {
                        await self.saveToHistory(result: result)
                    }
                }
            } catch is CancellationError {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.currentView = .home
                    self.isTranscribing = false
                    self.transcriptionStatusMessage = "已取消"
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = error.localizedDescription
                    self.currentView = .home
                    self.isTranscribing = false
                }
            }
        }
    }

    /// 转录开始时间（用于计算剩余时间）
    private var transcriptionStartDate = Date()

    /// 取消转录
    func cancelTranscription() {
        currentTask?.cancel()
        currentTask = nil
        isTranscribing = false
        currentView = .home
        transcriptionProgress = 0
        transcriptionStatusMessage = ""
    }

    /// 重置状态
    func reset() {
        currentAudioFile = nil
        currentResult = nil
        transcriptionProgress = 0
        transcriptionStatusMessage = ""
        estimatedTimeRemaining = 0
        isTranscribing = false
        errorMessage = nil
        currentView = .home
    }

    /// 显示错误
    /// - Parameter message: 错误消息
    func showError(_ message: String) {
        errorMessage = message
    }

    /// 清除错误
    func clearError() {
        errorMessage = nil
    }

    // MARK: - 历史记录管理

    /// 从仓库加载历史记录
    private func loadHistoryFromRepository() async {
        // 从 HistoryRepository 加载历史记录并转换为 TranscriptionResult
        let records = await historyRepository.getRecentHistory(limit: 20)
        
        await MainActor.run {
            transcriptionHistory = records.compactMap { record in
                // 从历史记录重建 TranscriptionResult
                guard let audioFile = record.audioFile else { return nil }
                
                let sentences = record.transcript
                    .components(separatedBy: "\n")
                    .map { text in
                        SentenceTimestamp(text: text, startTime: 0, endTime: record.duration)
                    }
                
                return TranscriptionResult(
                    audioFile: audioFile,
                    modelName: record.modelId,
                    language: record.language,
                    sentences: sentences,
                    processingTime: record.processingTime,
                    metadata: TranscriptionMetadata(
                        modelVersion: record.modelId,
                        audioDuration: record.duration,
                        realTimeFactor: record.realTimeFactor
                    )
                )
            }
        }
    }

    /// 保存转录结果到历史记录
    func saveToHistory(result: TranscriptionResult) async {
        let transcript = result.sentences.map { $0.text }.joined(separator: "\n")
        await historyRepository.addHistoryRecord(from: result, transcript: transcript)
        
        // 同时更新内存缓存
        await MainActor.run {
            transcriptionHistory.insert(result, at: 0)
        }
    }

    /// 删除历史记录
    func deleteHistoryRecord(id: UUID) async {
        // await historyRepository.deleteHistoryRecord(id: id)
    }

    // MARK: - 私有方法

    /// 创建模拟转录结果（用于测试）
    private func createMockResult(for audioFile: AudioFile) -> TranscriptionResult {
        let sentences = [
            SentenceTimestamp(
                text: "这是一段示例转录文本。",
                startTime: 0,
                endTime: 3.5
            ),
            SentenceTimestamp(
                text: "实际的转录功能将在集成 ASR 模型后实现。",
                startTime: 3.5,
                endTime: 7.2
            ),
            SentenceTimestamp(
                text: "感谢您使用声声慢！",
                startTime: 7.2,
                endTime: 9.0
            )
        ]

        return TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR-0.6B",
            language: "zh",
            sentences: sentences,
            processingTime: audioFile.duration * 0.2,
            metadata: TranscriptionMetadata(
                modelVersion: "Qwen3-ASR-0.6B",
                audioDuration: audioFile.duration,
                realTimeFactor: 0.2
            )
        )
    }
}