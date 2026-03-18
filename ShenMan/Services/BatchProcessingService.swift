import Foundation

/// 批量处理服务
/// 负责管理多个音频文件的批量转录
///
/// ## v1.0 功能
/// - 支持一次导入多个文件
/// - 队列处理（自动处理下一个）
/// - 支持取消整个批次或单个任务
/// - 批量导出功能
///
/// ## 并发安全
/// 使用 `actor` 保证并发安全，所有方法都是 `async` 的
actor BatchProcessingService {

    // MARK: - 属性

    /// 当前批次 ID
    private let batchId: UUID

    /// 队列中的任务
    private var tasks: [BatchTask] = []

    /// 是否正在处理
    private var isProcessing = false

    /// 当前处理的任务索引
    private var currentTaskIndex = 0

    /// 转录服务
    private let transcriptionService = TranscriptionService()

    /// 取消标志
    private var isCancelled = false

    // MARK: - 批量任务

    /// 批量处理任务
    struct BatchTask: Identifiable, Sendable {
        let id: UUID
        let audioFile: AudioFile
        var status: BatchTaskStatus
        var progress: Double
        var result: TranscriptionResult?
        var errorMessage: String?

        init(
            id: UUID = UUID(),
            audioFile: AudioFile,
            status: BatchTaskStatus = .pending,
            progress: Double = 0,
            result: TranscriptionResult? = nil,
            errorMessage: String? = nil
        ) {
            self.id = id
            self.audioFile = audioFile
            self.status = status
            self.progress = progress
            self.result = result
            self.errorMessage = errorMessage
        }
    }

    // MARK: - 初始化

    init(batchId: UUID = UUID()) {
        self.batchId = batchId
    }

    // MARK: - 公开方法

    /// 添加任务到队列
    /// - Parameter audioFile: 音频文件
    func addTask(_ audioFile: AudioFile) {
        let task = BatchTask(audioFile: audioFile)
        tasks.append(task)
    }

    /// 添加多个任务到队列
    /// - Parameter audioFiles: 音频文件列表
    func addTasks(_ audioFiles: [AudioFile]) {
        for audioFile in audioFiles {
            addTask(audioFile)
        }
    }

    /// 开始批量处理
    /// - Parameter modelId: 模型 ID
    /// - Returns: 完成的转录结果列表
    /// - Throws: BatchProcessingError 当批次为空或所有任务失败时
    func startBatch(modelId: ModelIdentifier) async throws -> [TranscriptionResult] {
        guard !tasks.isEmpty else {
            throw BatchProcessingError.emptyBatch
        }

        isProcessing = true
        isCancelled = false
        currentTaskIndex = 0

        var results: [TranscriptionResult] = []
        var failedCount = 0

        for index in 0..<tasks.count {
            if isCancelled {
                break
            }

            currentTaskIndex = index
            var task = tasks[index]

            // 更新状态为处理中
            task.status = .processing
            tasks[index] = task

            do {
                // 创建模型
                let model = TranscriptionService.createModel(modelId)

                // 执行转录
                let result = try await transcriptionService.transcribe(
                    audioFile: task.audioFile,
                    model: model,
                    language: nil
                ) { progress, message in
                    // 进度回调由模型内部处理
                }

                // 更新任务状态
                task.status = .completed
                task.progress = 1.0
                task.result = result
                tasks[index] = task

                results.append(result)

            } catch {
                // 更新任务状态为失败
                task.status = .failed
                task.errorMessage = error.localizedDescription
                tasks[index] = task
                failedCount += 1
            }
        }

        isProcessing = false
        
        // 检查是否所有任务都失败
        if failedCount == tasks.count && results.isEmpty {
            throw BatchProcessingError.allTasksFailed
        }
        
        return results
    }

    /// 取消批量处理
    func cancel() {
        isCancelled = true
        transcriptionService.cancel()

        // 更新所有待处理任务的状态
        for index in 0..<tasks.count {
            if tasks[index].status == .pending {
                tasks[index].status = .cancelled
            }
        }
    }

    /// 取消单个任务
    /// - Parameter taskId: 任务 ID
    func cancelTask(taskId: UUID) {
        for index in 0..<tasks.count {
            if tasks[index].id == taskId {
                if tasks[index].status == .pending {
                    tasks[index].status = .cancelled
                }
                break
            }
        }
    }

    /// 移除已完成的任务
    func removeCompletedTasks() {
        tasks.removeAll { $0.status == .completed }
    }

    /// 移除失败的任务
    func removeFailedTasks() {
        tasks.removeAll { $0.status == .failed }
    }

    /// 清除所有任务
    func clearAllTasks() {
        tasks.removeAll()
        isProcessing = false
        currentTaskIndex = 0
        isCancelled = false
    }

    // MARK: - 计算属性

    /// 获取待处理任务数量
    var pendingTaskCount: Int {
        tasks.filter { $0.status == .pending }.count
    }

    /// 获取已完成任务数量
    var completedTaskCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    /// 获取失败任务数量
    var failedTaskCount: Int {
        tasks.filter { $0.status == .failed }.count
    }

    /// 获取总体进度
    var overallProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTaskCount) / Double(tasks.count)
    }

    /// 获取当前处理的任务
    var currentTask: BatchTask? {
        guard currentTaskIndex < tasks.count else { return nil }
        return tasks[currentTaskIndex]
    }
    
    /// 获取所有任务
    var allTasks: [BatchTask] {
        tasks
    }
}

// MARK: - 批量任务状态

enum BatchTaskStatus: String, Sendable {
    case pending = "等待中"
    case processing = "处理中"
    case completed = "已完成"
    case failed = "失败"
    case cancelled = "已取消"
}

// MARK: - 批量处理错误

enum BatchProcessingError: LocalizedError {
    case emptyBatch
    case allTasksFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .emptyBatch:
            return "批量处理队列为空"
        case .allTasksFailed:
            return "所有任务都失败了"
        case .cancelled:
            return "批量处理已取消"
        }
    }
}
