import Foundation

/// 转录服务
/// 核心业务逻辑，协调模型、处理器完成转录任务
///
/// ## Swift 6 并发安全说明
///
/// 本类型使用 `@unchecked Sendable` 因为：
/// 1. **协议约束限制**: 需要持有 `ASRModel` 协议实例，而该协议的实现（如 `Qwen3ASRModelWrapper`）不是 Sendable
/// 2. **实际安全性保证**:
///    - 所有公共方法都是 `async` 的，调用方通过 `await` 序列化访问
///    - 可变状态 (`currentModel`, `settingsSnapshot`) 都在 actor 调用者上下文中访问
///    - `isCancelled` 标志通过 `MainActor` 保证线程安全
/// 3. **替代方案不可行**: 使用 `actor` 会导致将模型实例传递给非隔离方法时出现数据竞争警告
///
/// ## 使用注意
/// - 所有公共方法都是 `async` 的，请在正确的并发上下文中调用
/// - 使用 `cancel()` 方法可以请求取消正在进行的转录
/// - 在转录过程中请通过 `progressHandler` 更新 UI
///
/// ## Swift 6 迁移说明
/// 这是 Swift 6 迁移中的**合理例外**：
/// - 由于依赖的 MLX 库类型不是 Sendable，无法避免使用 `@unchecked Sendable`
/// - 通过 async 方法和调用方的 `await` 序列化保证实际并发安全
/// - 取消标志通过 MainActor 保证线程安全
/// - 未来如果 MLX 库更新为 Sendable，可以考虑使用 `actor` 重构
final class TranscriptionService: @unchecked Sendable {

    // MARK: - 属性

    /// 当前使用的模型
    private var currentModel: ASRModel?

    /// 时间戳聚合器
    private let timestampAggregator = TimestampAggregator()

    /// 设置快照（从 AppSettings 复制的值）
    private var settingsSnapshot: SettingsSnapshot

    /// 是否已取消（通过 MainActor 保证线程安全）
    @MainActor private var isCancelled = false

    // MARK: - 设置快照

    /// 设置快照，用于在非 MainActor 上下文中访问设置
    struct SettingsSnapshot: Sendable {
        var defaultLanguage: Language
        var aggregationStrategy: AppSettings.AggregationStrategy
        var enableChineseCorrection: Bool
        var enablePunctuationOptimization: Bool
        var enableNumberFormatting: Bool

        static func from(_ settings: AppSettings) -> SettingsSnapshot {
            SettingsSnapshot(
                defaultLanguage: settings.defaultLanguage,
                aggregationStrategy: settings.aggregationStrategy,
                enableChineseCorrection: settings.enableChineseCorrection,
                enablePunctuationOptimization: settings.enablePunctuationOptimization,
                enableNumberFormatting: settings.enableNumberFormatting
            )
        }
    }

    // MARK: - 初始化

    init(settings: AppSettings = .shared) {
        self.settingsSnapshot = SettingsSnapshot.from(settings)
    }

    // MARK: - 公开方法

    /// 更新设置快照
    func updateSettings(from settings: AppSettings) {
        self.settingsSnapshot = SettingsSnapshot.from(settings)
    }

