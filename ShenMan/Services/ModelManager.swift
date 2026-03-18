import Foundation

/// 模型管理器
/// 负责模型的下载、更新和生命周期管理
actor ModelManager {

    // MARK: - 属性

    private let modelRegistry: ModelRegistry
    private let settingsRepository: SettingsRepository

    /// 当前已下载的模型
    private var downloadedModels: Set<String> = []

    /// 当前正在下载的模型
    private var downloadingModels: Set<String> = []

    // MARK: - 初始化

    init(
        modelRegistry: ModelRegistry = .shared,
        settingsRepository: SettingsRepository = SettingsRepository()
    ) {
        self.modelRegistry = modelRegistry
        self.settingsRepository = settingsRepository
    }

    // MARK: - 公开方法

    /// 获取所有可用模型
    /// - Returns: 模型信息列表
    func getAllModels() async -> [ModelInfo] {
        modelRegistry.getAllModels()
    }

    /// 获取默认模型
    /// - Returns: 默认模型信息
    func getDefaultModel() async -> ModelInfo {
        modelRegistry.defaultModel
    }

    /// 下载模型
    /// - Parameters:
    ///   - modelId: 模型 ID
    ///   - progressHandler: 进度回调
    func downloadModel(
        _ modelId: String,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        guard !downloadingModels.contains(modelId) else {
            throw ModelError.alreadyDownloading
        }

        guard !downloadedModels.contains(modelId) else {
            // 模型已下载
            progressHandler(1.0)
            return
        }

        downloadingModels.insert(modelId)
        defer {
            downloadingModels.remove(modelId)
        }

        do {
            // 创建模型并下载
            let model = modelRegistry.createModel(id: modelId)
            try await model.download(progressHandler: progressHandler)
            downloadedModels.insert(modelId)
        } catch {
            throw ModelError.downloadFailed(error.localizedDescription)
        }
    }

    /// 取消下载
    /// - Parameter modelId: 模型 ID
    func cancelDownload(_ modelId: String) {
        guard downloadingModels.contains(modelId) else { return }

        // 使用 ASRModel 协议的 cancel 方法
        // 注意：这里不能直接访问具体类型，因为 ModelManager 不应该依赖具体的 MLX 类型
        // cancel 状态会在 transcribe 方法中通过 isCancelled 检查
        downloadingModels.remove(modelId)
    }

    /// 检查模型是否已下载
    /// - Parameter modelId: 模型 ID
    /// - Returns: 是否已下载
    func isModelDownloaded(_ modelId: String) -> Bool {
        downloadedModels.contains(modelId) || modelRegistry.isModelDownloaded(modelId)
    }

    /// 获取已下载的模型列表
    /// - Returns: 已下载的模型 ID 列表
    func getDownloadedModels() -> [String] {
        Array(downloadedModels)
    }

    /// 删除模型
    /// - Parameter modelId: 模型 ID
    func deleteModel(_ modelId: String) throws {
        // 检查是否在已下载集合中或文件系统中存在
        guard isModelDownloaded(modelId) else {
            throw ModelError.modelNotFound
        }

        // 删除模型文件
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw ModelError.deleteFailed
        }
        
        let modelDir = cacheDirectory
            .appendingPathComponent("MLX-Audio", isDirectory: true)
            .appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "_"), isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: modelDir.path) else {
            throw ModelError.modelNotFound
        }
        
        // 实际删除文件
        try FileManager.default.removeItem(at: modelDir)
        
        // 从内存中移除
        downloadedModels.remove(modelId)
    }

    /// 预下载模型
    /// - Parameter modelId: 模型 ID
    func preloadModel(_ modelId: String) async throws {
        guard !isModelDownloaded(modelId) else { return }

        try await downloadModel(modelId) { _ in }
    }
}

// MARK: - 模型错误

enum ModelError: LocalizedError {
    case modelNotFound
    case alreadyDownloading
    case downloadFailed(String)
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "模型未找到"
        case .alreadyDownloading:
            return "模型正在下载中"
        case .downloadFailed(let reason):
            return "下载失败：\(reason)"
        case .deleteFailed:
            return "删除失败"
        }
    }
}
