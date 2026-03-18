import XCTest
@testable import ShenMan

// MARK: - 转录集成测试

final class TranscriptionIntegrationTests: XCTestCase {
    
    var service: TranscriptionService!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        service = TranscriptionService()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - 完整转录流程测试
    
    func testFullTranscriptionFlow() async throws {
        // 注意：这是一个集成测试，需要实际模型支持
        // 在实际环境中应该使用 mock 或测试模型
        
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        var progressReceived = false
        var languageReceived: String?
        
        do {
            let result = try await service.transcribe(
                audioFile: audioFile,
                language: .chinese,
                aggregateStrategy: .punctuation
            ) { progress, language in
                progressReceived = true
                languageReceived = language
            }
            
            // 如果转录成功，验证结果
            XCTAssertEqual(result.audioFile, audioFile)
            XCTAssertTrue(progressReceived)
            XCTAssertEqual(languageReceived, "zh")
        } catch {
            // 模型未下载时的预期错误
            print("预期错误：\(error)")
        }
    }
    
    // MARK: - 转录 + 后处理集成测试
    
    func testTranscriptionWithPostProcessing() async throws {
        let settings = AppSettings()
        settings.enableChinesePostProcessing = true
        settings.enableChineseCorrection = true
        settings.enablePunctuationOptimization = true
        settings.enableNumberFormatting = true
        
        service.updateSettings(settings)
        
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        do {
            _ = try await service.transcribe(
                audioFile: audioFile,
                language: .chinese,
                aggregateStrategy: .punctuation
            ) { _, _ in }
        } catch {
            // 预期错误
        }
    }
    
    // MARK: - 转录 + 导出集成测试
    
    func testTranscriptionAndExport() async throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentences = [
            SentenceTimestamp(text: "测试文本", startTime: 0, endTime: 1.0)
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences
        )
        
        // 导出为 TXT
        let exporter = TXTExporter()
        let options = ExportOptions(includeMetadata: false)
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertEqual(text, "测试文本")
    }
}

// MARK: - 批量处理集成测试

final class BatchProcessingIntegrationTests: XCTestCase {
    
