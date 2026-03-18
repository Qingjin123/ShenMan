import Foundation

/// TXT 导出器
/// 导出纯文本格式
struct TXTExporter: Exporter {
    // MARK: - 属性

    let formatName = "纯文本"
    let fileExtension = "txt"
    let mimeType = "text/plain"

    // MARK: - 导出方法

    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""

        // 添加元数据（可选）
        if options.includeMetadata {
            content += "文件：\(result.audioFile.filename)\n"
            content += "模型：\(result.modelName)\n"
            content += "语言：\(result.language)\n"
            content += "时长：\(TimeFormatter.formatTime(result.audioFile.duration))\n"
            content += "处理时间：\(String(format: "%.1f", result.processingTime)) 秒\n"
            content += "实时因子：\(String(format: "%.2f", result.metadata.realTimeFactor))x\n"
            content += "\n---\n\n"
        }

        // 添加转录内容
        for sentence in result.sentences {
            if options.includeTimestamp {
                let timestamp = formatTimestamp(
                    startTime: sentence.startTime,
                    endTime: sentence.endTime,
                    precision: options.timestampPrecision
                )

                switch options.timestampPosition {
                case .start:
                    content += "\(timestamp) \(sentence.text)\n"
                case .end:
                    content += "\(sentence.text) \(timestamp)\n"
                }
            } else {
                content += "\(sentence.text)\n"
            }
        }

        guard let data = content.data(using: options.encoding) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    // MARK: - 私有方法

    private func formatTimestamp(
        startTime: TimeInterval,
        endTime: TimeInterval,
        precision: AppSettings.TimestampPrecision
    ) -> String {
        let start = precision == .milliseconds
            ? TimeFormatter.formatTimeWithMilliseconds(startTime)
            : TimeFormatter.formatTime(startTime)
        let end = precision == .milliseconds
            ? TimeFormatter.formatTimeWithMilliseconds(endTime)
            : TimeFormatter.formatTime(endTime)
        return "[\(start) → \(end)]"
    }
}

// MARK: - 导出错误

enum ExportError: LocalizedError {
    case encodingFailed
    case fileWriteFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "文本编码失败"
        case .fileWriteFailed:
            return "文件写入失败"
        }
    }
}