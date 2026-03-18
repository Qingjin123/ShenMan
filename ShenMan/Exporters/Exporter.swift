import Foundation

/// 导出器协议
/// 所有导出器必须实现此协议
protocol Exporter: Sendable {
    /// 格式名称
    var formatName: String { get }

    /// 文件扩展名
    var fileExtension: String { get }

    /// MIME 类型
    var mimeType: String { get }

    /// 导出转录结果
    /// - Parameters:
    ///   - result: 转录结果
    ///   - options: 导出选项
    /// - Returns: 导出的数据
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data
}