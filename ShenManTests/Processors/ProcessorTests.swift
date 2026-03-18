import XCTest
@testable import ShenMan

// MARK: - ChinesePostProcessor 测试

final class ChinesePostProcessorTests: XCTestCase {
    
    var processor: ChinesePostProcessor!
    
    override func setUp() async throws {
        try await super.setUp()
        processor = ChinesePostProcessor()
    }
    
    override func tearDown() async throws {
        processor = nil
        try await super.tearDown()
    }
    
    // MARK: - correctHomophones (单文本) 测试
    
    func testCorrectHomophonesBasic() {
        let text = "这个配备有问题"
        let corrected = processor.correctHomophones(text: text)
        XCTAssertEqual(corrected, "这个配置有问题")
    }
    
    func testCorrectHomophonesMultiple() {
        let text = "这个协义和配备都有问题"
        let corrected = processor.correctHomophones(text: text)
        XCTAssertEqual(corrected, "这个协议和配置都有问题")
    }
    
    func testCorrectHomophonesNoError() {
        let text = "这个配置没有问题"
        let corrected = processor.correctHomophones(text: text)
        XCTAssertEqual(corrected, text)
    }
    
    func testCorrectHomophonesEmpty() {
        let corrected = processor.correctHomophones(text: "")
        XCTAssertEqual(corrected, "")
    }
    
    // MARK: - correctHomophones (句子列表) 测试
    
    func testCorrectHomophonesSentences() {
        let sentences = [
            SentenceTimestamp(text: "这个配备有问题", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "协义很重要", startTime: 1.0, endTime: 2.0)
        ]
        
        let corrected = processor.correctHomophones(sentences: sentences)
        
        XCTAssertEqual(corrected.count, 2)
        XCTAssertEqual(corrected[0].text, "这个配置有问题")
        XCTAssertEqual(corrected[1].text, "协议很重要")
    }
    
    // MARK: - optimizePunctuation (单文本) 测试
    
    func testOptimizePunctuationEnglishToChinese() {
        let text = "你好，世界！今天天气不错，"
        let optimized = processor.optimizePunctuation(text: text)
        XCTAssertEqual(optimized, "你好，今天天气不错，")
    }
    
    func testOptimizePunctuationRepeated() {
        let text = "真的吗！！太好了！！！"
        let optimized = processor.optimizePunctuation(text: text)
        XCTAssertEqual(optimized, "真的吗！太好了！")
    }
    
    func testOptimizePunctuationSpaceBefore() {
        let text = "你好 ， 世界 ！"
        let optimized = processor.optimizePunctuation(text: text)
        XCTAssertEqual(optimized, "你好，世界！")
    }
    
    func testOptimizePunctuationMixed() {
        let text = "Hello , world ! 你好， 世界 ！！"
        let optimized = processor.optimizePunctuation(text: text)
        // 英文逗号转中文，重复标点合并
        XCTAssertTrue(optimized.contains("，"))
        XCTAssertFalse(optimized.contains("!!"))
    }
    
    func testOptimizePunctuationEmpty() {
        let optimized = processor.optimizePunctuation(text: "")
        XCTAssertEqual(optimized, "")
    }
    
    // MARK: - optimizePunctuation (句子列表) 测试
    
    func testOptimizePunctuationSentences() {
        let sentences = [
            SentenceTimestamp(text: "你好，", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "世界！！", startTime: 1.0, endTime: 2.0)
        ]
        
        let optimized = processor.optimizePunctuation(sentences: sentences)
        
        XCTAssertEqual(optimized.count, 2)
        XCTAssertEqual(optimized[0].text, "你好，")
        XCTAssertEqual(optimized[1].text, "世界！")
    }
    
    // MARK: - formatNumbers (单文本) 测试
    
    func testFormatNumbersYear() {
        let text = "二零二五年三月十八日"
        let formatted = processor.formatNumbers(text: text)
        XCTAssertEqual(formatted, "2025 年 3 月 18 日")
    }
    
