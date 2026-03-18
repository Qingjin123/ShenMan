import Foundation

/// 转录任务状态
enum TranscriptionTaskStatus: String, Sendable {
    case pending = "等待中"
    case processing = "处理中"
    case completed = "已完成"
    case failed = "失败"
    case cancelled = "已取消"
}

/// 转录任务
struct TranscriptionTask: Identifiable, Sendable {
    let id: UUID
    let audioFile: AudioFile
    var status: TranscriptionTaskStatus
    var progress: Double
    var result: TranscriptionResult?
    var errorMessage: String?
    let createdAt: Date
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        audioFile: AudioFile,
        status: TranscriptionTaskStatus = .pending,
        progress: Double = 0,
        result: TranscriptionResult? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.audioFile = audioFile
        self.status = status
        self.progress = progress
        self.result = result
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

/// 转录历史记录
struct TranscriptionHistory: Sendable {
    let id: UUID
    let task: TranscriptionTask
    let exportedFormats: [String]
    var isFavorite: Bool
    let tags: [String]
    
    init(
        id: UUID = UUID(),
        task: TranscriptionTask,
        exportedFormats: [String] = [],
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.task = task
        self.exportedFormats = exportedFormats
        self.isFavorite = isFavorite
        self.tags = tags
    }
}

/// 批量处理队列
@MainActor
class BatchProcessingQueue: ObservableObject {
    // MARK: - 属性
    
    @Published var tasks: [TranscriptionTask] = []
    @Published var isProcessing: Bool = false
    @Published var currentTaskIndex: Int = 0
    @Published var totalProgress: Double = 0
    
    private let transcriptionService = TranscriptionService()
    private var currentTask: Task<Void, Never>?
    
    // MARK: - 计算属性
    
    var pendingTasks: [TranscriptionTask] {
        tasks.filter { $0.status == .pending }
    }
    
    var completedTasks: [TranscriptionTask] {
        tasks.filter { $0.status == .completed }
    }
    
    var failedTasks: [TranscriptionTask] {
        tasks.filter { $0.status == .failed }
    }
    
    var overallProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }
    
    // MARK: - 公开方法
    
    /// 添加任务到队列
    func addTask(audioFile: AudioFile) {
        let task = TranscriptionTask(audioFile: audioFile)
        tasks.append(task)
    }
    
    /// 添加多个任务
    func addTasks(audioFiles: [AudioFile]) {
        for audioFile in audioFiles {
            addTask(audioFile: audioFile)
        }
    }
    
    /// 移除任务
    func removeTask(_ task: TranscriptionTask) {
        tasks.removeAll { $0.id == task.id }
    }
    
    /// 清除已完成任务
    func clearCompleted() {
        tasks.removeAll { $0.status == .completed }
    }
    
    /// 清除所有任务
    func clearAll() {
        tasks.removeAll()
        isProcessing = false
        currentTaskIndex = 0
        totalProgress = 0
    }
    
    /// 开始处理队列
    func startProcessing() async {
        guard !isProcessing && !pendingTasks.isEmpty else { return }
        
        isProcessing = true
        currentTaskIndex = 0
        
        for (index, task) in tasks.enumerated() {
            guard task.status == .pending else { continue }
            
            currentTaskIndex = index
            await processTask(task)
        }
        
        isProcessing = false
    }
    
    /// 取消处理
    func cancelProcessing() {
        currentTask?.cancel()
        isProcessing = false
        
        for index in tasks.indices {
            if tasks[index].status == .pending {
                tasks[index].status = .cancelled
            }
        }
    }
    
    /// 重试失败的任务
    func retryFailedTasks() async {
        let failedTaskIds = failedTasks.map { $0.id }
        
        for taskId in failedTaskIds {
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index].status = .pending
                tasks[index].progress = 0
                tasks[index].errorMessage = nil
            }
        }
        
        await startProcessing()
    }
    
    // MARK: - 私有方法
    
    private func processTask(_ task: TranscriptionTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].status = .processing
        
        do {
            let model = TranscriptionService.createModel(
                huggingFaceId: AppSettings.shared.selectedModel
            )
            
            let result = try await transcriptionService.transcribe(
                audioFile: task.audioFile,
                model: model,
                language: AppSettings.shared.defaultLanguage
            ) { progress, message in
                Task { @MainActor in
                    self.tasks[index].progress = progress
                }
            }
            
            tasks[index].status = .completed
            tasks[index].result = result
            tasks[index].completedAt = Date()
            tasks[index].progress = 1.0
            
        } catch {
            tasks[index].status = .failed
            tasks[index].errorMessage = error.localizedDescription
        }
    }
}
