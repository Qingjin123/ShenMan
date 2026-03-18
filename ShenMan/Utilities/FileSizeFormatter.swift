import Foundation

/// 文件大小格式化工具
struct FileSizeFormatter {
    
    /// 格式化文件大小
    /// - Parameter bytes: 字节数
    /// - Returns: 格式化的文件大小字符串
    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 格式化文件大小（带单位）
    /// - Parameter bytes: 字节数
    /// - Returns: 格式化的文件大小字符串
    static func formatWithUnit(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}