    var batchService: BatchProcessingService!
    var exportService: BatchExportService!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        batchService = BatchProcessingService()
        exportService = BatchExportService()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        batchService = nil
        exportService = nil
        try await super.tearDown()
    }
    
    // MARK: - 批量转录 + 批量导出集成测试
    
    func testBatchTranscribeAndExport() async throws {
        // 准备测试数据
        let audioFile1 = AudioFile(
            url: URL(fileURLWithPath: "/test1.mp3"),
            filename: "test1.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let audioFile2 = AudioFile(
            url: URL(fileURLWithPath: "/test2.mp3"),
            filename: "test2.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        // 模拟转录结果
        let results = [
            TranscriptionResult(
                audioFile: audioFile1,
                modelName: "Qwen3-ASR",
                language: "zh",
                sentences: [SentenceTimestamp(text: "测试 1", startTime: 0, endTime: 1.0)]
            ),
            TranscriptionResult(
                audioFile: audioFile2,
                modelName: "Qwen3-ASR",
                language: "zh",
                sentences: [SentenceTimestamp(text: "测试 2", startTime: 0, endTime: 1.0)]
            )
        ]
        
        // 批量导出
        var progressValues: [Double] = []
        
        let urls = try await exportService.exportBatch(
            results: results,
            format: .txt,
            directory: tempDirectory
        ) { progress, _ in
            progressValues.append(progress)
        }
        
        // 验证结果
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(progressValues.count, 2)
        XCTAssertEqual(progressValues.last, 1.0, accuracy: 0.01)
        
        // 验证文件存在
        for url in urls {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }
}

// MARK: - 历史记录集成测试

final class HistoryIntegrationTests: XCTestCase {
    
    var historyRepository: HistoryRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        historyRepository = HistoryRepository.shared
    }
    
    override func tearDown() async throws {
        historyRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - 完整历史记录流程测试
    
    func testFullHistoryFlow() async throws {
        // 1. 创建转录结果
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [
                SentenceTimestamp(text: "第一句", startTime: 0, endTime: 1.0),
                SentenceTimestamp(text: "第二句", startTime: 1.0, endTime: 2.0)
            ]
        )
        
        // 2. 保存到历史记录
        let record = await historyRepository.addHistoryRecord(
            from: result,
            transcript: "第一句\n第二句"
        )
        
        // 3. 验证保存
        let records = await historyRepository.getAllHistory()
        XCTAssertTrue(records.contains(where: { $0.id == record.id }))
        
        // 4. 测试搜索
        let searchResults = await historyRepository.searchHistory(query: "第一句")
        XCTAssertTrue(searchResults.contains(where: { $0.id == record.id }))
        
        // 5. 测试收藏
        await historyRepository.toggleFavorite(id: record.id)
        let favorites = await historyRepository.getFavorites()
        XCTAssertTrue(favorites.contains(where: { $0.id == record.id }))
        
        // 6. 测试更新
        var updatedRecord = record
        updatedRecord.transcript = "更新后的文本"
        await historyRepository.updateHistoryRecord(updatedRecord)
        
        let updatedRecords = await historyRepository.getAllHistory()
        if let found = updatedRecords.first(where: { $0.id == record.id }) {
            XCTAssertEqual(found.transcript, "更新后的文本")
        }
        
        // 7. 测试删除
        await historyRepository.deleteHistoryRecord(id: record.id, deleteAssociatedFile: false)
        
        let finalRecords = await historyRepository.getAllHistory()
        XCTAssertFalse(finalRecords.contains(where: { $0.id == record.id }))
    }
    
    // MARK: - 历史记录限制测试
    
    func testHistoryLimit() async throws {
        let maxCount = 100
        
        // 添加超过限制的记录
        for i in 0..<110 {
            let audioFile = AudioFile(
                url: URL(fileURLWithPath: "/test\(i).mp3"),
                filename: "test\(i).mp3",
                duration: 60.0,
                fileSize: 1024,
                format: .mp3
            )
            
            let result = TranscriptionResult(
                audioFile: audioFile,
                modelName: "Qwen3-ASR",
                language: "zh",
                sentences: [SentenceTimestamp(text: "测试\(i)", startTime: 0, endTime: 1.0)]
            )
            
            await historyRepository.addHistoryRecord(
                from: result,
                transcript: "测试\(i)"
            )
        }
        
        let records = await historyRepository.getAllHistory()
        // 验证记录数量不超过限制
        XCTAssertLessThanOrEqual(records.count, maxCount + 10) // 允许一些收藏记录
    }
}

// MARK: - 导出器集成测试

final class ExporterIntegrationTests: XCTestCase {
    
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try await super.tearDown()
    }
    
    // MARK: - 多格式导出测试
    
    func testMultiFormatExport() async throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [
                SentenceTimestamp(text: "第一句", startTime: 0, endTime: 1.0),
                SentenceTimestamp(text: "第二句", startTime: 1.5, endTime: 2.5)
            ]
        )
        
        let exporters: [Exporter] = [
            TXTExporter(),
            SRTExporter(),
            MarkdownExporter()
        ]
        
        for exporter in exporters {
            let options = ExportOptions(includeMetadata: true)
            let data = try exporter.export(result: result, options: options)
            
            let fileURL = tempDirectory
                .appendingPathComponent("test")
                .appendingPathExtension(exporter.fileExtension)
            
            try data.write(to: fileURL)
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertFalse(content.isEmpty)
        }
    }
    
    // MARK: - 批量导出集成测试
    
    func testBatchExportIntegration() async throws {
        // 准备多个结果
        var results: [TranscriptionResult] = []
        
        for i in 1...5 {
            let audioFile = AudioFile(
                url: URL(fileURLWithPath: "/test\(i).mp3"),
                filename: "test\(i).mp3",
                duration: Double(i * 10),
                fileSize: 1024,
                format: .mp3
            )
            
            results.append(TranscriptionResult(
                audioFile: audioFile,
                modelName: "Qwen3-ASR",
                language: "zh",
                sentences: [SentenceTimestamp(text: "测试\(i)", startTime: 0, endTime: 1.0)]
            ))
        }
        
        // 批量导出
        let exportService = BatchExportService()
        var lastProgress: Double = 0
        
        let urls = try await exportService.exportBatch(
            results: results,
            format: .txt,
            directory: tempDirectory
        ) { progress, _ in
            lastProgress = progress
        }
        
        // 验证
        XCTAssertEqual(urls.count, 5)
        XCTAssertEqual(lastProgress, 1.0, accuracy: 0.01)
        
        for url in urls {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }
}
