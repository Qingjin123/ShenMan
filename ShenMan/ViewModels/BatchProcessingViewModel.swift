import Foundation
import SwiftUI

/// 批量处理 ViewModel
/// 管理批量转录的状态和进度
@MainActor
final class BatchProcessingViewModel: ObservableObject {
    
    // MARK: - 属性
    
    /// 批量处理服务
    private let batchService = BatchProcessingService()
    
    /// 当前批次 ID
    let batchId: UUID
    
    /// 处理状态
    @Published var processingState: BatchProcessingState = .idle
    
    /// 当前进度 (0.0 - 1.0)
    @Published var progress: Double = 0.0
    
    /// 当前处理的任务索引
    @Published var currentTaskIndex: Int = 0
    
    /// 已完成的任务数量
    @Published var completedCount: Int = 0
    
    /// 失败的任务数量
    @Published var failedCount: Int = 0
    
    /// 总任务数量
    @Published var totalCount: Int = 0
    
    /// 当前处理的文件
    @Published var currentProcessingFile: String = ""
    
    /// 错误消息
    @Published var errorMessage: String?
    
    /// 转录结果
    @Published var results: [TranscriptionResult] = []
    
    // MARK: - 初始化
    
    init(batchId: UUID = UUID()) {
        self.batchId = batchId
    }
    
    // MARK: - 公开方法
    
    /// 添加文件到队列
    func addFiles(_ files: [AudioFile]) {
        Task {
            await batchService.addTasks(files)
            await MainActor.run {
                totalCount = files.count
            }
        }
    }
    
    /// 开始批量转录
    func startBatchTranscription(modelId: ModelIdentifier) async {
        processingState = .processing
        progress = 0.0
        errorMessage = nil
        results.removeAll()

        do {
            // 使用 Task 包裹 actor 调用
            let batchResults = try await batchService.startBatch(modelId: modelId)

            await MainActor.run {
                results = batchResults
                completedCount = batchResults.count
                processingState = .completed
                progress = 1.0
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                processingState = .failed
            }
        }
    }
    
    /// 取消批量处理
    func cancel() {
        Task {
            await batchService.cancel()
            await MainActor.run {
                processingState = .cancelled
            }
        }
    }
    
    /// 重置状态
    func reset() {
        processingState = .idle
        progress = 0.0
        currentTaskIndex = 0
        completedCount = 0
        failedCount = 0
        totalCount = 0
        currentProcessingFile = ""
        errorMessage = nil
        results.removeAll()
    }
    
    // MARK: - 计算属性
    
    /// 是否正在处理
    var isProcessing: Bool {
        processingState == .processing
    }
    
    /// 是否完成
    var isCompleted: Bool {
        processingState == .completed
    }
    
    /// 进度文本
    var progressText: String {
        String(format: "%.0f%%", progress * 100)
    }
    
    /// 状态描述
    var statusDescription: String {
        switch processingState {
        case .idle:
            return "准备就绪"
        case .processing:
            return "处理中：\(currentProcessingFile)"
        case .completed:
            return "完成，共 \(completedCount) 个文件"
        case .failed:
            return "失败：\(errorMessage ?? "未知错误")"
        case .cancelled:
            return "已取消"
        }
    }
}

// MARK: - 处理状态

enum BatchProcessingState: Equatable {
    case idle       // 空闲
    case processing // 处理中
    case completed  // 完成
    case failed     // 失败
    case cancelled  // 已取消
}
