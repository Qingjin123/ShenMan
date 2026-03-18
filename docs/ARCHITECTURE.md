# 声声慢 (ShenMan) - 架构设计文档

## 📋 文档概述

本文档详细描述声声慢应用的技术架构设计，包括系统分层、模块划分、数据流设计和关键技术决策。

**目标读者**：
- 架构师
- 核心开发者
- 技术审查者

---

## 1. 系统架构概览

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                      (SwiftUI UI)                        │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────┐    │
│  │ 文件导入   │  │ 转录控制   │  │ 结果展示与编辑     │    │
│  │ 视图      │  │ 视图      │  │ 视图              │    │
│  └───────────┘  └───────────┘  └───────────────────┘    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│                   (ViewModel / State)                    │
│  ┌─────────────────────────────────────────────────┐    │
│  │              TranscriptionViewModel              │    │
│  │  • 状态管理                                      │    │
│  │  • 用户交互处理                                  │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Business Logic Layer                  │
│                   (Domain / Use Cases)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ 转录用例     │  │ 导出用例     │  │ 后处理用例   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Access Layer                     │
│                 (Repository / Services)                  │
│  ┌─────────────────────────────────────────────────┐    │
│  │              TranscriptionService                │    │
│  │  • 模型管理                                      │    │
│  │  • 转录执行                                      │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │               FileRepository                     │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                  │
│                  (Framework / Models)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ MLX Swift    │  │ AVFoundation │  │ Qwen3-ASR    │   │
│  │ (模型推理)   │  │ (音频处理)   │  │ (语音识别)   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 1.2 架构模式

项目采用 **MVVM + Clean Architecture** 的混合架构：

- **MVVM (Model-View-ViewModel)**: UI 层架构模式
- **Clean Architecture**: 业务逻辑层架构模式

**核心原则**：
1. **关注点分离**: 每层只负责单一职责
2. **依赖倒置**: 高层模块不依赖低层模块的具体实现
3. **单向数据流**: 数据从底层流向顶层
4. **协议导向**: 使用协议定义接口，便于测试和替换

---

## 2. 核心模块设计

### 2.1 模型层 (Models)

#### 2.1.1 核心模型

```swift
/// 音频文件模型
struct AudioFile: Sendable {
    let url: URL
    let filename: String
    let duration: TimeInterval
    let fileSize: Int64
    let format: AudioFormat
}

/// 转录结果
struct TranscriptionResult: Sendable {
    let audioFile: AudioFile
    let modelName: String
    let language: String
    let sentences: [SentenceTimestamp]
    let processingTime: TimeInterval
    let metadata: TranscriptionMetadata
}

/// 句子级时间戳
struct SentenceTimestamp: Sendable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let words: [WordTimestamp]  // 可选的词级时间戳
}
```

#### 2.1.2 模型协议

```swift
/// ASR 模型协议 - 所有语音识别模型必须实现
protocol ASRModel: Sendable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var supportedLanguages: [Language] { get }
    var sizeGB: Double { get }
    var isDownloaded: Bool { get }
    
    func download(progressHandler: @escaping @Sendable (Double) -> Void) async throws
    func transcribe(
        audioFile: AudioFile,
        language: Language?,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> RawTranscriptionResult
}
```

**设计要点**：
- 使用 `Sendable` 保证并发安全
- 协议抽象便于替换不同模型实现
- 进度回调使用 `@Sendable` 闭包

### 2.2 视图层 (Views)

#### 2.2.1 视图层次

```
App
└── ContentView
    ├── HomeView (拖放文件)
    ├── TranscribingView (转录进度)
    ├── ResultView (结果展示)
    └── SettingsView (设置)
```

#### 2.2.2 视图组件化

```swift
// 可复用组件
Views/
├── Components/
│   ├── DropZoneView.swift      // 拖放区域
│   ├── AudioFileCard.swift     // 文件信息卡片
│   ├── ProgressBar.swift       // 进度条
│   ├── TimestampText.swift     // 时间戳文本
│   └── ExportButton.swift      // 导出按钮
```

**设计要点**：
- 组件高度复用
- 使用 `@EnvironmentObject` 传递共享状态
- 支持深色模式

