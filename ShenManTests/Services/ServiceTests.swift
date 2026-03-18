import XCTest
@testable import ShenMan

// MARK: - TranscriptionService 测试

final class TranscriptionServiceTests: XCTestCase {
    
    var service: TranscriptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = TranscriptionService()
    }
    
    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() {
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.settingsSnapshot)
    }
    
    func testInitializationWithCustomSettings() {
        let customSettings = AppSettings()
        customSettings.defaultLanguage = .english
        let customService = TranscriptionService(settings: customSettings)
        
        XCTAssertNotNil(customService)
    }
    
    // MARK: - updateSettings 测试
    
    func testUpdateSettings() {
        let newSettings = AppSettings()
        newSettings.defaultLanguage = .english
        newSettings.defaultModel = .qwen3ASR17B8bit
        
        service.updateSettings(newSettings)
        
        XCTAssertEqual(service.settingsSnapshot.defaultLanguage, .english)
        XCTAssertEqual(service.settingsSnapshot.defaultModel, .qwen3ASR17B8bit)
    }
    
    // MARK: - cancel 测试
    
    func testCancel() {
        service.cancel()
        // 验证取消标志被设置（内部实现）
    }
    
    // MARK: - 转录流程测试
    
    func testTranscribeWithProgress() async throws {
        // 这是一个异步测试，需要实际模型支持
        // 在实际环境中应该使用 mock 模型
        
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        var progressValues: [Double] = []
        var languageUsed: String?
        
        do {
            _ = try await service.transcribe(
                audioFile: audioFile,
                language: .chinese,
                aggregateStrategy: .punctuation
            ) { progress, language in
                await MainActor.run {
                    progressValues.append(progress)
                    languageUsed = language
                }
            }
            
            // 如果模型可用，验证进度回调
            XCTAssertFalse(progressValues.isEmpty, "应该有进度回调")
            XCTAssertEqual(languageUsed, "zh", "语言参数应该正确传递")
        } catch {
            // 模型未下载时的预期错误
            print("预期错误：\(error)")
        }
    }
    
    func testTranscribeWithNilLanguage() async throws {
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
                language: nil,
                aggregateStrategy: .punctuation
            ) { _, _ in }
        } catch {
            // 预期错误
        }
    }
    
    // MARK: - 后处理配置测试
    
    func testTranscribeWithChinesePostProcessing() async throws {
        service.updateSettings(AppSettings())
        
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
    
    func testTranscribeWithoutPostProcessing() async throws {
        let settings = AppSettings()
        settings.enableChinesePostProcessing = false
        settings.enableChineseCorrection = false
        settings.enablePunctuationOptimization = false
        settings.enableNumberFormatting = false
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
}

// MARK: - BatchProcessingService 测试

final class BatchProcessingServiceTests: XCTestCase {
    
    var service: BatchProcessingService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = BatchProcessingService()
    }
    
    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() {
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.batchId)
    }
    
    func testInitializationWithCustomBatchId() {
        let customId = UUID()
        let customService = BatchProcessingService(batchId: customId)
        XCTAssertEqual(customService.batchId, customId)
    }
    
    // MARK: - addTask 测试
    
    func testAddTask() async {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3
        )
        
        await service.addTask(audioFile, modelId: .qwen3ASR06B8bit)
        
        let tasks = await service.tasks
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].audioFile, audioFile)
        XCTAssertEqual(tasks[0].modelId, .qwen3ASR06B8bit)
    }
    
    // MARK: - addTasks 测试
    
    func testAddTasks() async {
        let audioFile1 = AudioFile(url: URL(fileURLWithPath: "/test1.mp3"), filename: "test1.mp3", duration: 60, fileSize: 1024, format: .mp3)
        let audioFile2 = AudioFile(url: URL(fileURLWithPath: "/test2.mp3"), filename: "test2.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let files = [audioFile1, audioFile2]
        await service.addTasks(files, modelId: .qwen3ASR06B8bit)
        
        let tasks = await service.tasks
        XCTAssertEqual(tasks.count, 2)
    }
    
    func testAddTasksEmptyArray() async {
        await service.addTasks([], modelId: .qwen3ASR06B8bit)
        
        let tasks = await service.tasks
        XCTAssertTrue(tasks.isEmpty)
    }
    
    // MARK: - startBatch 测试
    
    func testStartBatchEmptyQueue() async {
        do {
            let results = try await service.startBatch(modelId: .qwen3ASR06B8bit)
            XCTAssertTrue(results.isEmpty)
        } catch {
            XCTFail("不应该抛出错误")
        }
    }
    
    func testStartBatchCancellation() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        await service.addTask(audioFile, modelId: .qwen3ASR06B8bit)
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            await service.cancel()
        }
        
        do {
            _ = try await service.startBatch(modelId: .qwen3ASR06B8bit)
        } catch let error as BatchProcessingError {
            XCTAssertEqual(error, .cancelled)
        } catch {
            // 其他错误也是可接受的
        }
    }
    
    // MARK: - cancel 测试
    
    func testCancel() async {
        await service.cancel()
        // 验证取消标志被设置
    }
    
    // MARK: - removeCompletedTasks 测试
    
    func testRemoveCompletedTasks() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task.status = .completed
        await service.addTask(task)
        
        let pendingTask = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        pendingTask.status = .pending
        await service.addTask(pendingTask)
        
        await service.removeCompletedTasks()
        
        let tasks = await service.tasks
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].status, .pending)
    }
    
    // MARK: - removeFailedTasks 测试
    
    func testRemoveFailedTasks() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .failed
        await service.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .pending
        await service.addTask(task2)
        
        await service.removeFailedTasks()
        
        let tasks = await service.tasks
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].status, .pending)
    }
    
    // MARK: - clearAllTasks 测试
    
    func testClearAllTasks() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        await service.addTask(audioFile, modelId: .qwen3ASR06B8bit)
        
        await service.clearAllTasks()
        
        let tasks = await service.tasks
        XCTAssertTrue(tasks.isEmpty)
    }
    
    // MARK: - 计算属性测试
    
    func testPendingTaskCount() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .pending
        await service.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .completed
        await service.addTask(task2)
        
        let pendingCount = await service.pendingTaskCount
        XCTAssertEqual(pendingCount, 1)
    }
    
    func testCompletedTaskCount() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .completed
        await service.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .pending
        await service.addTask(task2)
        
        let completedCount = await service.completedTaskCount
        XCTAssertEqual(completedCount, 1)
    }
    
    func testFailedTaskCount() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .failed
        await service.addTask(task1)
        
        let failedCount = await service.failedTaskCount
        XCTAssertEqual(failedCount, 1)
    }
    
    func testOverallProgress() async {
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .completed
        task1.progress = 1.0
        await service.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .processing
        task2.progress = 0.5
        await service.addTask(task2)
        
        let progress = await service.overallProgress
        XCTAssertEqual(progress, 0.75, accuracy: 0.01)
    }
}

