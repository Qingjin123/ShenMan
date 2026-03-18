import Foundation

/// ASR 模型协议
/// 所有语音识别模型必须实现此协议
/// 
/// 注意：由于 MLX 模型类型不是 Sendable 的，实现者可能使用 `@unchecked Sendable`
protocol ASRModel {
    /// 模型标识符
    var id: String { get }

    /// 模型名称（显示给用户）
    var name: String { get }

    /// 模型描述
    var description: String { get }

    /// 支持的语言列表
    var supportedLanguages: [Language] { get }

    /// 模型大小（GB）
    var sizeGB: Double { get }

    /// 是否已下载
    var isDownloaded: Bool { get }

    /// 模型路径
    var modelPath: URL? { get }

    /// 下载模型
    func download(progressHandler: @Sendable @escaping (Double) -> Void) async throws

    /// 转录音频
    /// - Parameters:
    ///   - audioFile: 音频文件
    ///   - language: 语言（nil 为自动检测）
    ///   - progressHandler: 进度回调
    /// - Returns: 原始转录结果
    func transcribe(
        audioFile: AudioFile,
        language: Language?,
        progressHandler: @Sendable @escaping (Double) -> Void
    ) async throws -> RawTranscriptionResult

    /// 取消转录
    func cancel()
}

// MARK: - ASR 错误

enum ASRError: LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case audioLoadFailed
    case inferenceFailed(String)
    case outOfMemory
    case cancelled
    case unsupportedLanguage

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "模型未找到，请先下载模型"
        case .modelLoadFailed:
            return "模型加载失败"
        case .audioLoadFailed:
            return "无法加载音频文件"
        case .inferenceFailed(let reason):
            return "转录失败：\(reason)"
        case .outOfMemory:
            return "内存不足，请关闭其他应用后重试"
        case .cancelled:
            return "转录已取消"
        case .unsupportedLanguage:
            return "不支持的语言"
        }
    }
}

// MARK: - 模型信息

/// 模型信息结构
struct ModelInfo: Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let huggingFaceId: String
    let sizeGB: Double
    let supportedLanguages: [Language]
    let isDownloaded: Bool

    init(
        id: String,
        name: String,
        description: String,
        huggingFaceId: String,
        sizeGB: Double,
        supportedLanguages: [Language],
        isDownloaded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.huggingFaceId = huggingFaceId
        self.sizeGB = sizeGB
        self.supportedLanguages = supportedLanguages
        self.isDownloaded = isDownloaded
    }

    /// 从 HuggingFace ID 创建模型信息
    static func from(huggingFaceId: String) -> ModelInfo {
        // 尝试从 ModelIdentifier 创建
        if let modelId = ModelIdentifier(rawValue: huggingFaceId) {
            return ModelInfo(
                id: modelId.rawValue,
                name: modelId.displayName,
                description: modelId.description,
                huggingFaceId: modelId.rawValue,
                sizeGB: modelId.sizeGB,
                supportedLanguages: modelId.supportedLanguages,
                isDownloaded: false
            )
        }
        
        // 回退到旧方式
        let components = huggingFaceId.components(separatedBy: "/")
        let modelName = components.last ?? huggingFaceId

        return ModelInfo(
            id: huggingFaceId,
            name: modelName,
            description: "自定义模型",
            huggingFaceId: huggingFaceId,
            sizeGB: 2.0,
            supportedLanguages: [.auto, .chinese, .english],
            isDownloaded: false
        )
    }
}