### 2.3 视图模型层 (ViewModels)

#### 2.3.1 状态管理

```swift
@MainActor
final class AppState: ObservableObject {
    // 导航状态
    @Published var currentView: AppView = .home
    
    // 转录状态
    @Published var currentAudioFile: AudioFile?
    @Published var currentResult: TranscriptionResult?
    @Published var transcriptionProgress: Double = 0
    @Published var isTranscribing: Bool = false
    
    // Task 管理
    private var loadHistoryTask: Task<Void, Never>?
    private var currentTask: Task<Void, Never>?
    
    init() {
        loadHistoryTask = Task {
            await loadHistoryFromRepository()
        }
    }
    
    deinit {
        loadHistoryTask?.cancel()
        currentTask?.cancel()
    }
}
```

**设计要点**：
- 所有 `@Published` 属性自动在 `MainActor` 上同步
- Task 生命周期管理，避免内存泄漏
- 使用 `weak self` 避免循环引用

### 2.4 服务层 (Services)

#### 2.4.1 转录服务

```swift
final class TranscriptionService: @unchecked Sendable {
    private var currentModel: ASRModel?
    private let timestampAggregator = TimestampAggregator()
    @MainActor private var isCancelled = false
    
    func transcribe(
        audioFile: AudioFile,
        model: ASRModel,
        language: Language? = nil,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        // 1. 检查模型下载
        // 2. 执行转录
        // 3. 时间戳聚合
        // 4. 后处理
        // 5. 返回结果
    }
    
    func cancel() {
        Task { @MainActor in
            isCancelled = true
            currentModel?.cancel()
        }
    }
}
```

**为什么使用 `@unchecked Sendable`**：
- `ASRModel` 协议的实现（如 `Qwen3ASRModelWrapper`）不是 `Sendable`
- 所有公共方法都是 `async`，通过 `await` 序列化访问
- 取消标志通过 `@MainActor` 保证线程安全

#### 2.4.2 批量处理服务

```swift
actor BatchProcessingService {
    private var tasks: [BatchTask] = []
    private var isProcessing = false
    
    func addTask(_ audioFile: AudioFile) {
        tasks.append(BatchTask(audioFile: audioFile))
    }
    
    func startBatch(modelId: ModelIdentifier) async throws -> [TranscriptionResult] {
        guard !tasks.isEmpty else {
            throw BatchProcessingError.emptyBatch
        }
        
        var results: [TranscriptionResult] = []
        var failedCount = 0
        
        for task in tasks {
            do {
                let result = try await transcribe(task.audioFile)
                results.append(result)
            } catch {
                failedCount += 1
            }
        }
        
        if failedCount == tasks.count && results.isEmpty {
            throw BatchProcessingError.allTasksFailed
        }
        
        return results
    }
}
```

**使用 `actor` 的原因**：
- 自动隔离可变状态
- 无需手动管理锁
- 编译器保证并发安全

### 2.5 处理器层 (Processors)

#### 2.5.1 时间戳聚合器

```swift
struct TimestampAggregator {
    enum Strategy {
        case punctuation      // 按标点符号
        case pauseThreshold   // 按停顿时间
    }
    
    func aggregate(
        words: [WordTimestamp],
        strategy: Strategy = .punctuation
    ) -> [SentenceTimestamp] {
        switch strategy {
        case .punctuation:
            return aggregateByPunctuation(words: words)
        case .pauseThreshold:
            return aggregateByPause(words: words)
        }
    }
    
    private func aggregateByPunctuation(words: [WordTimestamp]) -> [SentenceTimestamp] {
        var sentences: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []
        
        for word in words {
            currentWords.append(word)
            
            if isPunctuation(word.word) {
                sentences.append(SentenceTimestamp(
                    text: currentWords.map { $0.word }.joined(),
                    startTime: currentWords.first!.startTime,
                    endTime: currentWords.last!.endTime,
                    words: currentWords
                ))
                currentWords = []
            }
        }
        
        return sentences
    }
}
```

#### 2.5.2 中文后处理器