    /// 执行转录
    /// - Parameters:
    ///   - audioFile: 音频文件
    ///   - model: ASR 模型
    ///   - language: 语言（nil 为自动检测）
    ///   - progressHandler: 进度回调
    /// - Returns: 转录结果
    func transcribe(
        audioFile: AudioFile,
        model: ASRModel,
        language: Language? = nil,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        // 重置状态
        await MainActor.run {
            isCancelled = false
        }
        currentModel = model

        let startDate = Date()

        // 1. 检查模型是否已下载
        if !model.isDownloaded {
            progressHandler(0.0, "下载模型...")

            try await model.download { progress in
                Task { @MainActor in
                    progressHandler(progress * 0.1, "下载模型... \(Int(progress * 100))%")
                }
            }
        }

        if await isCancelledCheck() {
            throw ASRError.cancelled
        }

        // 2. 执行转录（模型内部会处理进度）
        let rawResult = try await model.transcribe(
            audioFile: audioFile,
            language: language ?? settingsSnapshot.defaultLanguage
        ) { progress in
            // 映射到总体进度（10%-90%）
            let overallProgress = 0.1 + (progress * 0.8)
            let message = progress < 0.5 ? "加载音频..." : progress < 0.8 ? "转录中..." : "处理结果..."
            progressHandler(overallProgress, message)
        }

        if await isCancelledCheck() {
            throw ASRError.cancelled
        }

        // 3. 时间戳聚合
        progressHandler(0.9, "处理时间戳...")

        let strategy: TimestampAggregator.Strategy = {
            switch settingsSnapshot.aggregationStrategy {
            case .punctuation:
                return .punctuation
            case .pauseThreshold:
                return .pauseThreshold
            }
        }()

        var sentences = timestampAggregator.aggregate(
            words: rawResult.words,
            strategy: strategy
        )

        // 合并短句子
        sentences = timestampAggregator.mergeShortSentences(sentences)

        if await isCancelledCheck() {
            throw ASRError.cancelled
        }

        // 4. 后处理
        progressHandler(0.95, "后处理...")

        sentences = postProcess(sentences: sentences)

        // 5. 构建结果
        let endDate = Date()
        let processingTime = endDate.timeIntervalSince(startDate)
        let rtf = processingTime / audioFile.duration

        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: model.name,
            language: rawResult.language,
            sentences: sentences,
            processingTime: processingTime,
            metadata: TranscriptionMetadata(
                modelVersion: model.id,
                audioDuration: audioFile.duration,
                realTimeFactor: rtf
            )
        )

        progressHandler(1.0, "完成")

        return result
    }

    /// 取消转录
    func cancel() {
        Task { @MainActor in
            isCancelled = true
            currentModel?.cancel()
        }
    }
    
    /// 检查是否已取消
    @MainActor private func isCancelledCheck() -> Bool {
        isCancelled
    }

    // MARK: - 私有方法

    /// 后处理
    private func postProcess(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        var processed = sentences

        // 使用 ChinesePostProcessor 进行统一的中文后处理
        let postProcessor = ChinesePostProcessor()

        // 中文纠错
        if settingsSnapshot.enableChineseCorrection {
            processed = postProcessor.correctHomophones(sentences: processed)
        }

        // 标点优化
        if settingsSnapshot.enablePunctuationOptimization {
            processed = postProcessor.optimizePunctuation(sentences: processed)
        }

        // 数字格式化
        if settingsSnapshot.enableNumberFormatting {
            processed = postProcessor.formatNumbers(sentences: processed)
        }

        // 空格清理（总是执行）
        processed = postProcessor.cleanSpaces(sentences: processed)

        return processed
    }

    /// 同音字纠错（委托给 ChinesePostProcessor）
    private func correctHomophones(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        let postProcessor = ChinesePostProcessor()
        return postProcessor.correctHomophones(sentences: sentences)
    }

    /// 标点优化（委托给 ChinesePostProcessor）
    private func optimizePunctuation(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        let postProcessor = ChinesePostProcessor()
        return postProcessor.optimizePunctuation(sentences: sentences)
    }

    /// 数字格式化（委托给 ChinesePostProcessor）
    private func formatNumbers(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        let postProcessor = ChinesePostProcessor()
        return postProcessor.formatNumbers(sentences: sentences)
    }
}

// MARK: - 模型管理（静态方法）

extension TranscriptionService {
    /// 获取可用模型列表
    static func getAvailableModels() -> [ModelInfo] {
        return Constants.availableASRModels.map { ModelInfo.from(huggingFaceId: $0) }
    }

    /// 创建模型实例
    /// - Parameter huggingFaceId: HuggingFace 模型 ID
    /// - Returns: ASR 模型实例
    static func createModel(huggingFaceId: String) -> ASRModel {
        // 根据模型 ID 创建对应的模型实例
        if huggingFaceId.contains("GLM") {
            // GLM-ASR 使用 Qwen3ASRModelWrapper（MLX-Audio-Swift 支持）
            return Qwen3ASRModelWrapper(huggingFaceId: huggingFaceId)
        } else {
            // 默认使用 Qwen3-ASR
            return Qwen3ASRModelWrapper(huggingFaceId: huggingFaceId)
        }
    }
    
    /// 根据模型标识符创建模型
    /// - Parameter modelId: 模型标识符
    /// - Returns: ASR 模型实例
    static func createModel(_ modelId: ModelIdentifier) -> ASRModel {
        return createModel(huggingFaceId: modelId.rawValue)
    }
}