import XCTest
@testable import ShenMan

// MARK: - TXTExporter 测试

final class TXTExporterTests: XCTestCase {
    
    var exporter: TXTExporter!
    
    override func setUp() async throws {
        try await super.setUp()
        exporter = TXTExporter()
    }
    
    override func tearDown() async throws {
        exporter = nil
        try await super.tearDown()
    }
    
    // MARK: - 属性测试
    
    func testFormatName() {
        XCTAssertEqual(exporter.formatName, "纯文本")
    }
    
    func testFileExtension() {
        XCTAssertEqual(exporter.fileExtension, "txt")
    }
    
    func testMimeType() {
        XCTAssertEqual(exporter.mimeType, "text/plain")
    }
    
    // MARK: - export 测试
    
    func testExportBasic() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentences = [
            SentenceTimestamp(text: "第一句", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "第二句", startTime: 1.0, endTime: 2.0)
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences
        )
        
        let options = ExportOptions(
            includeTimestamp: false,
            includeMetadata: false
        )
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertEqual(text, "第一句\n第二句")
    }
    
    func testExportWithTimestamp() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentence = SentenceTimestamp(text: "测试", startTime: 1.5, endTime: 2.5)
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [sentence]
        )
        
        let options = ExportOptions(
            includeTimestamp: true,
            timestampPosition: .start,
            timestampPrecision: .seconds,
            includeMetadata: false
        )
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.contains("[00:02]"))
        XCTAssertTrue(text.contains("测试"))
    }
    
    func testExportTimestampAtEnd() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentence = SentenceTimestamp(text: "测试", startTime: 1.5, endTime: 2.5)
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [sentence]
        )
        
        let options = ExportOptions(
            includeTimestamp: true,
            timestampPosition: .end,
            timestampPrecision: .seconds,
            includeMetadata: false
        )
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.hasSuffix("[00:02]"))
    }
    
    func testExportWithMilliseconds() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentence = SentenceTimestamp(text: "测试", startTime: 1.234, endTime: 2.567)
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [sentence]
        )
        
        let options = ExportOptions(
            includeTimestamp: true,
            timestampPrecision: .milliseconds,
            includeMetadata: false
        )
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.contains("[00:01.234]"))
    }
    
    func testExportWithMetadata() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentence = SentenceTimestamp(text: "测试", startTime: 0, endTime: 1.0)
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [sentence]
        )
        
        let options = ExportOptions(
            includeTimestamp: false,
            includeMetadata: true
        )
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.contains("模型：Qwen3-ASR"))
        XCTAssertTrue(text.contains("时长：10.0 秒"))
    }
    
    func testExportEmptySentences() throws {
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
            sentences: []
        )
        
        let options = ExportOptions(includeMetadata: false)
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.isEmpty)
    }
}

// MARK: - SRTExporter 测试

final class SRTExporterTests: XCTestCase {
    
    var exporter: SRTExporter!
    
    override func setUp() async throws {
        try await super.setUp()
        exporter = SRTExporter()
    }
    
    override func tearDown() async throws {
        exporter = nil
        try await super.tearDown()
    }
    
    // MARK: - 属性测试
    
    func testFormatName() {
        XCTAssertEqual(exporter.formatName, "字幕文件")
    }
    
    func testFileExtension() {
        XCTAssertEqual(exporter.fileExtension, "srt")
    }
    
    func testMimeType() {
        XCTAssertEqual(exporter.mimeType, "application/x-subrip")
    }
    
    // MARK: - export 测试
    
    func testExportBasic() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentences = [
            SentenceTimestamp(text: "第一句", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "第二句", startTime: 1.5, endTime: 2.5)
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences
        )
        
        let data = try exporter.export(result: result, options: ExportOptions())
        let text = String(data: data, encoding: .utf8)!
        