```swift
struct ChinesePostProcessor {
    private static let homophoneCorrections: [String: String] = [
        "配备": "配置",
        "协义": "协议",
        // ...
    ]
    
    func correctHomophones(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        sentences.map { sentence in
            var correctedText = sentence.text
            for (wrong, correct) in Self.homophoneCorrections {
                correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
            }
            return sentence.with(text: correctedText)
        }
    }
    
    func optimizePunctuation(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        // 标点优化逻辑
    }
    
    func formatNumbers(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
        // 数字格式化逻辑
    }
}
```

### 2.6 导出层 (Exporters)

#### 2.6.1 导出器协议

```swift
protocol Exporter: Sendable {
    var formatName: String { get }
    var fileExtension: String { get }
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data
}
```

#### 2.6.2 具体实现

```swift
struct TXTExporter: Exporter {
    let formatName = "纯文本"
    let fileExtension = "txt"
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""
        
        for sentence in result.sentences {
            if options.includeTimestamp {
                content += "[\(formatTime(sentence.startTime))] "
            }
            content += "\(sentence.text)\n"
        }
        
        return content.data(using: .utf8)!
    }
}

struct SRTExporter: Exporter {
    let formatName = "字幕文件"
    let fileExtension = "srt"
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""
        
        for (index, sentence) in result.sentences.enumerated() {
            content += "\(index + 1)\n"
            content += "\(formatSRTTime(sentence.startTime)) --> \(formatSRTTime(sentence.endTime))\n"
            content += "\(sentence.text)\n\n"
        }
        
        return content.data(using: .utf8)!
    }
}
```

### 2.7 仓库层 (Repositories)

#### 2.7.1 文件仓库

```swift
final class FileRepository: @unchecked Sendable {
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func readFile(at url: URL) throws -> Data {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileError.fileNotFound
        }
        return try Data(contentsOf: url)
    }
    
    func writeFile(_ data: Data, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
```

**为什么使用 `@unchecked Sendable`**：
- `FileManager` 不是 `Sendable`
- `FileManager` 本身是线程安全的
- 方法都是简单的委托调用，没有可变状态

#### 2.7.2 历史记录仓库

```swift
actor HistoryRepository {
    private var history: [TranscriptionHistoryRecord] = []
    private let fileRepository: FileRepository
    
    func getAllHistory() async -> [TranscriptionHistoryRecord] {
        await ensureLoaded()
        return history.sorted { $0.createdAt > $1.createdAt }
    }
    
    func addHistoryRecord(_ record: TranscriptionHistoryRecord) async {
        await ensureLoaded()
        
        if let index = history.firstIndex(where: { $0.id == record.id }) {
            history[index] = record
        } else {
            history.append(record)
        }
        
        await saveHistory()
    }
    
    private func ensureLoaded() async {
        guard !isLoaded else { return }
        await loadHistory()
        isLoaded = true
    }
}
```

**使用 `actor` 的原因**：
- 保护共享的可变状态（`history` 数组）
- 延迟加载确保数据一致性
- 自动的线程安全保证

---

## 3. 数据流设计

### 3.1 转录数据流

```
┌──────────────┐
│  用户拖放文件  │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────┐
│  AppState.loadAudioFile()    │
│  • 验证文件格式               │
│  • 读取元数据                 │
│  • 创建 AudioFile             │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  用户点击"开始转录"            │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  TranscriptionViewModel.     │
│  startTranscription()        │
│  • 更新 UI 状态                │
│  • 创建 Task                  │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  TranscriptionService.       │
│  transcribe()                │
│  • 检查模型下载               │
│  • 执行转录                   │
│  • 进度回调                   │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  ASRModel.transcribe()       │
│  • 加载模型                   │
│  • 预处理音频                 │
│  • MLX 推理                   │
│  • 返回 RawTranscriptionResult│
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  TimestampAggregator.        │
│  aggregate()                 │
│  • 按标点聚合                 │
│  • 或按停顿聚合               │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  ChinesePostProcessor.       │
│  process()                   │
│  • 同音字纠错                 │
│  • 标点优化                   │
│  • 数字格式化                 │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  返回 TranscriptionResult    │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  更新 UI 状态                 │
│  • 显示结果                   │
│  • 保存到历史记录             │
└──────────────────────────────┘
```