    func testFormatNumbersTime() {
        let text = "两点钟见面"
        let formatted = processor.formatNumbers(text: text)
        XCTAssertEqual(formatted, "2 点钟见面")
    }
    
    func testFormatNumbersNoNumbers() {
        let text = "今天天气不错"
        let formatted = processor.formatNumbers(text: text)
        XCTAssertEqual(formatted, text)
    }
    
    // MARK: - formatNumbers (句子列表) 测试
    
    func testFormatNumbersSentences() {
        let sentences = [
            SentenceTimestamp(text: "二零二五年", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "三点钟", startTime: 1.0, endTime: 2.0)
        ]
        
        let formatted = processor.formatNumbers(sentences: sentences)
        
        XCTAssertEqual(formatted.count, 2)
        XCTAssertEqual(formatted[0].text, "2025 年")
        XCTAssertEqual(formatted[1].text, "3 点钟")
    }
    
    // MARK: - cleanSpaces (单文本) 测试
    
    func testCleanSpacesBetweenChinese() {
        let text = "你 好 世 界"
        let cleaned = processor.cleanSpaces(text: text)
        XCTAssertEqual(cleaned, "你好世界")
    }
    
    func testCleanSpacesLeadingTrailing() {
        let text = "  你好世界  "
        let cleaned = processor.cleanSpaces(text: text)
        XCTAssertEqual(cleaned, "你好世界")
    }
    
    func testCleanSpacesMultipleSpaces() {
        let text = "a  b   c"
        let cleaned = processor.cleanSpaces(text: text)
        XCTAssertEqual(cleaned, "a b c")
    }
    
    func testCleanSpacesPreserveEnglish() {
        let text = "hello world"
        let cleaned = processor.cleanSpaces(text: text)
        XCTAssertEqual(cleaned, "hello world")
    }
    
    func testCleanSpacesMixed() {
        let text = "  你 好   hello   世界  "
        let cleaned = processor.cleanSpaces(text: text)
        XCTAssertEqual(cleaned, "你好 hello 世界")
    }
    
    func testCleanSpacesEmpty() {
        let cleaned = processor.cleanSpaces(text: "")
        XCTAssertEqual(cleaned, "")
    }
    
    // MARK: - cleanSpaces (句子列表) 测试
    
    func testCleanSpacesSentences() {
        let sentences = [
            SentenceTimestamp(text: "  你 好  ", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "  世 界  ", startTime: 1.0, endTime: 2.0)
        ]
        
        let cleaned = processor.cleanSpaces(sentences: sentences)
        
        XCTAssertEqual(cleaned.count, 2)
        XCTAssertEqual(cleaned[0].text, "你好")
        XCTAssertEqual(cleaned[1].text, "世界")
    }
    
    // MARK: - process (完整流程) 测试
    
    func testProcessFull() {
        let text = "  二零二五年 的 配备  ，  协义 ！！ "
        let processed = processor.process(text: text)
        
        // 验证所有处理步骤都执行
        XCTAssertEqual(processed, "2025 年的配置，协议！")
    }
    
    func testProcessSentences() {
        let sentences = [
            SentenceTimestamp(text: "  二零二五年  的  配备  ", startTime: 0, endTime: 1.0),
            SentenceTimestamp(text: "  协义 ！！  ", startTime: 1.0, endTime: 2.0)
        ]
        
        let processed = processor.process(sentences: sentences)
        
        XCTAssertEqual(processed.count, 2)
        XCTAssertEqual(processed[0].text, "2025 年的配置")
        XCTAssertEqual(processed[1].text, "协议！")
    }
    
    func testProcessEmpty() {
        let processed = processor.process(text: "")
        XCTAssertEqual(processed, "")
    }
}

// MARK: - TimestampAggregator 测试

final class TimestampAggregatorTests: XCTestCase {
    
    var aggregator: TimestampAggregator!
    
    override func setUp() async throws {
        try await super.setUp()
        aggregator = TimestampAggregator()
    }
    