        // 验证 SRT 格式
        XCTAssertTrue(text.contains("1\n"))
        XCTAssertTrue(text.contains("00:00:00,000 --> 00:00:01,000"))
        XCTAssertTrue(text.contains("第一句"))
        XCTAssertTrue(text.contains("2\n"))
        XCTAssertTrue(text.contains("00:00:01,500 --> 00:00:02,500"))
        XCTAssertTrue(text.contains("第二句"))
    }
    
    func testExportEmptySentences() throws {
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
            sentences: []
        )
        
        let data = try exporter.export(result: result, options: ExportOptions())
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.isEmpty)
    }
    
    // MARK: - formatSRTTime 测试
    
    func testFormatSRTTimeZero() {
        let time = exporter.formatSRTTime(0)
        XCTAssertEqual(time, "00:00:00,000")
    }
    
    func testFormatSRTTimeOneSecond() {
        let time = exporter.formatSRTTime(1.0)
        XCTAssertEqual(time, "00:00:01,000")
    }
    
    func testFormatSRTTimeWithMilliseconds() {
        let time = exporter.formatSRTTime(1.234)
        XCTAssertEqual(time, "00:00:01,234")
    }
    
    func testFormatSRTTimeOneMinute() {
        let time = exporter.formatSRTTime(65.123)
        XCTAssertEqual(time, "00:01:05,123")
    }
    
    func testFormatSRTTimeOneHour() {
        let time = exporter.formatSRTTime(3665.999)
        XCTAssertEqual(time, "01:01:05,999")
    }
    
    func testFormatSRTTimeNegative() {
        let time = exporter.formatSRTTime(-1.0)
        // 负数时间应该处理为 0
        XCTAssertEqual(time, "00:00:00,000")
    }
}

// MARK: - MarkdownExporter 测试

final class MarkdownExporterTests: XCTestCase {
    
    var exporter: MarkdownExporter!
    
    override func setUp() async throws {
        try await super.setUp()
        exporter = MarkdownExporter()
    }
    
    override func tearDown() async throws {
        exporter = nil
        try await super.tearDown()
    }
    
    // MARK: - 属性测试
    
    func testFormatName() {
        XCTAssertEqual(exporter.formatName, "Markdown")
    }
    
    func testFileExtension() {
        XCTAssertEqual(exporter.fileExtension, "md")
    }
    
    func testMimeType() {
        XCTAssertEqual(exporter.mimeType, "text/markdown")
    }
    
    // MARK: - export 测试
    
    func testExportBasic() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentences = [
            SentenceTimestamp(text: "第一句", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "第二句", startTime: 1.0, endTime: 2.0)
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences
        )
        
        let data = try exporter.export(result: result, options: ExportOptions(includeMetadata: false))
        let text = String(data: data, encoding: .utf8)!
        
        // 验证 Markdown 格式
        XCTAssertTrue(text.contains("# test"))
        XCTAssertTrue(text.contains("- 第一句"))
        XCTAssertTrue(text.contains("- 第二句"))
        XCTAssertTrue(text.contains("声声慢"))
    }
    
    func testExportWithTimestamp() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentence = SentenceTimestamp(text: "测试", startTime: 1.5, endTime: 2.5)
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [sentence]
        )
        
        let options = ExportOptions(
            includeTimestamp: true,
            timestampPrecision: .seconds,
            includeMetadata: false
        )
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(text.contains("**[00:02]** 测试"))
    }
    
    func testExportWithMetadata() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentence = SentenceTimestamp(text: "测试", startTime: 0, endTime: 1.0)
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: [sentence]
        )
        
        let options = ExportOptions(includeMetadata: true)
        
        let data = try exporter.export(result: result, options: options)
        let text = String(data: data, encoding: .utf8)!
        
        // 验证元数据表格
        XCTAssertTrue(text.contains("| 模型 | Qwen3-ASR |"))
        XCTAssertTrue(text.contains("| 时长 | 10.0 秒 |"))
    }
    
    func testExportFilenameWithoutExtension() throws {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.with.dots.mp3",
            duration: 10.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: []
        )
        
        let data = try exporter.export(result: result, options: ExportOptions(includeMetadata: false))
        let text = String(data: data, encoding: .utf8)!
        
        // 验证标题不包含扩展名
        XCTAssertTrue(text.contains("# test.with.dots"))
        XCTAssertFalse(text.contains("# test.with.dots.mp3"))
    }
    
    func testExportEmptySentences() throws {
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
            sentences: []
        )
        
        let data = try exporter.export(result: result, options: ExportOptions(includeMetadata: false))
        let text = String(data: data, encoding: .utf8)!
        
        // 仍然包含标题和页脚
        XCTAssertTrue(text.contains("# test"))
        XCTAssertTrue(text.contains("声声慢"))
    }
}
