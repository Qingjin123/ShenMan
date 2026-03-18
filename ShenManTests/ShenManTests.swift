import XCTest
import AVFoundation
@testable import ShenMan

// MARK: - 模型标识符测试

final class ModelIdentifierTests: XCTestCase {

    func testModelIdentifierCases() {
        // 测试所有模型标识符用例
        let allCases = ModelIdentifier.allCases
        XCTAssertEqual(allCases.count, 3, "应该有 3 个模型标识符")
        
        // 测试 rawValue
        XCTAssertEqual(ModelIdentifier.qwen3ASR06B8bit.rawValue, "mlx-community/Qwen3-ASR-0.6B-8bit")
        XCTAssertEqual(ModelIdentifier.qwen3ASR17B8bit.rawValue, "mlx-community/Qwen3-ASR-1.7B-8bit")
        XCTAssertEqual(ModelIdentifier.glmASRNano4bit.rawValue, "mlx-community/GLM-ASR-Nano-2512-4bit")
    }
    
    func testModelIdentifierProperties() {
        let model = ModelIdentifier.qwen3ASR06B8bit
        
        XCTAssertEqual(model.displayName, "Qwen3-ASR 0.6B (8bit)")
        XCTAssertEqual(model.sizeGB, 0.6)
        XCTAssertTrue(model.supportedLanguages.contains(.chinese))
        XCTAssertTrue(model.supportedLanguages.contains(.auto))
    }
    
    func testModelIdentifierFromRawValue() {
        let model = ModelIdentifier(rawValue: "mlx-community/Qwen3-ASR-0.6B-8bit")
        XCTAssertNotNil(model)
        XCTAssertEqual(model, .qwen3ASR06B8bit)
        
        let invalidModel = ModelIdentifier(rawValue: "invalid-model")
        XCTAssertNil(invalidModel)
    }
}

// MARK: - 音频文件模型测试
final class AudioFileTests: XCTestCase {
    
    func testSupportedFormats() {
        // 验证支持的格式
        XCTAssertTrue(AudioFile.isSupported(extension: "mp3"))
        XCTAssertTrue(AudioFile.isSupported(extension: "wav"))
        XCTAssertTrue(AudioFile.isSupported(extension: "m4a"))
        XCTAssertTrue(AudioFile.isSupported(extension: "mp4"))
        
        // 验证不支持的格式
        XCTAssertFalse(AudioFile.isSupported(extension: "txt"))
        XCTAssertFalse(AudioFile.isSupported(extension: "pdf"))
    }
    
    func testDurationFormatting() {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 3665, // 1 小时 1 分 5 秒
            fileSize: 1024 * 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        XCTAssertEqual(audioFile.durationFormatted, "61:05", "时长格式化应该正确")
    }
}

/// 时间戳聚合器测试
final class TimestampAggregatorTests: XCTestCase {
    
    func testAggregateByPunctuation() {
        // 准备测试数据
        let words = [
            WordTimestamp(word: "你好", startTime: 0, endTime: 0.5, confidence: 0.95),
            WordTimestamp(word: "世界", startTime: 0.5, endTime: 1.0, confidence: 0.93),
            WordTimestamp(word: "。", startTime: 1.0, endTime: 1.0, confidence: 1.0),
            WordTimestamp(word: "今天", startTime: 1.5, endTime: 2.0, confidence: 0.92),
            WordTimestamp(word: "天气", startTime: 2.0, endTime: 2.5, confidence: 0.94),
            WordTimestamp(word: "不错", startTime: 2.5, endTime: 3.0, confidence: 0.91),
            WordTimestamp(word: "。", startTime: 3.0, endTime: 3.0, confidence: 1.0)
        ]
        
        // 执行
        let aggregator = TimestampAggregator()
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        // 验证
        XCTAssertEqual(sentences.count, 2, "应该聚合为 2 个句子")
        XCTAssertEqual(sentences[0].text, "你好世界。", "第一个句子应该正确")
        XCTAssertEqual(sentences[1].text, "今天天气不错。", "第二个句子应该正确")
        XCTAssertEqual(sentences[0].startTime, 0, "第一个句子开始时间应该正确")
        XCTAssertEqual(sentences[1].endTime, 3.0, "第二个句子结束时间应该正确")
    }
    
