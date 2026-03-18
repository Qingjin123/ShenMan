import Foundation
import SwiftUI

/// 应用设置
/// 管理用户偏好配置
///
/// ## Swift 6 并发安全说明
///
/// 本类型使用 `@unchecked Sendable` 因为：
/// 1. **ObservableObject 限制**: 作为 SwiftUI 的 ObservableObject，需要在 MainActor 上运行
/// 2. **@Published 属性包装器**: @Published 属性需要在可变 self 上操作，与 Sendable 冲突
/// 3. **实际安全性**: 所有 @Published 属性都通过 @MainActor 保证隔离
///
/// ## 使用注意
/// - 所有 @Published 属性自动在 MainActor 上同步
/// - 避免在非 MainActor 上下文中直接访问可变状态
///
/// ## Swift 6 迁移说明
/// 这是 Swift 6 迁移中的**合理例外**：
/// - SwiftUI 的 ObservableObject 模式与 Sendable 不兼容
/// - 通过 @MainActor 和 @Published 保证实际并发安全
final class AppSettings: ObservableObject, @unchecked Sendable {

    // MARK: - 单例

    static let shared = AppSettings()

    // MARK: - 模型设置

    /// 当前选中的模型名称
    @Published var selectedModel: String = Constants.defaultASRModel

    /// 是否自动下载模型
    @Published var autoDownloadModels: Bool = true

    // MARK: - 语言设置

    /// 默认语言
    @Published var defaultLanguage: Language = .auto

    /// 是否启用语言检测
    @Published var enableLanguageDetection: Bool = true

    // MARK: - 转录设置

    /// 是否包含时间戳
    @Published var includeTimestamp: Bool = true

    /// 时间戳位置
    @Published var timestampPosition: TimestampPosition = .start

    /// 时间戳精度
    @Published var timestampPrecision: TimestampPrecision = .milliseconds

    /// 聚合策略
    @Published var aggregationStrategy: AggregationStrategy = .punctuation

    // MARK: - 导出设置

    /// 默认导出格式
    @Published var defaultExportFormat: ExportFormat = .txt

    /// 上次导出路径
    @Published var lastExportPath: URL?

    // MARK: - 后处理设置

    /// 是否启用中文纠错
    @Published var enableChineseCorrection: Bool = true

    /// 是否启用标点优化
    @Published var enablePunctuationOptimization: Bool = true

    /// 是否启用数字格式化
    @Published var enableNumberFormatting: Bool = true

    // MARK: - 高级设置

    /// 是否启用日志
    @Published var enableLogging: Bool = false

    /// 最大并发任务数
    @Published var maxConcurrentTasks: Int = 1

    // MARK: - 嵌套类型

