import Foundation

/// Markdown 导出器
/// 导出 Markdown 格式
struct MarkdownExporter: Exporter {
    // MARK: - 属性

    let formatName = "Markdown"
    let fileExtension = "md"
    let mimeType = "text/markdown"

    // MARK: - 导出方法

    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""

        // 标题
        let filename = result.audioFile.filename
            .replacingOccurrences(of: "\\.[^.]+$", with: "", options: .regularExpression)
        content += "# \(filename)\n\n"

        // 元数据
        content += "## 元数据\n\n"
        content += "| 属性 | 值 |\n"
        content += "| --- | --- |\n"
        content += "| 文件 | \(result.audioFile.filename) |\n"
        content += "| 模型 | \(result.modelName) |\n"
        content += "| 语言 | \(result.language) |\n"
        content += "| 时长 | \(TimeFormatter.formatTime(result.audioFile.duration)) |\n"
        content += "| 处理时间 | \(String(format: "%.1f", result.processingTime)) 秒 |\n"
        content += "| 实时因子 | \(String(format: "%.2f", result.metadata.realTimeFactor))x |\n"
        content += "\n"

        // 转录内容
        content += "## 转录内容\n\n"

        for sentence in result.sentences {
            if options.includeTimestamp {
                let timestamp = formatTimestamp(
                    startTime: sentence.startTime,
                    precision: options.timestampPrecision
                )
                content += "- **\(timestamp)** \(sentence.text)\n"
            } else {
                content += "- \(sentence.text)\n"
            }
        }

        // 页脚
        content += "\n---\n\n"
        content += "*由 \(Constants.appName) 生成*\n"

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    // MARK: - 私有方法

    private func formatTimestamp(
        startTime: TimeInterval,
        precision: AppSettings.TimestampPrecision
    ) -> String {
        return precision == .milliseconds
            ? TimeFormatter.formatTimeWithMilliseconds(startTime)
            : TimeFormatter.formatTime(startTime)
    }
}