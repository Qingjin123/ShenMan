import XCTest
@testable import ShenMan

// MARK: - TranscriptionResult 测试

final class TranscriptionResultTests: XCTestCase {
    
    // MARK: - WordTimestamp 测试
    
    func testWordTimestampInitialization() {
        let word = WordTimestamp(
            word: "测试",
            startTime: 1.0,
            endTime: 2.0,
            confidence: 0.95
        )
        
        XCTAssertEqual(word.word, "测试")
        XCTAssertEqual(word.startTime, 1.0)
        XCTAssertEqual(word.endTime, 2.0)
        XCTAssertEqual(word.confidence, 0.95)
        XCTAssertNotNil(word.id)
    }
    
    func testWordTimestampDefaultConfidence() {
        let word = WordTimestamp(word: "测试", startTime: 0, endTime: 1.0)
        XCTAssertEqual(word.confidence, 1.0)
    }
    
    // MARK: - SentenceTimestamp 测试
    
    func testSentenceTimestampInitialization() {
        let sentence = SentenceTimestamp(
            text: "这是一个测试句子",
            startTime: 0,
            endTime: 3.0
        )
        
        XCTAssertEqual(sentence.text, "这是一个测试句子")
        XCTAssertEqual(sentence.startTime, 0)
        XCTAssertEqual(sentence.endTime, 3.0)
        XCTAssertEqual(sentence.duration, 3.0)
        XCTAssertNil(sentence.speaker)
        XCTAssertTrue(sentence.words.isEmpty)
    }
    
    func testSentenceTimestampDuration() {
        let sentence = SentenceTimestamp(text: "测试", startTime: 1.0, endTime: 2.5)
        XCTAssertEqual(sentence.duration, 1.5)
    }
    
    // MARK: - TranscriptionMetadata 测试
    
    func testTranscriptionMetadataInitialization() {
        let metadata = TranscriptionMetadata(
            modelVersion: "Qwen3-ASR-0.6B",
            audioDuration: 120.0,
            realTimeFactor: 0.5
        )
        
        XCTAssertEqual(metadata.modelVersion, "Qwen3-ASR-0.6B")
        XCTAssertEqual(metadata.audioDuration, 120.0)
        XCTAssertEqual(metadata.realTimeFactor, 0.5)
        XCTAssertNotNil(metadata.processingDate)
    }
    
    // MARK: - TranscriptionResult 测试
    
    func testTranscriptionResultInitialization() {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3,
            sampleRate: 16000,
            channels: 1
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
        
        XCTAssertNotNil(result.id)
        XCTAssertEqual(result.audioFile, audioFile)
        XCTAssertEqual(result.modelName, "Qwen3-ASR")
        XCTAssertEqual(result.language, "zh")
        XCTAssertEqual(result.sentences.count, 2)
        XCTAssertEqual(result.fullText, "第一句第二句")
        XCTAssertNotNil(result.metadata)
    }
    
    func testTranscriptionResultCustomFullText() {
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
            sentences: [],
            fullText: "自定义文本"
        )
        
        XCTAssertEqual(result.fullText, "自定义文本")
    }
    
    func testTranscriptionResultTotalWords() {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentences = [
            SentenceTimestamp(
                text: "你好世界",
                startTime: 0,
                endTime: 1.0,
                words: [
                    WordTimestamp(word: "你", startTime: 0, endTime: 0.25),
                    WordTimestamp(word: "好", startTime: 0.25, endTime: 0.5),
                    WordTimestamp(word: "世", startTime: 0.5, endTime: 0.75),
                    WordTimestamp(word: "界", startTime: 0.75, endTime: 1.0)
                ]
            )
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences
        )
        
        XCTAssertEqual(result.totalWords, 4)
    }
    
    func testTranscriptionResultAverageConfidence() {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let sentences = [
            SentenceTimestamp(
                text: "测试",
                startTime: 0,
                endTime: 1.0,
                words: [
                    WordTimestamp(word: "测", startTime: 0, endTime: 0.5, confidence: 0.8),
                    WordTimestamp(word: "试", startTime: 0.5, endTime: 1.0, confidence: 0.9)
                ]
            )
        ]
        
        let result = TranscriptionResult(
            audioFile: audioFile,
            modelName: "Qwen3-ASR",
            language: "zh",
            sentences: sentences
        )
        
        XCTAssertEqual(result.averageConfidence, 0.85, accuracy: 0.01)
    }
    
    func testTranscriptionResultEmptySentences() {
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
            sentences: []
        )
        
        XCTAssertEqual(result.totalWords, 0)
        XCTAssertEqual(result.averageConfidence, 0)
    }
}

// MARK: - BatchProcessingQueue 测试

final class BatchProcessingQueueTests: XCTestCase {
    
    func testTranscriptionTaskStatusRawValues() {
        XCTAssertEqual(TranscriptionTaskStatus.pending.rawValue, "pending")
        XCTAssertEqual(TranscriptionTaskStatus.processing.rawValue, "processing")
        XCTAssertEqual(TranscriptionTaskStatus.completed.rawValue, "completed")
        XCTAssertEqual(TranscriptionTaskStatus.failed.rawValue, "failed")
        XCTAssertEqual(TranscriptionTaskStatus.cancelled.rawValue, "cancelled")
    }
    