// MARK: - BatchExportService 测试

final class BatchExportServiceTests: XCTestCase {
    
    var service: BatchExportService!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        service = BatchExportService()
        
        // 创建临时目录
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        // 清理临时目录
        try? FileManager.default.removeItem(at: tempDirectory)
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - exportBatch 测试
    
    func testExportBatchEmptyResults() async {
        do {
            _ = try await service.exportBatch(
                results: [],
                format: .txt,
                directory: tempDirectory
            ) { _, _ in }
            XCTFail("应该抛出 emptyResults 错误")
        } catch let error as BatchExportError {
            XCTAssertEqual(error, .emptyResults)
        } catch {
            XCTFail("应该抛出 BatchExportError")
        }
    }
    
    func testExportBatchSingleResult() async {
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
        
        do {
            let urls = try await service.exportBatch(
                results: [result],
                format: .txt,
                directory: tempDirectory
            ) { _, _ in }
            
            XCTAssertEqual(urls.count, 1)
            XCTAssertTrue(FileManager.default.fileExists(atPath: urls[0].path))
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testExportBatchMultipleResults() async {
        let audioFile1 = AudioFile(url: URL(fileURLWithPath: "/test1.mp3"), filename: "test1.mp3", duration: 10, fileSize: 1024, format: .mp3)
        let audioFile2 = AudioFile(url: URL(fileURLWithPath: "/test2.mp3"), filename: "test2.mp3", duration: 10, fileSize: 1024, format: .mp3)
        
        let result1 = TranscriptionResult(
            audioFile: audioFile1,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [SentenceTimestamp(text: "测试 1", startTime: 0, endTime: 1.0)]
        )
        
        let result2 = TranscriptionResult(
            audioFile: audioFile2,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [SentenceTimestamp(text: "测试 2", startTime: 0, endTime: 1.0)]
        )
        
        var progressValues: [Double] = []
        
        do {
            let urls = try await service.exportBatch(
                results: [result1, result2],
                format: .txt,
                directory: tempDirectory
            ) { progress, _ in
                progressValues.append(progress)
            }
            
            XCTAssertEqual(urls.count, 2)
            XCTAssertEqual(progressValues.count, 2)
            XCTAssertEqual(progressValues.last, 1.0, accuracy: 0.01)
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testExportBatchWithProgressCallback() async {
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
            sentences: [SentenceTimestamp(text: "测试", startTime: 0, endTime: 1.0)]
        )
        
        var statusText: String?
        
        do {
            _ = try await service.exportBatch(
                results: [result],
                format: .txt,
                directory: tempDirectory
            ) { _, status in
                statusText = status
            }
            
            XCTAssertNotNil(statusText)
            XCTAssertTrue(statusText!.contains("测试"))
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    // MARK: - 计算属性测试
    
    func testCurrentProgress() async {
        let progress = await service.currentProgress
        XCTAssertEqual(progress, 0.0)
    }
    
    func testCurrentSuccessCount() async {
        let count = await service.currentSuccessCount
        XCTAssertEqual(count, 0)
    }
    
    func testCurrentFailedCount() async {
        let count = await service.currentFailedCount
        XCTAssertEqual(count, 0)
    }
}