    /// 时间戳位置
    enum TimestampPosition: String, CaseIterable, Identifiable, Codable, Sendable {
        case start  // 句首
        case end    // 句尾

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .start: return "句首"
            case .end: return "句尾"
            }
        }
    }

    /// 时间戳精度
    enum TimestampPrecision: String, CaseIterable, Identifiable, Codable, Sendable {
        case seconds      // 秒级 (00:01:23)
        case milliseconds // 毫秒级 (00:01:23.450)

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .seconds: return "秒级"
            case .milliseconds: return "毫秒级"
            }
        }
    }

    /// 聚合策略
    enum AggregationStrategy: String, CaseIterable, Identifiable, Codable, Sendable {
        case punctuation      // 按标点符号
        case pauseThreshold   // 按停顿时间

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .punctuation: return "按标点符号"
            case .pauseThreshold: return "按停顿时间"
            }
        }
    }

    /// 导出格式
    enum ExportFormat: String, CaseIterable, Identifiable, Codable, Sendable {
        case txt
        case srt
        case markdown

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .txt: return "纯文本 (TXT)"
            case .srt: return "字幕文件 (SRT)"
            case .markdown: return "Markdown"
            }
        }

        var fileExtension: String {
            switch self {
            case .txt: return "txt"
            case .srt: return "srt"
            case .markdown: return "md"
            }
        }
    }

    // MARK: - 初始化

    init() {
        // 从 UserDefaults 加载设置
        loadFromUserDefaults()
    }

    // MARK: - 持久化

    /// 保存设置到 UserDefaults
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(selectedModel, forKey: Keys.selectedModel)
        defaults.set(autoDownloadModels, forKey: Keys.autoDownloadModels)
        defaults.set(defaultLanguage.rawValue, forKey: Keys.defaultLanguage)
        defaults.set(enableLanguageDetection, forKey: Keys.enableLanguageDetection)
        defaults.set(includeTimestamp, forKey: Keys.includeTimestamp)
        defaults.set(timestampPosition.rawValue, forKey: Keys.timestampPosition)
        defaults.set(timestampPrecision.rawValue, forKey: Keys.timestampPrecision)
        defaults.set(aggregationStrategy.rawValue, forKey: Keys.aggregationStrategy)
        defaults.set(defaultExportFormat.rawValue, forKey: Keys.defaultExportFormat)
        defaults.set(enableChineseCorrection, forKey: Keys.enableChineseCorrection)
        defaults.set(enablePunctuationOptimization, forKey: Keys.enablePunctuationOptimization)
        defaults.set(enableNumberFormatting, forKey: Keys.enableNumberFormatting)
        defaults.set(enableLogging, forKey: Keys.enableLogging)
        defaults.set(maxConcurrentTasks, forKey: Keys.maxConcurrentTasks)

        if let path = lastExportPath {
            defaults.set(path, forKey: Keys.lastExportPath)
        }
    }

    /// 从 UserDefaults 加载设置
    private func loadFromUserDefaults() {
        let defaults = UserDefaults.standard

        if let model = defaults.string(forKey: Keys.selectedModel) {
            selectedModel = model
        }
        autoDownloadModels = defaults.bool(forKey: Keys.autoDownloadModels)
        if let lang = defaults.string(forKey: Keys.defaultLanguage),
           let language = Language(rawValue: lang) {
            defaultLanguage = language
        }
        enableLanguageDetection = defaults.bool(forKey: Keys.enableLanguageDetection)
        includeTimestamp = defaults.bool(forKey: Keys.includeTimestamp)
        if let pos = defaults.string(forKey: Keys.timestampPosition),
           let position = TimestampPosition(rawValue: pos) {
            timestampPosition = position
        }
        if let prec = defaults.string(forKey: Keys.timestampPrecision),
           let precision = TimestampPrecision(rawValue: prec) {
            timestampPrecision = precision
        }
        if let strat = defaults.string(forKey: Keys.aggregationStrategy),
           let strategy = AggregationStrategy(rawValue: strat) {
            aggregationStrategy = strategy
        }
        if let format = defaults.string(forKey: Keys.defaultExportFormat),
           let exportFormat = ExportFormat(rawValue: format) {
            defaultExportFormat = exportFormat
        }
        enableChineseCorrection = defaults.bool(forKey: Keys.enableChineseCorrection)
        enablePunctuationOptimization = defaults.bool(forKey: Keys.enablePunctuationOptimization)
        enableNumberFormatting = defaults.bool(forKey: Keys.enableNumberFormatting)
        enableLogging = defaults.bool(forKey: Keys.enableLogging)
        maxConcurrentTasks = defaults.integer(forKey: Keys.maxConcurrentTasks)
        if maxConcurrentTasks == 0 { maxConcurrentTasks = 1 }
        lastExportPath = defaults.url(forKey: Keys.lastExportPath)
    }

    /// 重置为默认设置
    func resetToDefaults() {
        selectedModel = "Qwen3-ASR-0.6B"
        autoDownloadModels = true
        defaultLanguage = .auto
        enableLanguageDetection = true
        includeTimestamp = true
        timestampPosition = .start
        timestampPrecision = .milliseconds
        aggregationStrategy = .punctuation
        defaultExportFormat = .txt
        enableChineseCorrection = true
        enablePunctuationOptimization = true
        enableNumberFormatting = true
        enableLogging = false
        maxConcurrentTasks = 1
        lastExportPath = nil
        saveToUserDefaults()
    }
}

// MARK: - Keys

private extension AppSettings {
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