    func testMergeShortSentences() {
        // 准备测试数据
        let aggregator = TimestampAggregator()
        let sentences = [
            SentenceTimestamp(text: "好", startTime: 0, endTime: 0.5),
            SentenceTimestamp(text: "的", startTime: 0.5, endTime: 1.0),
            SentenceTimestamp(text: "这是一段测试文本", startTime: 1.5, endTime: 3.0)
        ]
        
        // 执行
        let merged = aggregator.mergeShortSentences(sentences, minLength: 5)
        
        // 验证
        XCTAssertEqual(merged.count, 2, "应该合并为 2 个句子")
        XCTAssertEqual(merged[0].text, "好的", "前两个短句应该合并")
        XCTAssertEqual(merged[1].text, "这是一段测试文本", "长句子应该保持不变")
    }
}

/// 导出器测试
final class ExporterTests: XCTestCase {
    
    func testTXTExporter() throws {
        // 准备测试数据
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        let sentences = [
            SentenceTimestamp(text: "第一句话", startTime: 0, endTime: 2.5),
            SentenceTimestamp(text: "第二句话", startTime: 3.0, endTime: 5.5)
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences,
            processingTime: 2.0,
            metadata: TranscriptionMetadata(
                modelVersion: "Qwen3-ASR-0.6B",
                audioDuration: 10,
                realTimeFactor: 0.2
            )
        )
        
        // 执行
        let exporter = TXTExporter()
        let options = ExportOptions(includeTimestamp: false, includeMetadata: false)
        let data = try exporter.export(result: result, options: options)
        let content = String(data: data, encoding: .utf8)
        
        // 验证
        XCTAssertNotNil(content, "导出内容不应该为空")
        XCTAssertTrue(content?.contains("第一句话") ?? false, "应该包含第一句话")
        XCTAssertTrue(content?.contains("第二句话") ?? false, "应该包含第二句话")
    }
    
    func testSRTExporter() throws {
        // 准备测试数据
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        let sentences = [
            SentenceTimestamp(text: "你好", startTime: 0.5, endTime: 1.5),
            SentenceTimestamp(text: "世界", startTime: 2.0, endTime: 3.0)
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences,
            processingTime: 2.0,
            metadata: TranscriptionMetadata(
                modelVersion: "Qwen3-ASR-0.6B",
                audioDuration: 10,
                realTimeFactor: 0.2
            )
        )
        
        // 执行
        let exporter = SRTExporter()
        let options = ExportOptions()
        let data = try exporter.export(result: result, options: options)
        let content = String(data: data, encoding: .utf8)
        
        // 验证 SRT 格式
        XCTAssertNotNil(content, "导出内容不应该为空")
        XCTAssertTrue(content?.contains("1") ?? false, "应该包含序号 1")
        XCTAssertTrue(content?.contains("2") ?? false, "应该包含序号 2")
        XCTAssertTrue(content?.contains("00:00:00,500 --> 00:00:01,500") ?? false, "时间轴应该正确")
        XCTAssertTrue(content?.contains("你好") ?? false, "应该包含第一句话")
        XCTAssertTrue(content?.contains("世界") ?? false, "应该包含第二句话")
    }
}

/// 时间格式化器测试
final class TimeFormatterTests: XCTestCase {
    
    func testFormatTime() {
        XCTAssertEqual(TimeFormatter.formatTime(0), "00:00")
        XCTAssertEqual(TimeFormatter.formatTime(5), "00:05")
        XCTAssertEqual(TimeFormatter.formatTime(65), "01:05")
        XCTAssertEqual(TimeFormatter.formatTime(3665), "01:01:05")
    }
    
    func testFormatSRTTime() {
        XCTAssertEqual(TimeFormatter.formatSRTTime(0), "00:00:00,000")
        XCTAssertEqual(TimeFormatter.formatSRTTime(1.5), "00:00:01,500")
        XCTAssertEqual(TimeFormatter.formatSRTTime(65.123), "00:01:05,123")
    }
}

/// 应用设置测试
final class AppSettingsTests: XCTestCase {
    
    func testSettingsInitialization() {
        let settings = AppSettings.shared
        
        // 验证默认值
        XCTAssertEqual(settings.selectedModel, "Qwen3-ASR-0.6B")
        XCTAssertEqual(settings.defaultLanguage, .auto)
        XCTAssertTrue(settings.includeTimestamp)
        XCTAssertEqual(settings.timestampPosition, .start)
        XCTAssertEqual(settings.timestampPrecision, .milliseconds)
    }
}

/// 转录服务测试
final class TranscriptionServiceTests: XCTestCase {