### 3.2 导出数据流

```
┌──────────────┐
│  用户点击导出  │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────┐
│  选择导出格式                 │
│  • TXT                       │
│  • SRT                       │
│  • Markdown                  │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  选择导出选项                 │
│  • 包含时间戳                 │
│  • 时间戳位置                 │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Exporter.export()           │
│  • 生成文件内容               │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  NSSavePanel 选择保存路径     │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  FileManager 写入文件          │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  显示导出成功/失败             │
└──────────────────────────────┘
```

---

## 4. 并发设计

### 4.1 Swift 6 并发模型

项目使用 Swift 6 的严格并发检查：

```swift
// Package.swift
swiftSettings: [
    .swiftLanguageMode(.v6),
    .enableExperimentalFeature("StrictConcurrency"),
    .unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"])
]
```

### 4.2 并发策略

#### 4.2.1 使用 `actor` 隔离状态

```swift
actor BatchProcessingService {
    private var tasks: [BatchTask] = []
    
    func addTask(_ audioFile: AudioFile) {
        tasks.append(BatchTask(audioFile: audioFile))
    }
}
```

#### 4.2.2 使用 `@MainActor` 隔离 UI

```swift
@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var progress: Double = 0
    
    func updateProgress(_ progress: Double) {
        self.progress = progress  // 自动在 MainActor 上
    }
}
```

#### 4.2.3 合理使用 `@unchecked Sendable`

```swift
/// 文档说明为什么使用 @unchecked Sendable
final class TranscriptionService: @unchecked Sendable {
    @MainActor private var isCancelled = false
    
    func cancel() {
        Task { @MainActor in
            isCancelled = true
        }
    }
}
```

### 4.3 Task 管理

```swift
final class AppState: ObservableObject {
    private var loadHistoryTask: Task<Void, Never>?
    private var currentTask: Task<Void, Never>?
    
    init() {
        loadHistoryTask = Task {
            await loadHistoryFromRepository()
        }
    }
    
    deinit {
        loadHistoryTask?.cancel()
        currentTask?.cancel()
    }
    
    func startTranscription() {
        currentTask = Task { [weak self] in
            guard let strongSelf = self else { return }
            // 转录逻辑
        }
    }
    
    func cancelTranscription() {
        currentTask?.cancel()
        currentTask = nil
    }
}
```

---

## 5. 错误处理设计

### 5.1 错误类型层次

```swift
// ASR 错误
enum ASRError: LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case audioLoadFailed
    case inferenceFailed(String)
    case outOfMemory
    case cancelled
}

// 文件错误
enum FileError: LocalizedError {
    case fileNotFound
    case fileIsDirectory
    case noPermission
    case writeFailed(String)
    case readFailed(String)
}

// 批处理错误
enum BatchProcessingError: LocalizedError {
    case emptyBatch
    case allTasksFailed
    case cancelled
}

// 导出错误
enum ExportError: LocalizedError {
    case encodingFailed
    case fileWriteFailed
}
```

### 5.2 错误恢复建议

```swift
protocol ErrorRecoverySuggestion {
    var recoverySuggestion: String? { get }
    var isRecoverable: Bool { get }
    func attemptRecovery() async -> Bool
}

extension ASRError: ErrorRecoverySuggestion {
    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "请在设置中下载所需的 ASR 模型"
        case .outOfMemory:
            return "请关闭其他应用释放内存后重试"
        default:
            return nil
        }
    }
}
```

### 5.3 错误传播链

```
Model → Service → ViewModel → View

1. Model 抛出错误
   ↓
2. Service 捕获并转换错误类型
   ↓
3. ViewModel 更新错误状态
   ↓
4. View 显示错误消息和恢复建议
```

---

## 6. 性能优化设计

### 6.1 内存管理

```swift
// 1. 使用流式处理
for try await chunk in audioStream {
    process(chunk)
}

// 2. 及时释放大对象
func processLargeFile() {
    autoreleasepool {
        // 处理大文件
    }
}

// 3. 使用弱引用避免循环引用
Task { [weak self] in
    guard let self = self else { return }
    // 逻辑
}
```

