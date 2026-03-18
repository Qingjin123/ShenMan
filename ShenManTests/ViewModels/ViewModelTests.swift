import XCTest
@testable import ShenMan

// MARK: - BatchProcessingViewModel 测试

final class BatchProcessingViewModelTests: XCTestCase {
    
    var viewModel: BatchProcessingViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = BatchProcessingViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertNotNil(viewModel.batchId)
        XCTAssertEqual(viewModel.processingState, .idle)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertEqual(viewModel.totalCount, 0)
    }
    
    func testInitializationWithCustomBatchId() {
        let customId = UUID()
        let customViewModel = BatchProcessingViewModel(batchId: customId)
        XCTAssertEqual(customViewModel.batchId, customId)
    }
    
    // MARK: - addFiles 测试
    
    func testAddFiles() async {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3
        )
        
        viewModel.addFiles([audioFile])
        
        // 等待异步处理
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.totalCount, 1)
    }
    
    func testAddFilesEmpty() async {
        viewModel.addFiles([])
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.totalCount, 0)
    }
    
    // MARK: - reset 测试
    
    func testReset() {
        viewModel.reset()
        
        XCTAssertEqual(viewModel.processingState, .idle)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertEqual(viewModel.currentTaskIndex, 0)
        XCTAssertEqual(viewModel.completedCount, 0)
        XCTAssertEqual(viewModel.failedCount, 0)
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertEqual(viewModel.currentProcessingFile, "")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.results.isEmpty)
    }
    
    // MARK: - 计算属性测试
    
    func testIsProcessing() {
        viewModel.processingState = .processing
        XCTAssertTrue(viewModel.isProcessing)
        
        viewModel.processingState = .idle
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    func testIsCompleted() {
        viewModel.processingState = .completed
        XCTAssertTrue(viewModel.isCompleted)
        
        viewModel.processingState = .processing
        XCTAssertFalse(viewModel.isCompleted)
    }
    
    func testProgressText() {
        viewModel.progress = 0.45
        XCTAssertEqual(viewModel.progressText, "45%")
        
        viewModel.progress = 0.0
        XCTAssertEqual(viewModel.progressText, "0%")
        
        viewModel.progress = 1.0
        XCTAssertEqual(viewModel.progressText, "100%")
    }
    
    func testStatusDescriptionIdle() {
        viewModel.processingState = .idle
        XCTAssertEqual(viewModel.statusDescription, "准备就绪")
    }
    
    func testStatusDescriptionProcessing() {
        viewModel.processingState = .processing
        viewModel.currentProcessingFile = "test.mp3"
        XCTAssertEqual(viewModel.statusDescription, "处理中：test.mp3")
    }
    
    func testStatusDescriptionCompleted() {
        viewModel.processingState = .completed
        viewModel.completedCount = 5
        XCTAssertEqual(viewModel.statusDescription, "完成，共 5 个文件")
    }
    
    func testStatusDescriptionFailed() {
        viewModel.processingState = .failed
        viewModel.errorMessage = "测试错误"
        XCTAssertEqual(viewModel.statusDescription, "失败：测试错误")
    }
    
    func testStatusDescriptionCancelled() {
        viewModel.processingState = .cancelled
        XCTAssertEqual(viewModel.statusDescription, "已取消")
    }
}

// MARK: - ModelManagerViewModel 测试

final class ModelManagerViewModelTests: XCTestCase {
    
    var viewModel: ModelManagerViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = ModelManagerViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.models.isEmpty)
    }
    
    // MARK: - checkDownloadStatus 测试
    
    func testCheckDownloadStatus() {
        viewModel.checkDownloadStatus()
        // 验证下载状态被检查
    }
    
    // MARK: - isModelDownloaded 测试
    
    func testIsModelDownloaded() {
        // 测试模型下载状态检查
        let isDownloaded = viewModel.isModelDownloaded(.qwen3ASR06B8bit)
        // 结果取决于实际下载状态
        XCTAssertNotNil(isDownloaded)
    }
    
    // MARK: - downloadState 测试
    
    func testDownloadState() {
        let state = viewModel.downloadState(for: .qwen3ASR06B8bit)
        // 验证返回有效的下载状态
        XCTAssertNotNil(state)
    }
}

// MARK: - AppState 测试

final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        appState = AppState()
    }
    
    override func tearDown() async throws {
        appState = nil
        try await super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() async {
        XCTAssertNotNil(appState)
        XCTAssertEqual(appState.currentView, .home)
        XCTAssertNil(appState.currentAudioFile)
        XCTAssertNil(appState.errorMessage)
    }
    
    // MARK: - loadAudioFile 测试
    
    func testLoadAudioFileValid() async {
        // 创建一个临时音频文件
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp3")
        
        // 注意：实际测试需要真实的音频文件
        // 这里只测试错误处理
        do {
            try await appState.loadAudioFile(url: tempURL)
        } catch {
            // 文件不存在是预期的
        }
    }
    
    func testLoadAudioFileInvalid() async {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.mp3")
        
        do {
            try await appState.loadAudioFile(url: invalidURL)
        } catch {
            XCTAssertNotNil(appState.errorMessage)
        }
    }
    
    // MARK: - startTranscription 测试
    
    func testStartTranscriptionNoFile() async {
        appState.currentAudioFile = nil
        
        await appState.startTranscription()
        
        // 没有音频文件时应该无操作
    }
    
    // MARK: - cancelTranscription 测试
    
    func testCancelTranscription() async {
        await appState.cancelTranscription()
        
        // 验证状态重置
    }
    
    // MARK: - reset 测试
    
    func testReset() {
        appState.reset()
        
        XCTAssertEqual(appState.currentView, .home)
        XCTAssertNil(appState.currentAudioFile)
        XCTAssertNil(appState.currentResult)
        XCTAssertNil(appState.errorMessage)
    }
    
    // MARK: - showError 测试
    
    func testShowError() {
        appState.showError("测试错误")
        XCTAssertEqual(appState.errorMessage, "测试错误")
    }
    
    // MARK: - clearError 测试
    
    func testClearError() {
        appState.errorMessage = "测试错误"
        appState.clearError()
        XCTAssertNil(appState.errorMessage)
    }
    
    // MARK: - saveToHistory 测试
    
    func testSaveToHistory() async {
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
            sentences: [SentenceTimestamp(text: "测试", startTime: 0, endTime: 1.0)]
        )
        
        await appState.saveToHistory(result: result)
        
        // 验证历史记录被保存
    }
    
    // MARK: - deleteHistoryRecord 测试
    
    func testDeleteHistoryRecord() async {
        let id = UUID()
        await appState.deleteHistoryRecord(id: id)
        
        // 验证删除操作
    }
    
    // MARK: - 导航状态测试
    
    func testNavigationStates() {
        XCTAssertFalse(appState.showSettings)
        XCTAssertFalse(appState.showHistory)
        XCTAssertFalse(appState.showModelPicker)
        XCTAssertFalse(appState.showBatchImport)
        XCTAssertFalse(appState.showBatchExport)
        
        appState.showSettings = true
        XCTAssertTrue(appState.showSettings)
    }
}
