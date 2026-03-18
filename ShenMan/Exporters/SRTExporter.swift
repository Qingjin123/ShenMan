import Foundation

/// SRT 导出器
/// 导出字幕格式
struct SRTExporter: Exporter {
    // MARK: - 属性

    let formatName = "字幕文件"
    let fileExtension = "srt"
    let mimeType = "application/x-subrip"

    // MARK: - 导出方法

    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""

        for (index, sentence) in result.sentences.enumerated() {
            // 序号
            content += "\(index + 1)\n"

            // 时间轴（SRT 格式：HH:MM:SS,mmm --> HH:MM:SS,mmm）
            content += "\(formatSRTTime(sentence.startTime)) --> \(formatSRTTime(sentence.endTime))\n"

            // 字幕文本
            content += "\(sentence.text)\n\n"
        }

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    // MARK: - 私有方法

    /// 格式化 SRT 时间格式
    /// - Parameter time: 时间间隔（秒）
    /// - Returns: SRT 格式时间字符串（HH:MM:SS,mmm）
    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}