### 6.2 缓存策略

```swift
// 1. 正则表达式缓存
private static let punctuationRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: "[。！？]", options: [])
}()

// 2. 模型缓存
actor ModelCache {
    private var cache: [String: Any] = [:]
    
    func get<T>(key: String) -> T? {
        cache[key] as? T
    }
    
    func set<T>(key: String, value: T) {
        cache[key] = value
    }
}
```

### 6.3 懒加载

```swift
// 1. 延迟加载历史记录
actor HistoryRepository {
    private var isLoaded = false
    
    private func ensureLoaded() async {
        guard !isLoaded else { return }
        await loadHistory()
        isLoaded = true
    }
}

// 2. 计算属性懒加载
var formattedDuration: String {
    TimeFormatter.format(duration)
}
```

---

## 7. 依赖注入设计

### 7.1 依赖注入容器

```swift
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()
    
    private var services: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    private let lock = NSLock()
    
    func register<Service>(_ protocolType: Service.Type, 
                          factory: @escaping (DependencyContainer) -> Service) {
        lock.lock()
        defer { lock.unlock() }
        services[String(describing: protocolType)] = factory
    }
    
    func resolve<Service>(_ protocolType: Service.Type) -> Service {
        let key = String(describing: protocolType)
        guard let factory = services[key] as? (DependencyContainer) -> Service else {
            fatalError("Service \(key) not registered")
        }
        return factory(self)
    }
}
```

### 7.2 使用示例

```swift
// 配置
container.register(TranscriptionServiceProtocol.self) { _ in
    TranscriptionService()
}

// 使用
let service: TranscriptionServiceProtocol = container.resolve()
```

---

## 8. 技术决策记录

### 8.1 为什么选择 Qwen3-ASR

**决策日期**: 2026-03-19

**背景**: 需要选择一个适合中文语音识别的模型

**选项对比**:

| 模型 | 中文准确率 | 处理速度 | 模型大小 | 支持方言 |
|------|----------|---------|---------|---------|
| Qwen3-ASR-0.6B | 92% | 快 | 0.6GB | 22 种 |
| Whisper-large-v3 | 88% | 中 | 3GB | 99 种 |
| Whisper-small | 85% | 快 | 242MB | 99 种 |

**决策**: 选择 Qwen3-ASR-0.6B

**理由**:
1. 中文优化更好
2. 支持中文方言
3. 模型小，速度快
4. MLX 原生支持

### 8.2 为什么使用 MVVM

**决策日期**: 2026-03-19

**背景**: 选择 UI 架构模式

**选项对比**:

| 模式 | 优点 | 缺点 |
|------|------|------|
| MVC | 简单 |  Massive View Controller |
| MVP | 测试友好 | 代码量大 |
| MVVM | SwiftUI 原生支持，数据绑定 | 学习曲线 |

**决策**: MVVM

**理由**:
1. SwiftUI 原生支持
2. `@Published` 自动更新 UI
3. 便于单元测试
4. 代码简洁

### 8.3 为什么使用 `actor`

**决策日期**: 2026-03-19

**背景**: 如何保证并发安全

**选项对比**:

| 方案 | 优点 | 缺点 |
|------|------|------|
| 锁 (NSLock) | 灵活 | 容易死锁 |
| 队列 (DispatchQueue) | 成熟 | 容易出错 |
| actor | 编译器保证安全 | 性能开销 |

**决策**: 优先使用 `actor`

**理由**:
1. 编译器自动检查
2. 无需手动管理锁
3. 代码更清晰
4. Swift 6 原生支持

---

## 9. 未来架构演进

### 9.1 v2.0 规划

- **说话人分离**: 集成 Sortformer 模型
- **词级对齐**: 集成 Qwen3-ForcedAligner
- **实时转录**: 流式处理架构

### 9.2 架构改进方向

1. **插件化架构**: 支持第三方模型插件
2. **模块化**: 将核心功能拆分为独立模块
3. **热更新**: 支持模型热更新

---

**文档版本**: v1.0  
**创建日期**: 2026-03-18  
**最后更新**: 2026-03-18  
**作者**: ShenMan Team