    func testTranscriptionTaskInitialization() {
        let audioFile = AudioFile(
            url: URL(fileURLWithPath: "/test.mp3"),
            filename: "test.mp3",
            duration: 60.0,
            fileSize: 1024,
            format: .mp3
        )
        
        let task = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        
        XCTAssertEqual(task.audioFile, audioFile)
        XCTAssertEqual(task.modelId, .qwen3ASR06B8bit)
        XCTAssertEqual(task.status, .pending)
        XCTAssertEqual(task.progress, 0)
        XCTAssertNil(task.result)
        XCTAssertNil(task.error)
        XCTAssertNotNil(task.createdAt)
    }
    
    func testTranscriptionHistoryInitialization() {
        let history = TranscriptionHistory(
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
        
        XCTAssertEqual(history.filename, "test.mp3")
        XCTAssertEqual(history.transcript, "测试文本")
        XCTAssertEqual(history.duration, 60.0)
        XCTAssertEqual(history.fileSize, 1024)
        XCTAssertEqual(history.format, "mp3")
        XCTAssertEqual(history.modelId, "Qwen3-ASR")
        XCTAssertEqual(history.language, "zh")
        XCTAssertEqual(history.processingTime, 10.0)
        XCTAssertEqual(history.realTimeFactor, 0.17)
        XCTAssertTrue(history.exportedFormats.isEmpty)
        XCTAssertFalse(history.isFavorite)
        XCTAssertTrue(history.tags.isEmpty)
    }
    
    func testBatchProcessingQueueInitialization() {
        let queue = BatchProcessingQueue()
        
        XCTAssertNotNil(queue.id)
        XCTAssertTrue(queue.tasks.isEmpty)
        XCTAssertEqual(queue.status, .idle)
        XCTAssertNil(queue.currentTaskId)
    }
    
    func testBatchProcessingQueuePendingTasks() {
        let queue = BatchProcessingQueue()
        let audioFile1 = AudioFile(url: URL(fileURLWithPath: "/test1.mp3"), filename: "test1.mp3", duration: 60, fileSize: 1024, format: .mp3)
        let audioFile2 = AudioFile(url: URL(fileURLWithPath: "/test2.mp3"), filename: "test2.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        queue.addTask(TranscriptionTask(audioFile: audioFile1, modelId: .qwen3ASR06B8bit))
        let task2 = TranscriptionTask(audioFile: audioFile2, modelId: .qwen3ASR06B8bit)
        task2.status = .completed
        queue.addTask(task2)
        
        XCTAssertEqual(queue.pendingTasks.count, 1)
    }
    
    func testBatchProcessingQueueCompletedTasks() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .completed
        queue.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .pending
        queue.addTask(task2)
        
        XCTAssertEqual(queue.completedTasks.count, 1)
    }
    
    func testBatchProcessingQueueFailedTasks() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .failed
        queue.addTask(task1)
        
        XCTAssertEqual(queue.failedTasks.count, 1)
    }
    
    func testBatchProcessingQueueOverallProgress() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .completed
        task1.progress = 1.0
        queue.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .processing
        task2.progress = 0.5
        queue.addTask(task2)
        
        XCTAssertEqual(queue.overallProgress, 0.75, accuracy: 0.01)
    }
    
    func testBatchProcessingQueueAddTasks() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let tasks = [
            TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit),
            TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        ]
        
        queue.addTasks(tasks)
        XCTAssertEqual(queue.tasks.count, 2)
    }
    
    func testBatchProcessingQueueRemoveTask() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        let task = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        queue.addTask(task)
        
        let removed = queue.removeTask(id: task.id)
        XCTAssertNotNil(removed)
        XCTAssertTrue(queue.tasks.isEmpty)
        
        let notRemoved = queue.removeTask(id: task.id)
        XCTAssertNil(notRemoved)
    }
    
    func testBatchProcessingQueueClearCompleted() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        
        let task1 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task1.status = .completed
        queue.addTask(task1)
        
        let task2 = TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit)
        task2.status = .pending
        queue.addTask(task2)
        
        queue.clearCompleted()
        XCTAssertEqual(queue.tasks.count, 1)
        XCTAssertEqual(queue.tasks[0].status, .pending)
    }
    
    func testBatchProcessingQueueClearAll() {
        let queue = BatchProcessingQueue()
        let audioFile = AudioFile(url: URL(fileURLWithPath: "/test.mp3"), filename: "test.mp3", duration: 60, fileSize: 1024, format: .mp3)
        queue.addTask(TranscriptionTask(audioFile: audioFile, modelId: .qwen3ASR06B8bit))
        
        queue.clearAll()
        XCTAssertTrue(queue.tasks.isEmpty)
        XCTAssertEqual(queue.status, .idle)
        XCTAssertNil(queue.currentTaskId)
    }
}

// MARK: - ExportOptions 测试

final class ExportOptionsTests: XCTestCase {
    