    override func tearDown() async throws {
        aggregator = nil
        try await super.tearDown()
    }
    
    // MARK: - aggregateByPunctuation 测试
    
    func testAggregateByPunctuationChinese() {
        let words = [
            WordTimestamp(word: "你", startTime: 0, endTime: 0.25),
            WordTimestamp(word: "好", startTime: 0.25, endTime: 0.5),
            WordTimestamp(word: "。", startTime: 0.5, endTime: 0.5),
            WordTimestamp(word: "世", startTime: 0.6, endTime: 0.8),
            WordTimestamp(word: "界", startTime: 0.8, endTime: 1.0),
            WordTimestamp(word: "！", startTime: 1.0, endTime: 1.0)
        ]
        
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[0].text, "你好。")
        XCTAssertEqual(sentences[1].text, "世界！")
    }
    
    func testAggregateByPunctuationEnglish() {
        let words = [
            WordTimestamp(word: "Hello", startTime: 0, endTime: 0.5),
            WordTimestamp(word: "world", startTime: 0.5, endTime: 1.0),
            WordTimestamp(word: ".", startTime: 1.0, endTime: 1.0),
            WordTimestamp(word: "How", startTime: 1.2, endTime: 1.5),
            WordTimestamp(word: "are", startTime: 1.5, endTime: 1.8),
            WordTimestamp(word: "you", startTime: 1.8, endTime: 2.0),
            WordTimestamp(word: "?", startTime: 2.0, endTime: 2.0)
        ]
        
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[0].text, "Hello world.")
        XCTAssertEqual(sentences[1].text, "How are you?")
    }
    
    func testAggregateByPunctuationNoEnding() {
        let words = [
            WordTimestamp(word: "没", startTime: 0, endTime: 0.3),
            WordTimestamp(word: "有", startTime: 0.3, endTime: 0.6),
            WordTimestamp(word: "标", startTime: 0.6, endTime: 0.9),
            WordTimestamp(word: "点", startTime: 0.9, endTime: 1.2)
        ]
        
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0].text, "没有标点")
    }
    
    func testAggregateByPunctuationSingleWord() {
        let words = [
            WordTimestamp(word: "好", startTime: 0, endTime: 0.5)
        ]
        
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0].text, "好")
    }
    
    func testAggregateByPunctuationEmpty() {
        let words: [WordTimestamp] = []
        
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        XCTAssertTrue(sentences.isEmpty)
    }
    
    // MARK: - aggregateByPause 测试
    
    func testAggregateByPause() {
        let words = [
            WordTimestamp(word: "你", startTime: 0, endTime: 0.3),
            WordTimestamp(word: "好", startTime: 0.3, endTime: 0.6),
            WordTimestamp(word: "啊", startTime: 2.0, endTime: 2.3), // 停顿 1.4 秒
            WordTimestamp(word: "世", startTime: 2.3, endTime: 2.6),
            WordTimestamp(word: "界", startTime: 2.6, endTime: 2.9)
        ]
        
        let sentences = aggregator.aggregate(words: words, strategy: .pauseThreshold)
        
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[0].text, "你好")
        XCTAssertEqual(sentences[1].text, "啊世界")
    }
    
    func testAggregateByPauseNoPause() {
        let words = [
            WordTimestamp(word: "连", startTime: 0, endTime: 0.2),
            WordTimestamp(word: "续", startTime: 0.2, endTime: 0.4),
            WordTimestamp(word: "说", startTime: 0.4, endTime: 0.6),
            WordTimestamp(word: "话", startTime: 0.6, endTime: 0.8)
        ]
        
        let sentences = aggregator.aggregate(words: words, strategy: .pauseThreshold)
        
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0].text, "连续说话")
    }
    
    // MARK: - isSentenceBoundary 测试
    
    func testIsSentenceBoundaryChinese() {
        XCTAssertTrue(aggregator.isSentenceBoundary("。"))
        XCTAssertTrue(aggregator.isSentenceBoundary("！"))
        XCTAssertTrue(aggregator.isSentenceBoundary("？"))
        XCTAssertFalse(aggregator.isSentenceBoundary("，"))
        XCTAssertFalse(aggregator.isSentenceBoundary("的"))
    }
    
    func testIsSentenceBoundaryEnglish() {
        XCTAssertTrue(aggregator.isSentenceBoundary("."))
        XCTAssertTrue(aggregator.isSentenceBoundary("!"))
        XCTAssertTrue(aggregator.isSentenceBoundary("?"))
        XCTAssertFalse(aggregator.isSentenceBoundary(","))
        XCTAssertFalse(aggregator.isSentenceBoundary("a"))
    }
    
    // MARK: - createSentence 测试
    
    func testCreateSentenceMultipleWords() {
        let words = [
            WordTimestamp(word: "你", startTime: 0, endTime: 0.3),
            WordTimestamp(word: "好", startTime: 0.3, endTime: 0.6),
            WordTimestamp(word: "啊", startTime: 0.6, endTime: 0.9)
        ]
        
        let sentence = aggregator.createSentence(from: words)
        
        XCTAssertNotNil(sentence)
        XCTAssertEqual(sentence?.text, "你好啊")
        XCTAssertEqual(sentence?.startTime, 0)
        XCTAssertEqual(sentence?.endTime, 0.9)
    }
    
    func testCreateSentenceSingleWord() {
        let words = [
            WordTimestamp(word: "好", startTime: 0, endTime: 0.5)
        ]
        
        let sentence = aggregator.createSentence(from: words)
        
        XCTAssertNotNil(sentence)
        XCTAssertEqual(sentence?.text, "好")
        XCTAssertEqual(sentence?.startTime, 0)
        XCTAssertEqual(sentence?.endTime, 0.5)
    }
    
    func testCreateSentenceEmpty() {
        let words: [WordTimestamp] = []
        
        let sentence = aggregator.createSentence(from: words)
        
        XCTAssertNil(sentence)
    }
    
    // MARK: - mergeShortSentences 测试
    
    func testMergeShortSentences() {
        let sentences = [
            SentenceTimestamp(text: "好", startTime: 0, endTime: 0.3),
            SentenceTimestamp(text: "啊", startTime: 0.3, endTime: 0.6),
            SentenceTimestamp(text: "这是一个很长的句子", startTime: 0.6, endTime: 2.0)
        ]
        
        let merged = aggregator.mergeShortSentences(sentences, minLength: 2)
        
        // 前两个短句应该被合并
        XCTAssertGreaterThanOrEqual(merged.count, 2)
    }
    
    func testMergeShortSentencesEmpty() {
        let sentences: [SentenceTimestamp] = []
        
        let merged = aggregator.mergeShortSentences(sentences, minLength: 2)
        
        XCTAssertTrue(merged.isEmpty)
    }
    
    func testMergeShortSentencesSingle() {
        let sentences = [
            SentenceTimestamp(text: "单句", startTime: 0, endTime: 1.0)
        ]
        
        let merged = aggregator.mergeShortSentences(sentences, minLength: 2)
        
        XCTAssertEqual(merged.count, 1)
    }
    
    // MARK: - splitLongSentences 测试
    
    func testSplitLongSentences() {
        let sentences = [
            SentenceTimestamp(text: "这是一个非常非常非常非常非常非常非常非常非常非常长的句子，超过了最大长度限制", startTime: 0, endTime: 10.0)
        ]
        
        let split = aggregator.splitLongSentences(sentences, maxLength: 20)
        
        // 长句应该被分割
        XCTAssertGreaterThanOrEqual(split.count, 1)
    }
    
    func testSplitLongSentencesNotLong() {
        let sentences = [
            SentenceTimestamp(text: "短句", startTime: 0, endTime: 1.0)
        ]
        
        let split = aggregator.splitLongSentences(sentences, maxLength: 20)
        
        XCTAssertEqual(split.count, 1)
        XCTAssertEqual(split[0].text, "短句")
    }
}
