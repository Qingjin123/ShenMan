import Foundation

/// 词级时间戳
/// 表示单个词的时间信息
struct WordTimestamp: Sendable, Identifiable, Hashable {
    let id: UUID
    let word: String
    let startTime: TimeInterval    // 开始时间（秒）
    let endTime: TimeInterval      // 结束时间（秒）
    let confidence: Double         // 置信度 0-1
    
    init(
        id: UUID = UUID(),
        word: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        confidence: Double = 1.0
    ) {
        self.id = id
        self.word = word
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
}

/// 句子级时间戳
/// 表示一个句子的时间信息
struct SentenceTimestamp: Sendable, Identifiable, Hashable {
    let id: UUID
    var text: String               // 句子文本
    let startTime: TimeInterval    // 开始时间（秒）
    let endTime: TimeInterval      // 结束时间（秒）
    let words: [WordTimestamp]     // 包含的词列表
    var speaker: String?           // 说话人标识（v2.0）
    
    init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        words: [WordTimestamp] = [],
        speaker: String? = nil
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.words = words
        self.speaker = speaker
    }
    
    /// 句子时长
    var duration: TimeInterval {
        endTime - startTime
    }
}

/// 转录元数据
/// 记录转录过程的相关信息
struct TranscriptionMetadata: Sendable, Codable {
    let modelVersion: String       // 模型版本
    let processingDate: Date       // 处理日期
    let audioDuration: TimeInterval // 音频时长
    let realTimeFactor: Double     // 实时因子（RTF）
    
    init(
        modelVersion: String,
        processingDate: Date = Date(),
        audioDuration: TimeInterval,
        realTimeFactor: Double
    ) {
        self.modelVersion = modelVersion
        self.processingDate = processingDate
        self.audioDuration = audioDuration
        self.realTimeFactor = realTimeFactor
    }
}

/// 转录结果
/// 包含完整的转录内容和元数据
struct TranscriptionResult: Sendable, Identifiable {
    let id: UUID
    let audioFile: AudioFile
    let modelName: String
    let language: String
    var sentences: [SentenceTimestamp]  // var 以支持后处理修改
    let fullText: String
    let processingTime: TimeInterval
    let metadata: TranscriptionMetadata
    
    init(
        id: UUID = UUID(),
        audioFile: AudioFile,
        modelName: String,
        language: String,
        sentences: [SentenceTimestamp],
        fullText: String? = nil,
        processingTime: TimeInterval,
        metadata: TranscriptionMetadata
    ) {
        self.id = id
        self.audioFile = audioFile
        self.modelName = modelName
        self.language = language
        self.sentences = sentences
        self.fullText = fullText ?? sentences.map { $0.text }.joined()
        self.processingTime = processingTime
        self.metadata = metadata
    }
    
    /// 总词数
    var totalWords: Int {
        sentences.reduce(0) { $0 + $1.words.count }
    }
    
    /// 平均置信度
    var averageConfidence: Double {
        let allWords = sentences.flatMap { $0.words }
        guard !allWords.isEmpty else { return 0 }
        return allWords.reduce(0.0) { $0 + $1.confidence } / Double(allWords.count)
    }
}

/// 原始转录结果（模型直接输出）
/// 用于存储模型推理的原始结果
struct RawTranscriptionResult: Sendable {
    let text: String
    let words: [WordTimestamp]
    let language: String
    let languageProbability: Double
    
    init(
        text: String,
        words: [WordTimestamp],
        language: String,
        languageProbability: Double = 1.0
    ) {
        self.text = text
        self.words = words
        self.language = language
        self.languageProbability = languageProbability
    }
}