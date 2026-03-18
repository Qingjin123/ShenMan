import Foundation

/// 历史记录仓库
/// 负责转录历史记录的持久化存储
///
/// ## v1.0 功能
/// - 保存转录历史记录
/// - 从存储加载历史记录
/// - 删除历史记录
/// - 支持收藏和标签
///
/// ## 存储位置
/// 历史记录存储在 Application Support 目录下的 JSON 文件中
actor HistoryRepository {

    // MARK: - 属性

    /// 单例实例
    static let shared = HistoryRepository()

    /// 文件仓库
    private let fileRepository: FileRepository

    /// 历史记录存储目录
    private let historyDirectory: URL

    /// 历史记录文件 URL
    private let historyFileURL: URL

    /// 内存中的历史记录缓存
    private var history: [TranscriptionHistoryRecord] = []

    /// 最大历史记录数量
    private let maxHistoryCount = 100

    // MARK: - 初始化

    /// 是否已加载
    private var isLoaded = false

    init(fileRepository: FileRepository = FileRepository()) {
        self.fileRepository = fileRepository

        // 获取 Application Support 目录
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ShenMan", isDirectory: true)

        // 创建目录（如果不存在）
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.historyDirectory = appFolder
        self.historyFileURL = appFolder.appendingPathComponent("history.json")

        // 延迟加载，在首次使用时加载
    }

    /// 确保历史记录已加载
    private func ensureLoaded() async {
        guard !isLoaded else { return }
        await loadHistory()
        isLoaded = true
    }

    // MARK: - 公开方法

    /// 获取所有历史记录
    /// - Returns: 历史记录列表
    func getAllHistory() async -> [TranscriptionHistoryRecord] {
        await ensureLoaded()
        return history.sorted { $0.createdAt > $1.createdAt }
    }

    /// 获取最近的转录记录
    /// - Parameter limit: 最大数量
    /// - Returns: 最近的转录记录列表
    func getRecentHistory(limit: Int = 20) async -> [TranscriptionHistoryRecord] {
        await getAllHistory().prefix(limit).map { $0 }
    }

    /// 获取收藏的记录
    /// - Returns: 收藏的记录列表
    func getFavorites() async -> [TranscriptionHistoryRecord] {
        await ensureLoaded()
        return history.filter { $0.isFavorite }.sorted { $0.createdAt > $1.createdAt }
    }

    /// 根据 ID 获取历史记录
    /// - Parameter id: 记录 ID
    /// - Returns: 历史记录（如果存在）
    func getHistoryRecord(id: UUID) async -> TranscriptionHistoryRecord? {
        await ensureLoaded()
        return history.first { $0.id == id }
    }

    /// 添加历史记录
    /// - Parameter record: 历史记录
    func addHistoryRecord(_ record: TranscriptionHistoryRecord) async {
        await ensureLoaded()

        // 检查是否已存在
        if let index = history.firstIndex(where: { $0.id == record.id }) {
            history[index] = record
        } else {
            history.append(record)

            // 保存转录详情到单独文件
            await saveTranscriptRecord(id: record.id, transcript: record.transcript)

            // 限制历史记录数量
            if history.count > maxHistoryCount {
                // 移除最旧的记录（非收藏）
                if let oldestIndex = history.lastIndex(where: { !$0.isFavorite }) {
                    history.remove(at: oldestIndex)
                }
            }
        }

        // 保存到文件
        await saveHistory()
    }

    /// 从转录结果创建并添加历史记录
    /// - Parameters:
    ///   - result: 转录结果
    ///   - transcript: 转录文本
    /// - Returns: 创建的历史记录
    @discardableResult
    func addHistoryRecord(from result: TranscriptionResult, transcript: String) async -> TranscriptionHistoryRecord {
        let record = TranscriptionHistoryRecord.from(result: result, transcript: transcript)
        await addHistoryRecord(record)
        return record
    }

    /// 更新历史记录
    /// - Parameter record: 历史记录
    func updateHistoryRecord(_ record: TranscriptionHistoryRecord) async {
        await ensureLoaded()
        
        if let index = history.firstIndex(where: { $0.id == record.id }) {
            history[index] = record
            await saveHistory()
        }
    }

    /// 删除历史记录
    /// - Parameter id: 记录 ID
    func deleteHistoryRecord(id: UUID) async {
        await ensureLoaded()
        history.removeAll { $0.id == id }
        await saveHistory()

        // 删除关联的转录结果文件
        let recordFile = historyDirectory.appendingPathComponent("\(id).json")
        try? FileManager.default.removeItem(at: recordFile)
    }

    /// 删除所有历史记录
    func deleteAllHistory() async {
        await ensureLoaded()
        history.removeAll()
        await saveHistory()

        // 删除所有关联文件
        let files = try? FileManager.default.contentsOfDirectory(
            at: historyDirectory,
            includingPropertiesForKeys: nil
        )
        files?.forEach { file in
            if file.pathExtension == "json" && file.deletingPathExtension().lastPathComponent != "history" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// 切换收藏状态
    /// - Parameter id: 记录 ID
    func toggleFavorite(id: UUID) async {
        await ensureLoaded()
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].isFavorite.toggle()
            await saveHistory()
        }
    }

    /// 添加标签
    /// - Parameters:
    ///   - id: 记录 ID
    ///   - tag: 标签
    func addTag(id: UUID, tag: String) async {
        await ensureLoaded()
        if let index = history.firstIndex(where: { $0.id == id }) {
            if !history[index].tags.contains(tag) {
                history[index].tags.append(tag)
                await saveHistory()
            }
        }
    }

    /// 移除标签
    /// - Parameters:
    ///   - id: 记录 ID
    ///   - tag: 标签
    func removeTag(id: UUID, tag: String) async {
        await ensureLoaded()
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].tags.removeAll { $0 == tag }
            await saveHistory()
        }
    }

    /// 搜索历史记录
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的记录列表
    func searchHistory(query: String) async -> [TranscriptionHistoryRecord] {
        await ensureLoaded()
        guard !query.isEmpty else { return history.sorted { $0.createdAt > $1.createdAt } }

        let lowercasedQuery = query.lowercased()
        return history.filter { record in
            // 搜索文件名
            if record.filename.lowercased().contains(lowercasedQuery) {
                return true
            }
            // 搜索转录文本
            if record.transcript.lowercased().contains(lowercasedQuery) {
                return true
            }
            // 搜索标签
            if record.tags.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                return true
            }
            return false
        }.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - 私有方法

    /// 加载历史记录
    private func loadHistory() async {
        guard fileRepository.fileExists(at: historyFileURL) else {
            history = []
            return
        }

        do {
            let data = try fileRepository.readFile(at: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            history = try decoder.decode([TranscriptionHistoryRecord].self, from: data)
        } catch {
            print("加载历史记录失败：\(error)")
            history = []
        }
    }

    /// 保存历史记录
    private func saveHistory() async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(history)
            try fileRepository.writeFile(data, to: historyFileURL)
        } catch {
            print("保存历史记录失败：\(error)")
        }
    }

    /// 保存转录记录详情
    private func saveTranscriptRecord(id: UUID, transcript: String) async {
        let recordFile = historyDirectory.appendingPathComponent("\(id).json")

        do {
            let data = transcript.data(using: .utf8)!
            try fileRepository.writeFile(data, to: recordFile)
        } catch {
            print("保存转录详情失败：\(error)")
        }
    }

    /// 加载转录记录详情
    private func loadTranscriptRecord(id: UUID) -> String? {
        let recordFile = historyDirectory.appendingPathComponent("\(id).json")

        guard fileRepository.fileExists(at: recordFile) else {
            return nil
        }

        do {
            let data = try fileRepository.readFile(at: recordFile)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// MARK: - 转录历史记录

/// 转录历史记录（可序列化）
struct TranscriptionHistoryRecord: Codable, Identifiable, Sendable {
    let id: UUID
    let filename: String
    let fileURL: String  // 存储路径字符串
    let duration: Double
    let fileSize: Int64
    let format: String
    let createdAt: Date
    let modelId: String
    let language: String
    var transcript: String  // 简化存储，实际可以存储在单独文件
    var isFavorite: Bool
    var tags: [String]
    let exportedFormats: [String]
    let processingTime: Double
    let realTimeFactor: Double

    init(
        id: UUID = UUID(),
        filename: String,
        fileURL: URL,
        duration: Double,
        fileSize: Int64,
        format: String,
        createdAt: Date = Date(),
        modelId: String,
        language: String,
        transcript: String,
        isFavorite: Bool = false,
        tags: [String] = [],
        exportedFormats: [String] = [],
        processingTime: Double,
        realTimeFactor: Double
    ) {
        self.id = id
        self.filename = filename
        self.fileURL = fileURL.path
        self.duration = duration
        self.fileSize = fileSize
        self.format = format
        self.createdAt = createdAt
        self.modelId = modelId
        self.language = language
        self.transcript = transcript
        self.isFavorite = isFavorite
        self.tags = tags
        self.exportedFormats = exportedFormats
        self.processingTime = processingTime
        self.realTimeFactor = realTimeFactor
    }

    /// 从 TranscriptionResult 创建
    static func from(result: TranscriptionResult, transcript: String) -> TranscriptionHistoryRecord {
        TranscriptionHistoryRecord(
            filename: result.audioFile.filename,
            fileURL: result.audioFile.url,
            duration: result.audioFile.duration,
            fileSize: result.audioFile.fileSize,
            format: result.audioFile.format.rawValue,
            modelId: result.metadata.modelVersion,
            language: result.language,
            transcript: transcript,
            processingTime: result.processingTime,
            realTimeFactor: result.metadata.realTimeFactor
        )
    }

    /// 转换为 AudioFile
    var audioFile: AudioFile? {
        guard let format = AudioFile.AudioFormat(rawValue: format) else { return nil }

        return AudioFile(
            url: URL(fileURLWithPath: fileURL),
            filename: filename,
            duration: duration,
            fileSize: fileSize,
            format: format,
            sampleRate: 16000,  // 默认值
            channels: 1  // 默认值
        )
    }
    
    /// 格式化的时长文本
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
