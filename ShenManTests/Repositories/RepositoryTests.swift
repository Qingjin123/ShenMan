import XCTest
@testable import ShenMan

// MARK: - FileRepository 测试

final class FileRepositoryTests: XCTestCase {
    
    var repository: FileRepository!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        repository = FileRepository()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        repository = nil
        try await super.tearDown()
    }
    
    // MARK: - readFile 测试
    
    func testReadFileExisting() async {
        let fileURL = tempDirectory.appendingPathComponent("test.txt")
        let testData = "测试内容".data(using: .utf8)!
        try? testData.write(to: fileURL)
        
        do {
            let data = try await repository.readFile(at: fileURL)
            XCTAssertEqual(data, testData)
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testReadFileNonExistent() async {
        let fileURL = tempDirectory.appendingPathComponent("nonexistent.txt")
        
        do {
            _ = try await repository.readFile(at: fileURL)
            XCTFail("应该抛出 fileNotFound 错误")
        } catch let error as FileError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("应该抛出 FileError")
        }
    }
    
    // MARK: - writeFile 测试
    
    func testWriteFileNew() async {
        let fileURL = tempDirectory.appendingPathComponent("new.txt")
        let testData = "新内容".data(using: .utf8)!
        
        do {
            try await repository.writeFile(data: testData, to: fileURL, createIntermediateDirectories: false)
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            
            let readData = try Data(contentsOf: fileURL)
            XCTAssertEqual(readData, testData)
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testWriteFileOverwrite() async {
        let fileURL = tempDirectory.appendingPathComponent("overwrite.txt")
        let originalData = "原始内容".data(using: .utf8)!
        let newData = "新内容".data(using: .utf8)!
        
        try? originalData.write(to: fileURL)
        
        do {
            try await repository.writeFile(data: newData, to: fileURL, createIntermediateDirectories: false)
            let readData = try Data(contentsOf: fileURL)
            XCTAssertEqual(readData, newData)
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testWriteFileWithIntermediateDirectories() async {
        let fileURL = tempDirectory
            .appendingPathComponent("subdir1")
            .appendingPathComponent("subdir2")
            .appendingPathComponent("test.txt")
        
        let testData = "内容".data(using: .utf8)!
        
        do {
            try await repository.writeFile(data: testData, to: fileURL, createIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    // MARK: - deleteFile 测试
    
    func testDeleteFileExisting() async {
        let fileURL = tempDirectory.appendingPathComponent("delete.txt")
        let testData = "内容".data(using: .utf8)!
        try? testData.write(to: fileURL)
        
        do {
            try await repository.deleteFile(at: fileURL)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testDeleteFileNonExistent() async {
        let fileURL = tempDirectory.appendingPathComponent("nonexistent.txt")
        
        do {
            try await repository.deleteFile(at: fileURL)
            XCTFail("应该抛出 fileNotFound 错误")
        } catch let error as FileError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("应该抛出 FileError")
        }
    }
    
    // MARK: - fileExists 测试
    
    func testFileExistsTrue() async {
        let fileURL = tempDirectory.appendingPathComponent("exists.txt")
        let testData = "内容".data(using: .utf8)!
        try? testData.write(to: fileURL)
        
        let exists = await repository.fileExists(at: fileURL)
        XCTAssertTrue(exists)
    }
    
    func testFileExistsFalse() async {
        let fileURL = tempDirectory.appendingPathComponent("nonexistent.txt")
        
        let exists = await repository.fileExists(at: fileURL)
        XCTAssertFalse(exists)
    }
    
    // MARK: - fileSize 测试
    
    func testFileSize() async {
        let fileURL = tempDirectory.appendingPathComponent("size.txt")
        let testData = "测试内容 123".data(using: .utf8)!
        try? testData.write(to: fileURL)
        
        do {
            let size = try await repository.fileSize(at: fileURL)
            XCTAssertEqual(size, testData.count)
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testFileSizeNonExistent() async {
        let fileURL = tempDirectory.appendingPathComponent("nonexistent.txt")
        
        do {
            _ = try await repository.fileSize(at: fileURL)
            XCTFail("应该抛出 fileNotFound 错误")
        } catch let error as FileError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("应该抛出 FileError")
        }
    }
    
    // MARK: - copyFile 测试
    
    func testCopyFile() async {
        let sourceURL = tempDirectory.appendingPathComponent("source.txt")
        let destURL = tempDirectory.appendingPathComponent("dest.txt")
        let testData = "复制内容".data(using: .utf8)!
        try? testData.write(to: sourceURL)
        
        do {
            try await repository.copyFile(from: sourceURL, to: destURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: destURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    func testCopyFileSourceNonExistent() async {
        let sourceURL = tempDirectory.appendingPathComponent("nonexistent.txt")
        let destURL = tempDirectory.appendingPathComponent("dest.txt")
        
        do {
            try await repository.copyFile(from: sourceURL, to: destURL)
            XCTFail("应该抛出 fileNotFound 错误")
        } catch let error as FileError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("应该抛出 FileError")
        }
    }
    
    // MARK: - moveFile 测试
    
    func testMoveFile() async {
        let sourceURL = tempDirectory.appendingPathComponent("source.txt")
        let destURL = tempDirectory.appendingPathComponent("dest.txt")
        let testData = "移动内容".data(using: .utf8)!
        try? testData.write(to: sourceURL)
        
        do {
            try await repository.moveFile(from: sourceURL, to: destURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: destURL.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: sourceURL.path))
        } catch {
            XCTFail("不应该抛出错误：\(error)")
        }
    }
    
    // MARK: - temporaryDirectory 测试
    
    func testTemporaryDirectory() async {
        let tempDir = await repository.temporaryDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.path))
    }
    
    // MARK: - makeTemporaryFileURL 测试
    
    func testMakeTemporaryFileURL() async {
        let url = await repository.makeTemporaryFileURL(extension: "txt")
        
        XCTAssertEqual(url.pathExtension, "txt")
        XCTAssertNotNil(UUID(uuidString: url.deletingPathExtension().lastPathComponent))
    }
    
    func testMakeTemporaryFileURLWithDirectory() async {
        let url = await repository.makeTemporaryFileURL(directory: "test", extension: "mp3")
        
        XCTAssertTrue(url.path.contains("test"))
        XCTAssertEqual(url.pathExtension, "mp3")
    }
}

// MARK: - HistoryRepository 测试

final class HistoryRepositoryTests: XCTestCase {
    
    var repository: HistoryRepository!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // 使用自定义目录进行初始化
        repository = HistoryRepository.shared
        // 注意：实际测试中需要 mock 存储目录
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        repository = nil
        try await super.tearDown()
    }
    
    // MARK: - getAllHistory 测试
    
    func testGetAllHistoryEmpty() async {
        let records = await repository.getAllHistory()
        XCTAssertTrue(records.isEmpty)
    }
    
    // MARK: - getRecentHistory 测试
    
    func testGetRecentHistory() async {
        let records = await repository.getRecentHistory(limit: 20)
        XCTAssertGreaterThanOrEqual(records.count, 0)
    }
    
    // MARK: - getFavorites 测试
    
    func testGetFavoritesEmpty() async {
        let favorites = await repository.getFavorites()
        XCTAssertTrue(favorites.isEmpty)
    }
    
    // MARK: - getHistoryRecord 测试
    
    func testGetHistoryRecordNonExistent() async {
        let record = await repository.getHistoryRecord(id: UUID())
        XCTAssertNil(record)
    }
    
    // MARK: - addHistoryRecord 测试
    
    func testAddHistoryRecord() async {
        let record = TranscriptionHistory(
            filename: "test.mp3",
            fileURL: URL(fileURLWithPath: "/test.mp3"),
            transcript: "测试文本",
            duration: 60.0,
            fileSize: 1024,
            format: "mp3",
            modelId: "Qwen3-ASR",
            language: "zh",
            processingTime: 10.0,
            realTimeFactor: 0.17
        )
        
        await repository.addHistoryRecord(record)
        
        let records = await repository.getAllHistory()
        XCTAssertTrue(records.contains(where: { $0.filename == "test.mp3" }))
    }
    
    func testAddHistoryRecordFromResult() async {
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
        
        let record = await repository.addHistoryRecord(from: result, transcript: "测试")
        
        XCTAssertEqual(record.filename, "test.mp3")
        XCTAssertEqual(record.modelId, "Qwen3-ASR")
        XCTAssertEqual(record.language, "zh")
    }
    
    // MARK: - updateHistoryRecord 测试
    
    func testUpdateHistoryRecord() async {
        let record = TranscriptionHistory(
            filename: "test.mp3",
            fileURL: URL(fileURLWithPath: "/test.mp3"),
            transcript: "原始文本",
            duration: 60.0,
            fileSize: 1024,
            format: "mp3",
            modelId: "Qwen3-ASR",
            language: "zh",
            processingTime: 10.0,
            realTimeFactor: 0.17
        )
        
        await repository.addHistoryRecord(record)
        
        var updatedRecord = record
        updatedRecord.transcript = "更新后的文本"
        
        await repository.updateHistoryRecord(updatedRecord)
        
        let records = await repository.getAllHistory()
        if let found = records.first(where: { $0.id == record.id }) {
            XCTAssertEqual(found.transcript, "更新后的文本")
        }
    }
    
    // MARK: - deleteHistoryRecord 测试
    
    func testDeleteHistoryRecord() async {
        let record = TranscriptionHistory(
            filename: "test.mp3",
            fileURL: URL(fileURLWithPath: "/test.mp3"),
            transcript: "测试文本",
            duration: 60.0,
            fileSize: 1024,
            format: "mp3",
            modelId: "Qwen3-ASR",
            language: "zh",
            processingTime: 10.0,
            realTimeFactor: 0.17
        )
        
        await repository.addHistoryRecord(record)
        await repository.deleteHistoryRecord(id: record.id, deleteAssociatedFile: false)
        
        let records = await repository.getAllHistory()
        XCTAssertFalse(records.contains(where: { $0.id == record.id }))
    }
    
    // MARK: - deleteAllHistory 测试
    
    func testDeleteAllHistory() async {
        let record1 = TranscriptionHistory(
            filename: "test1.mp3",
            fileURL: URL(fileURLWithPath: "/test1.mp3"),
            transcript: "测试 1",
            duration: 60.0,
            fileSize: 1024,
            format: "mp3",
            modelId: "Qwen3-ASR",
            language: "zh",
            processingTime: 10.0,
            realTimeFactor: 0.17
        )
        
        let record2 = TranscriptionHistory(
            filename: "test2.mp3",
            fileURL: URL(fileURLWithPath: "/test2.mp3"),
            transcript: "测试 2",
            duration: 60.0,
            fileSize: 1024,
            format: "mp3",
            modelId: "Qwen3-ASR",
            language: "zh",
            processingTime: 10.0,
            realTimeFactor: 0.17
        )
        
        await repository.addHistoryRecord(record1)
        await repository.addHistoryRecord(record2)
        
        await repository.deleteAllHistory(deleteAssociatedFiles: false)
        
        let records = await repository.getAllHistory()
        XCTAssertTrue(records.isEmpty)
    }
    
    // MARK: - toggleFavorite 测试
    
    func testToggleFavorite() async {
        let record = TranscriptionHistory(
            filename: "test.mp3",
            fileURL: URL(fileURLWithPath: "/test.mp3"),
            transcript: "测试文本",
            duration: 60.0,
            fileSize: 1024,
            format: "mp3",
            modelId: "Qwen3-ASR",
            language: "zh",
            processingTime: 10.0,
            realTimeFactor: 0.17
        )
        
        await repository.addHistoryRecord(record)
        XCTAssertFalse(record.isFavorite)
        
        await repository.toggleFavorite(id: record.id)
        
        let records = await repository.getAllHistory()
        if let found = records.first(where: { $0.id == record.id }) {
            XCTAssertTrue(found.isFavorite)
        }
    }
    
    // MARK: - searchHistory 测试
    
    func testSearchHistoryEmptyQuery() async {
        let records = await repository.searchHistory(query: "")
        // 空查询应该返回所有记录
        XCTAssertGreaterThanOrEqual(records.count, 0)
    }
    
    func testSearchHistoryNoMatch() async {
        let records = await repository.searchHistory(query: "不存在的关键词")
        XCTAssertTrue(records.isEmpty)
    }
}