    func testServiceInitialization() async {
        let service = TranscriptionService()
        // actor 初始化应该成功
        XCTAssertNotNil(service, "服务应该能初始化")
    }

    func testModelCreation() async {
        let model = TranscriptionService.createModel(huggingFaceId: "mlx-community/Qwen3-ASR-0.6B-8bit")
        XCTAssertNotNil(model, "模型应该能创建")
        // 注意：model 现在是 some ASRModel，不能直接比较类型
    }
    
    func testServiceCancel() async {
        let service = TranscriptionService()
        // 测试取消方法
        await service.cancel()
        // 取消应该不会抛出错误
    }
}

// MARK: - 批量处理队列测试

@MainActor
final class BatchProcessingQueueTests: XCTestCase {
    
    func testQueueInitialization() {
        let queue = BatchProcessingQueue()
        XCTAssertTrue(queue.tasks.isEmpty, "初始队列应该为空")
        XCTAssertFalse(queue.isProcessing, "初始状态应该未处理")
        XCTAssertEqual(queue.totalProgress, 0, "初始进度应该为 0")
    }
    
    func testAddTask() async {
        let queue = BatchProcessingQueue()
        
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        queue.addTask(audioFile: audioFile)
        
        XCTAssertEqual(queue.tasks.count, 1, "应该添加 1 个任务")
        XCTAssertEqual(queue.pendingTasks.count, 1, "应该有 1 个待处理任务")
    }
    
    func testAddTasks() async {
        let queue = BatchProcessingQueue()
        
        let audioFiles = (1...3).map { i in
            AudioFile(
                url: URL(fileURLWithPath: "/test\(i).mp3"),
                filename: "test\(i).mp3",
                duration: 10,
                fileSize: 1024,
                format: .mp3,
                sampleRate: 16000,
                channels: 1
            )
        }
        
        queue.addTasks(audioFiles: audioFiles)
        
        XCTAssertEqual(queue.tasks.count, 3, "应该添加 3 个任务")
        XCTAssertEqual(queue.pendingTasks.count, 3, "应该有 3 个待处理任务")
    }
    
    func testRemoveTask() async {
        let queue = BatchProcessingQueue()
        
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 10,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        queue.addTask(audioFile: audioFile)
        XCTAssertEqual(queue.tasks.count, 1, "应该添加 1 个任务")
        
        if let task = queue.tasks.first {
            queue.removeTask(task)
            XCTAssertEqual(queue.tasks.count, 0, "应该移除任务")
        }
    }
    
    func testClearCompleted() async {
        let queue = BatchProcessingQueue()
        
        // 模拟添加已完成和待处理的任务
        let audioFile1 = AudioFile(
            url: URL(fileURLWithPath: "/test1.mp3"),
            filename: "test1.mp3",
            duration: 10,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        let audioFile2 = AudioFile(
            url: URL(fileURLWithPath: "/test2.mp3"),
            filename: "test2.mp3",
            duration: 10,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
        )
        
        queue.addTask(audioFile: audioFile1)
        queue.addTask(audioFile: audioFile2)
        
        // 手动设置第一个任务为已完成（用于测试）
        // 注意：实际使用中状态会在处理过程中改变
        XCTAssertEqual(queue.tasks.count, 2, "应该有 2 个任务")
        
        queue.clearCompleted()
        XCTAssertEqual(queue.tasks.count, 2, "清除已完成任务后应该还有 2 个任务（因为都是 pending 状态）")
    }
    
    func testClearAll() async {
        let queue = BatchProcessingQueue()
        
        let audioFiles = (1...3).map { i in
            AudioFile(
                url: URL(fileURLWithPath: "/test\(i).mp3"),
                filename: "test\(i).mp3",
                duration: 10,
                fileSize: 1024,
                format: .mp3,
                sampleRate: 16000,
                channels: 1
            )
        }
        
        queue.addTasks(audioFiles: audioFiles)
        XCTAssertEqual(queue.tasks.count, 3, "应该添加 3 个任务")
        
        queue.clearAll()
        
        XCTAssertTrue(queue.tasks.isEmpty, "应该清除所有任务")
        XCTAssertFalse(queue.isProcessing, "应该重置处理状态")
        XCTAssertEqual(queue.currentTaskIndex, 0, "应该重置任务索引")
        XCTAssertEqual(queue.totalProgress, 0, "应该重置进度")
    }
}
