import Foundation

/// 导出选项
/// 配置导出格式的详细选项
struct ExportOptions: Sendable {
    // MARK: - 属性

    /// 是否包含时间戳
    var includeTimestamp: Bool = true

    /// 时间戳位置
    var timestampPosition: AppSettings.TimestampPosition = .start

    /// 时间戳精度
    var timestampPrecision: AppSettings.TimestampPrecision = .milliseconds

    /// 文件编码
    var encoding: String.Encoding = .utf8

    /// 是否包含元数据
    var includeMetadata: Bool = false

    // MARK: - 初始化

    init(
        includeTimestamp: Bool = true,
        timestampPosition: AppSettings.TimestampPosition = .start,
        timestampPrecision: AppSettings.TimestampPrecision = .milliseconds,
        encoding: String.Encoding = .utf8,
        includeMetadata: Bool = false
    ) {
        self.includeTimestamp = includeTimestamp
        self.timestampPosition = timestampPosition
        self.timestampPrecision = timestampPrecision
        self.encoding = encoding
        self.includeMetadata = includeMetadata
    }

    /// 从 AppSettings 创建导出选项
    @MainActor
    static func from(_ settings: AppSettings) -> ExportOptions {
        ExportOptions(
            includeTimestamp: settings.includeTimestamp,
            timestampPosition: settings.timestampPosition,
            timestampPrecision: settings.timestampPrecision,
            includeMetadata: false
        )
    }
}