import Foundation

/// 设置仓库
/// 负责用户设置的持久化存储
final class SettingsRepository {

    // MARK: - 属性

    private let userDefaults: UserDefaults

    // MARK: - 初始化

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - 公开方法

    /// 保存设置值
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    func setValue(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取设置值
    /// - Parameter key: 键
    /// - Returns: 值
    func value(forKey key: String) -> Any? {
        userDefaults.object(forKey: key)
    }

    /// 获取字符串值
    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    /// 获取布尔值
    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }

    /// 获取整数值
    func integer(forKey key: String) -> Int {
        userDefaults.integer(forKey: key)
    }

    /// 获取 URL
    func url(forKey key: String) -> URL? {
        userDefaults.url(forKey: key)
    }

    /// 保存设置
    func save() {
        userDefaults.synchronize()
    }

    /// 重置设置为默认值
    func resetToDefaults() {
        let keys = [
            Keys.selectedModel,
            Keys.autoDownloadModels,
            Keys.defaultLanguage,
            Keys.enableLanguageDetection,
            Keys.includeTimestamp,
            Keys.timestampPosition,
            Keys.timestampPrecision,
            Keys.aggregationStrategy,
            Keys.defaultExportFormat,
            Keys.enableChineseCorrection,
            Keys.enablePunctuationOptimization,
            Keys.enableNumberFormatting,
            Keys.enableLogging,
            Keys.maxConcurrentTasks,
            Keys.lastExportPath
        ]

        for key in keys {
            userDefaults.removeObject(forKey: key)
        }

        userDefaults.synchronize()
    }

    /// 获取模型下载路径
    /// - Parameter modelId: 模型 ID
    /// - Returns: 模型下载路径 URL
    func modelDownloadPath(for modelId: String) -> URL? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let modelsDirectory = cachesDirectory.appendingPathComponent("Models")
        let modelDirectory = modelsDirectory.appendingPathComponent(modelId)
        return modelDirectory
    }

    /// 检查模型是否已下载
    /// - Parameter modelId: 模型 ID
    /// - Returns: 是否已下载
    func isModelDownloaded(_ modelId: String) -> Bool {
        guard let path = modelDownloadPath(for: modelId) else {
            return false
        }
        return FileManager.default.fileExists(atPath: path.path)
    }
}

// MARK: - Keys

extension SettingsRepository {
    enum Keys {
        static let selectedModel = "settings.selectedModel"
        static let autoDownloadModels = "settings.autoDownloadModels"
        static let defaultLanguage = "settings.defaultLanguage"
        static let enableLanguageDetection = "settings.enableLanguageDetection"
        static let includeTimestamp = "settings.includeTimestamp"
        static let timestampPosition = "settings.timestampPosition"
        static let timestampPrecision = "settings.timestampPrecision"
        static let aggregationStrategy = "settings.aggregationStrategy"
        static let defaultExportFormat = "settings.defaultExportFormat"
        static let lastExportPath = "settings.lastExportPath"
        static let enableChineseCorrection = "settings.enableChineseCorrection"
        static let enablePunctuationOptimization = "settings.enablePunctuationOptimization"
        static let enableNumberFormatting = "settings.enableNumberFormatting"
        static let enableLogging = "settings.enableLogging"
        static let maxConcurrentTasks = "settings.maxConcurrentTasks"
    }
}
