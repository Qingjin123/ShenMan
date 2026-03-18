import Foundation

/// 模型注册表
/// 管理所有可用的 ASR 模型
final class ModelRegistry: Sendable {

    // MARK: - 单例

    static let shared = ModelRegistry()

    // MARK: - 属性

    /// 所有可用模型
    private let availableModels: [ModelInfo]

    /// 默认模型
    var defaultModel: ModelInfo {
        availableModels.first { $0.id == Constants.defaultASRModel } ?? availableModels[0]
    }

    // MARK: - 初始化

    init() {
        self.availableModels = Constants.availableASRModels.map { modelId in
            ModelInfo.from(huggingFaceId: modelId)
        }
    }

    // MARK: - 公开方法

    /// 获取所有可用模型
    /// - Returns: 模型信息列表
    func getAllModels() -> [ModelInfo] {
        availableModels
    }

    /// 根据 ID 获取模型
    /// - Parameter id: 模型 ID
    /// - Returns: 模型信息
    func getModel(id: String) -> ModelInfo? {
        availableModels.first { $0.id == id }
    }

    /// 根据名称获取模型
    /// - Parameter name: 模型名称
    /// - Returns: 模型信息
    func getModel(name: String) -> ModelInfo? {
        availableModels.first { $0.name == name }
    }

    /// 创建模型实例
    /// - Parameter modelId: 模型 ID
    /// - Returns: ASR 模型实例
    func createModel(id: String) -> ASRModel {
        // 使用 ModelIdentifier 确保类型安全
        if let modelId = ModelIdentifier(rawValue: id) {
            return Qwen3ASRModelWrapper(huggingFaceId: modelId.rawValue)
        }
        // 回退到默认模型
        return Qwen3ASRModelWrapper(huggingFaceId: Constants.defaultASRModel)
    }

    /// 检查模型是否已下载
    /// - Parameter modelId: 模型 ID
    /// - Returns: 是否已下载
    func isModelDownloaded(_ modelId: String) -> Bool {
        // 检查模型缓存目录
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return false
        }
        
        // MLX-Audio 模型目录结构：Cache/MLX-Audio/{model_id}
        let modelDirectory = cacheDirectory
            .appendingPathComponent("MLX-Audio", isDirectory: true)
            .appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "_"), isDirectory: true)
        
        // 检查关键文件是否存在
        let requiredFiles = ["config.json", "weights.safetensors"]
        for file in requiredFiles {
            let filePath = modelDirectory.appendingPathComponent(file, isDirectory: false)
            if !FileManager.default.fileExists(atPath: filePath.path) {
                return false
            }
        }
        
        return true
    }
}
