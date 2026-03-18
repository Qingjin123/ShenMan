import Foundation

/// 批量导出服务
/// 负责将多个转录结果导出为文件
actor BatchExportService {
    
    // MARK: - 属性
    
    /// 文件仓库
    private let fileRepository = FileRepository()
    
    /// 导出进度
    private var progress: Double = 0.0
    
    /// 当前导出的文件索引
    private var currentIndex: Int = 0
    
    /// 总文件数量
    private var totalCount: Int = 0
    
    /// 成功的数量
    private var successCount: Int = 0
    
    /// 失败的数量
    private var failedCount: Int = 0
    
    // MARK: - 公开方法
    
    /// 批量导出转录结果
    /// - Parameters:
    ///   - results: 转录结果列表
    ///   - format: 导出格式
    ///   - directory: 导出目录
    ///   - progressHandler: 进度回调
    /// - Returns: 导出的文件 URL 列表
    func exportBatch(
        results: [TranscriptionResult],
        format: AppSettings.ExportFormat,
        directory: URL,
        progressHandler: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> [URL] {
        guard !results.isEmpty else {
            throw BatchExportError.emptyResults
        }
        
        totalCount = results.count
        currentIndex = 0
        successCount = 0
        failedCount = 0
        progress = 0.0
        
        var exportedURLs: [URL] = []
        
        // 创建导出目录
        try fileRepository.createDirectoryIfNeeded(at: directory)
        
        for (index, result) in results.enumerated() {
            currentIndex = index
            
            do {
                // 生成文件名
                let filename = generateFilename(for: result, format: format)
                let fileURL = directory.appendingPathComponent(filename)
                
                // 导出文件
                try await exportResult(result, to: fileURL, format: format)
                
                exportedURLs.append(fileURL)
                successCount += 1
                
            } catch {
                failedCount += 1
                print("导出失败：\(result.audioFile.filename) - \(error)")
            }
            
            // 更新进度
            progress = Double(index + 1) / Double(totalCount)
            let currentProgress = progress
            let currentFilename = result.audioFile.filename
            await MainActor.run {
                progressHandler?(currentProgress, "正在导出：\(currentFilename)")
            }
        }
        
        await MainActor.run {
            progressHandler?(1.0, "导出完成")
        }
        
        return exportedURLs
    }
    
    /// 导出单个转录结果
    private func exportResult(
        _ result: TranscriptionResult,
        to url: URL,
        format: AppSettings.ExportFormat
    ) async throws {
        let exporter: Exporter
        
        switch format {
        case .txt:
            exporter = TXTExporter()
        case .srt:
            exporter = SRTExporter()
        case .markdown:
            exporter = MarkdownExporter()
        }
        
        let exportOptions = ExportOptions(
            includeTimestamp: true,
            timestampPosition: .start,
            timestampPrecision: .milliseconds
        )
        
        let data = try exporter.export(result: result, options: exportOptions)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
    
    /// 生成文件名
    private func generateFilename(
        for result: TranscriptionResult,
        format: AppSettings.ExportFormat
    ) -> String {
        let baseName = result.audioFile.filename
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        let timestamp = Date().formatted(
            .dateTime.year().month().day().hour().minute()
        )
        
        return "\(baseName)_\(timestamp).\(format.fileExtension)"
    }
    
    // MARK: - 计算属性
    
    /// 当前进度
    var currentProgress: Double {
        progress
    }
    
    /// 成功数量
    var currentSuccessCount: Int {
        successCount
    }
    
    /// 失败数量
    var currentFailedCount: Int {
        failedCount
    }
}

// MARK: - 批量导出错误

enum BatchExportError: LocalizedError {
    case emptyResults
    case exportFailed(String)
    case directoryCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyResults:
            return "没有可导出的结果"
        case .exportFailed(let reason):
            return "导出失败：\(reason)"
        case .directoryCreationFailed:
            return "无法创建导出目录"
        }
    }
}

// MARK: - FileRepository 扩展

extension FileRepository {
    func createDirectoryIfNeeded(at url: URL) throws {
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                throw FileError.fileIsDirectory
            }
        } else {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }
}