    func testExportOptionsDefaultInitialization() {
        let options = ExportOptions()
        
        XCTAssertTrue(options.includeTimestamp)
        XCTAssertEqual(options.timestampPosition, .start)
        XCTAssertEqual(options.timestampPrecision, .milliseconds)
        XCTAssertTrue(options.includeMetadata)
    }
    
    func testExportOptionsCustomInitialization() {
        let options = ExportOptions(
            includeTimestamp: false,
            timestampPosition: .end,
            timestampPrecision: .seconds,
            includeMetadata: false
        )
        
        XCTAssertFalse(options.includeTimestamp)
        XCTAssertEqual(options.timestampPosition, .end)
        XCTAssertEqual(options.timestampPrecision, .seconds)
        XCTAssertFalse(options.includeMetadata)
    }
    
    func testExportOptionsFromSettings() {
        let settings = AppSettings()
        let options = ExportOptions(from: settings)
        
        XCTAssertEqual(options.includeTimestamp, settings.exportIncludeTimestamp)
        XCTAssertEqual(options.timestampPosition, settings.exportTimestampPosition)
        XCTAssertEqual(options.timestampPrecision, settings.exportTimestampPrecision)
        XCTAssertEqual(options.includeMetadata, settings.exportIncludeMetadata)
    }
}

// MARK: - Language 测试

final class LanguageTests: XCTestCase {
    
    func testLanguageRawValues() {
        XCTAssertEqual(Language.auto.rawValue, "auto")
        XCTAssertEqual(Language.chinese.rawValue, "zh")
        XCTAssertEqual(Language.english.rawValue, "en")
    }
    
    func testLanguageId() {
        XCTAssertEqual(Language.auto.id, "auto")
        XCTAssertEqual(Language.chinese.id, "zh")
        XCTAssertEqual(Language.english.id, "en")
    }
    
    func testLanguageDisplayName() {
        XCTAssertEqual(Language.auto.displayName, "自动检测")
        XCTAssertEqual(Language.chinese.displayName, "中文")
        XCTAssertEqual(Language.english.displayName, "English")
    }
    
    func testLanguageQwenLanguageCode() {
        XCTAssertEqual(Language.chinese.qwenLanguageCode, "zh")
        XCTAssertEqual(Language.english.qwenLanguageCode, "en")
    }
}

// MARK: - AppSettings 测试

final class AppSettingsTests: XCTestCase {
    
    func testAppSettingsSingleton() {
        let settings1 = AppSettings.shared
        let settings2 = AppSettings.shared
        XCTAssertTrue(settings1 === settings2)
    }
    
    func testAppSettingsDefaultValues() {
        let settings = AppSettings()
        
        XCTAssertEqual(settings.defaultLanguage, .auto)
        XCTAssertEqual(settings.defaultModel, .qwen3ASR06B8bit)
        XCTAssertEqual(settings.defaultSampleRate, 16000)
        XCTAssertEqual(settings.pauseThreshold, 0.5)
        XCTAssertEqual(settings.aggregationStrategy, .punctuation)
        XCTAssertTrue(settings.enableChinesePostProcessing)
        XCTAssertTrue(settings.enableChineseCorrection)
        XCTAssertTrue(settings.enablePunctuationOptimization)
        XCTAssertTrue(settings.enableNumberFormatting)
        XCTAssertEqual(settings.exportFormat, .txt)
        XCTAssertTrue(settings.exportIncludeTimestamp)
        XCTAssertEqual(settings.exportTimestampPosition, .start)
        XCTAssertEqual(settings.exportTimestampPrecision, .milliseconds)
        XCTAssertTrue(settings.exportIncludeMetadata)
    }
    
    func testTimestampPositionDisplayName() {
        XCTAssertEqual(AppSettings.TimestampPosition.start.displayName, "句首")
        XCTAssertEqual(AppSettings.TimestampPosition.end.displayName, "句尾")
    }
    
    func testTimestampPrecisionDisplayName() {
        XCTAssertEqual(AppSettings.TimestampPrecision.seconds.displayName, "秒")
        XCTAssertEqual(AppSettings.TimestampPrecision.milliseconds.displayName, "毫秒")
    }
    
    func testAggregationStrategyDisplayName() {
        XCTAssertEqual(AppSettings.AggregationStrategy.punctuation.displayName, "按标点符号")
        XCTAssertEqual(AppSettings.AggregationStrategy.pauseThreshold.displayName, "按停顿阈值")
    }
    
    func testExportFormatDisplayName() {
        XCTAssertEqual(AppSettings.ExportFormat.txt.displayName, "纯文本 (.txt)")
        XCTAssertEqual(AppSettings.ExportFormat.srt.displayName, "字幕文件 (.srt)")
        XCTAssertEqual(AppSettings.ExportFormat.markdown.displayName, "Markdown (.md)")
    }
    
    func testExportFormatFileExtension() {
        XCTAssertEqual(AppSettings.ExportFormat.txt.fileExtension, "txt")
        XCTAssertEqual(AppSettings.ExportFormat.srt.fileExtension, "srt")
        XCTAssertEqual(AppSettings.ExportFormat.markdown.fileExtension, "md")
    }
}
