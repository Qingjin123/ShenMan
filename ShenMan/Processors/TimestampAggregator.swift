import Foundation

/// 时间戳聚合器
/// 将词级时间戳聚合为句子级时间戳
struct TimestampAggregator {

    // MARK: - 聚合策略

    enum Strategy: Sendable {
        case punctuation      // 按标点符号
        case pauseThreshold   // 按停顿时间
    }

    // MARK: - 缓存的正则表达式（性能优化）

    private static let punctuationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "[。！？\\.!?]", options: [])
    }()

    /// 重复标点正则（internal 访问，供 TranscriptionService 使用）
    static let duplicatePunctuationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "([。！？\\.!?])\\1+", options: [])
    }()

    static let commaSet = Set(["，", ",", "、", "；", ";"])
    static let chineseSentenceEnd = Set(["。", "！", "？", "！", "？"])
    static let englishSentenceEnd = Set([".", "!", "?"])

    // MARK: - 属性

    /// 停顿阈值（秒）
    private let pauseThreshold: TimeInterval

    // MARK: - 初始化

    init(pauseThreshold: TimeInterval = Constants.pauseThreshold) {
        self.pauseThreshold = pauseThreshold
    }

    // MARK: - 公开方法

    /// 聚合时间戳
    /// - Parameters:
    ///   - words: 词级时间戳列表
    ///   - strategy: 聚合策略
    /// - Returns: 句子级时间戳列表
    func aggregate(
        words: [WordTimestamp],
        strategy: Strategy = .punctuation
    ) -> [SentenceTimestamp] {
        guard !words.isEmpty else { return [] }

        switch strategy {
        case .punctuation:
            return aggregateByPunctuation(words: words)
        case .pauseThreshold:
            return aggregateByPause(words: words)
        }
    }

    // MARK: - 私有方法

    /// 按标点符号聚合
    private func aggregateByPunctuation(words: [WordTimestamp]) -> [SentenceTimestamp] {
        var sentences: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []

        for word in words {
            currentWords.append(word)

            // 检测句子边界
            if isSentenceBoundary(word.word) {
                if let sentence = createSentence(from: currentWords) {
                    sentences.append(sentence)
                }
                currentWords = []
            }
        }

        // 处理剩余单词（没有标点结尾）
        if !currentWords.isEmpty {
            if let sentence = createSentence(from: currentWords) {
                sentences.append(sentence)
            }
        }

        return sentences
    }

    /// 按停顿时间聚合
    private func aggregateByPause(words: [WordTimestamp]) -> [SentenceTimestamp] {
        var sentences: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []

        for i in 0..<words.count {
            currentWords.append(words[i])

            // 检测与下一个词的停顿
            if i < words.count - 1 {
                let pause = words[i + 1].startTime - words[i].endTime
                if pause > pauseThreshold {
                    if let sentence = createSentence(from: currentWords) {
                        sentences.append(sentence)
                    }
                    currentWords = []
                }
            }
        }

        // 处理剩余单词
        if !currentWords.isEmpty {
            if let sentence = createSentence(from: currentWords) {
                sentences.append(sentence)
            }
        }

        return sentences
    }

    /// 检测句子边界
    private func isSentenceBoundary(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        // 检查最后一个字符
        if let lastChar = trimmed.last {
            return Self.chineseSentenceEnd.contains(String(lastChar)) || 
                   Self.englishSentenceEnd.contains(String(lastChar))
        }

        return false
    }

    /// 创建句子对象
    private func createSentence(from words: [WordTimestamp]) -> SentenceTimestamp? {
        guard let firstWord = words.first,
              let lastWord = words.last else {
            return nil
        }

        let text = words.map { $0.word }.joined()

        return SentenceTimestamp(
            text: text,
            startTime: firstWord.startTime,
            endTime: lastWord.endTime,
            words: words
        )
    }
}

// MARK: - 扩展方法

extension TimestampAggregator {
    /// 合并短句子
    /// - Parameters:
    ///   - sentences: 句子列表
    ///   - minLength: 最小句子长度（字符数）
    /// - Returns: 合并后的句子列表
    func mergeShortSentences(
        _ sentences: [SentenceTimestamp],
        minLength: Int = 5
    ) -> [SentenceTimestamp] {
        var result: [SentenceTimestamp] = []
        var currentSentence: SentenceTimestamp?

        for sentence in sentences {
            if let current = currentSentence {
                // 如果当前句子太短，合并
                if current.text.count < minLength {
                    let mergedWords = current.words + sentence.words
                    let mergedSentence = SentenceTimestamp(
                        text: current.text + sentence.text,
                        startTime: current.startTime,
                        endTime: sentence.endTime,
                        words: mergedWords
                    )
                    currentSentence = mergedSentence
                } else {
                    result.append(current)
                    currentSentence = sentence
                }
            } else {
                currentSentence = sentence
            }
        }

        if let last = currentSentence {
            result.append(last)
        }

        return result
    }

    /// 分割长句子
    /// - Parameters:
    ///   - sentences: 句子列表
    ///   - maxLength: 最大句子长度（字符数）
    /// - Returns: 分割后的句子列表
    func splitLongSentences(
        _ sentences: [SentenceTimestamp],
        maxLength: Int = 100
    ) -> [SentenceTimestamp] {
        var result: [SentenceTimestamp] = []

        for sentence in sentences {
            if sentence.text.count <= maxLength {
                result.append(sentence)
            } else {
                // 按逗号分割
                let parts = splitByComma(sentence)
                result.append(contentsOf: parts)
            }
        }

        return result
    }

    /// 按逗号分割句子
    private func splitByComma(_ sentence: SentenceTimestamp) -> [SentenceTimestamp] {
        var result: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []

        for word in sentence.words {
            currentWords.append(word)

            if let lastChar = word.word.last,
               Self.commaSet.contains(String(lastChar)) {
                if let newSentence = createSentence(from: currentWords) {
                    result.append(newSentence)
                }
                currentWords = []
            }
        }

        if !currentWords.isEmpty {
            if let newSentence = createSentence(from: currentWords) {
                result.append(newSentence)
            }
        }

        return result
    }
}