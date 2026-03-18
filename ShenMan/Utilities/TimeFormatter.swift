import Foundation

/// 时间格式化工具
/// 用于格式化时间戳显示
struct TimeFormatter {
    
    // MARK: - 格式化方法
    
    /// 格式化时间间隔为 HH:MM:SS 或 MM:SS 格式
    /// - Parameter time: 时间间隔（秒）
    /// - Returns: 格式化的时间字符串
    static func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 格式化时间间隔为毫秒级精度
    /// - Parameter time: 时间间隔（秒）
    /// - Returns: 格式化的时间字符串（HH:MM:SS.mmm）
    static func formatTimeWithMilliseconds(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
        }
    }
    
    /// 格式化 SRT 时间格式
    /// - Parameter time: 时间间隔（秒）
    /// - Returns: SRT 格式时间字符串（HH:MM:SS,mmm）
    static func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
    
    /// 格式化时间戳显示
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    ///   - precision: 时间精度
    /// - Returns: 格式化的时间戳字符串
    static func formatTimestamp(
        startTime: TimeInterval,
        endTime: TimeInterval,
        precision: AppSettings.TimestampPrecision = .milliseconds
    ) -> String {
        let start = precision == .milliseconds
            ? formatTimeWithMilliseconds(startTime)
            : formatTime(startTime)
        let end = precision == .milliseconds
            ? formatTimeWithMilliseconds(endTime)
            : formatTime(endTime)
        return "[\(start) → \(end)]"
    }
    
    /// 格式化剩余时间
    /// - Parameter time: 时间间隔（秒）
    /// - Returns: 格式化的剩余时间字符串
    static func formatRemainingTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.0f 秒", time)
        } else if time < 3600 {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d 分 %d 秒", minutes, seconds)
        } else {
            let hours = Int(time) / 3600
            let minutes = (Int(time) % 3600) / 60
            return String(format: "%d 小时 %d 分", hours, minutes)
        }
    }
}