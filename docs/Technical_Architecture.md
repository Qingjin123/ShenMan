# 声声慢 (ShenMan) - 技术架构文档

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
│  ┌───────────┐  ┌───────────┐  ┌───────────────────┐    │
│  │ 进度显示   │  │ 设置视图   │  │ 导出对话框        │    │
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
│  │  • 数据绑定                                      │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │               AppCoordinator                     │    │
│  │  • 导航流程                                      │    │
│  │  • 模块协调                                      │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Business Logic Layer                  │
│                   (Domain / Use Cases)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ 文件导入用例  │  │ 转录用例     │  │ 导出用例      │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ 时间戳聚合   │  │ 后处理用例   │  │ 模型选择用例  │   │
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
│  │  • 进度回调                                      │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │               FileRepository                     │    │
│  │  • 文件读取                                      │    │
│  │  • 文件写入                                      │    │
│  │  • 格式转换                                      │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │             SettingsRepository                   │    │
│  │  • 用户偏好                                      │    │
│  │  • 模型配置                                      │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                  │
│                  (Framework / Models)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ MLX Swift    │  │ AVFoundation │  │ Swift NIO    │   │
│  │ (模型推理)   │  │ (音频处理)   │  │ (异步 IO)    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Qwen3-ASR    │  │ Whisper      │  │ 其他模型     │   │
│  │ (主力模型)   │  │ (备选模型)   │  │ (插件化)     │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 核心模块设计

### 2.1 模型抽象层

#### 2.1.1 模型协议

```swift
/// ASR 模型协议 - 所有语音识别模型必须实现此协议
protocol ASRModel: Sendable {
    /// 模型名称（显示给用户）
    var name: String { get }
    
    /// 模型描述
    var description: String { get }
    
    /// 支持的语言列表
    var supportedLanguages: [Language] { get }
    
    /// 模型大小（GB）
    var sizeGB: Double { get }
    
    /// 是否已下载
    var isDownloaded: Bool { get }
    
    /// 下载模型
    func download() async throws
    
    /// 转录音频
    /// - Parameters:
    ///   - audio: 音频文件
    ///   - language: 语言（nil 为自动检测）
    ///   - progressHandler: 进度回调
    /// - Returns: 转录结果
    func transcribe(
        audio: AudioFile,
        language: Language?,
        progressHandler: @Sendable @escaping (Double) -> Void
    ) async throws -> TranscriptionResult
}
```

#### 2.1.2 模型实现示例

```swift
/// Qwen3-ASR 模型实现
final class Qwen3ASRModel: ASRModel {
    let name = "Qwen3-ASR-0.6B"
    let description = "阿里开源，中文优化，支持 22 种方言"
    let supportedLanguages: [Language] = [.chinese, .chineseCantonese, .english]
    let sizeGB: Double = 2.5
    
    private let modelPath: URL
    private let mlxContext: MLXContext
    
    init(modelPath: URL) {
        self.modelPath = modelPath
        self.mlxContext = MLXContext()
    }
    
    func transcribe(
        audio: AudioFile,
        language: Language?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> TranscriptionResult {
        // 使用 MLX 加载模型
        // 执行推理
        // 返回结果
    }
}
```

#### 2.1.3 模型注册表

```swift
/// 模型注册表 - 管理所有可用模型
final class ModelRegistry: Sendable {
    static let shared = ModelRegistry()
    
    /// 所有可用模型
    let availableModels: [ASRModel] = [
        Qwen3ASRModel(modelPath: ...),
        WhisperModel(modelPath: ...),
        // 未来可扩展
    ]
    
    /// 默认模型
    var defaultModel: ASRModel {
        availableModels.first { $0.name == "Qwen3-ASR-0.6B" }!
    }
    
    /// 根据名称获取模型
    func model(name: String) -> ASRModel? {
        availableModels.first { $0.name == name }
    }
}
```

---

### 2.2 音频处理模块

#### 2.2.1 音频文件封装

```swift
/// 音频文件封装
struct AudioFile: Sendable {
    let url: URL
    let filename: String
    let duration: TimeInterval
    let fileSize: Int64
    let format: AudioFormat
    
    enum AudioFormat: String, Sendable {
        case mp3, wav, m4a, flac, aac, mp4, mov, avi
    }
    
    /// 从 URL 初始化
    init(url: URL) throws {
        self.url = url
        self.filename = url.lastPathComponent
        self.duration = try AudioMetadataReader.readDuration(from: url)
        self.fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        self.format = AudioFormat(rawValue: url.pathExtension.lowercased()) ?? .wav
    }
}
```

#### 2.2.2 音频预处理

```swift
/// 音频预处理服务
actor AudioPreprocessor {
    /// 转换音频格式为模型所需格式
    func convertToModelFormat(audio: AudioFile) async throws -> AudioBuffer {
        // 使用 AVFoundation 解码
        // 重采样到 16kHz
        // 转换为单声道
        // 返回 PCM 数据
    }
    
    /// 降噪处理（可选）
    func denoise(audio: AudioBuffer) async throws -> AudioBuffer {
        // 集成 SAM-Audio 或 MossFormer2
        // 可选功能，v2.0 实现
    }
}
```

---

### 2.3 转录服务模块

#### 2.3.1 转录服务

```swift
/// 转录服务 - 核心业务逻辑
final class TranscriptionService: Sendable {
    private let modelRegistry: ModelRegistry
    private let audioPreprocessor: AudioPreprocessor
    
    /// 执行转录
    func transcribe(
        audio: AudioFile,
        model: ASRModel,
        language: Language? = nil
    ) async throws -> TranscriptionResult {
        // 1. 预处理音频
        let audioBuffer = try await audioPreprocessor.convertToModelFormat(audio: audio)
        
        // 2. 执行转录
        let result = try await model.transcribe(
            audio: audioBuffer,
            language: language,
            progressHandler: { progress in
                // 更新进度
            }
        )
        
        // 3. 后处理
        let processedResult = await postProcess(result: result)
        
        return processedResult
    }
    
    /// 后处理
    private func postProcess(result: TranscriptionResult) async -> TranscriptionResult {
        // 时间戳聚合
        // 中文纠错
        // 标点优化
    }
}
```

#### 2.3.2 时间戳聚合器

```swift
/// 时间戳聚合器 - 将词级时间戳聚合为句子级
struct TimestampAggregator {
    enum Strategy {
        case punctuation      // 按标点符号
        case pauseThreshold   // 按停顿时间
        case semantic         // 按语义（LLM 辅助）
    }
    
    /// 聚合时间戳
    func aggregate(
        words: [WordTimestamp],
        strategy: Strategy = .punctuation
    ) -> [SentenceTimestamp] {
        switch strategy {
        case .punctuation:
            return aggregateByPunctuation(words: words)
        case .pauseThreshold:
            return aggregateByPause(words: words, threshold: 0.5)
        case .semantic:
            // v2.0 实现
            return aggregateByPunctuation(words: words)
        }
    }
    
    private func aggregateByPunctuation(words: [WordTimestamp]) -> [SentenceTimestamp] {
        var sentences: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []
        
        for word in words {
            currentWords.append(word)
            
            // 检测标点符号
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
    
    private func isPunctuation(_ text: String) -> Bool {
        let punctuationSet = Set(["。", "！", "？", ".", "!", "?", "；", ";"])
        return punctuationSet.contains(text)
    }
}
```

---

### 2.4 导出模块

#### 2.4.1 导出器协议

```swift
/// 导出器协议
protocol Exporter: Sendable {
    var formatName: String { get }
    var fileExtension: String { get }
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data
}
```

#### 2.4.2 TXT 导出器

```swift
struct TXTExporter: Exporter {
    let formatName = "纯文本"
    let fileExtension = "txt"
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""
        
        for sentence in result.sentences {
            if options.includeTimestamp {
                switch options.timestampPosition {
                case .start:
                    content += "[\(formatTime(sentence.startTime)) → \(formatTime(sentence.endTime))] "
                case .end:
                    content += ""
                }
            }
            content += sentence.text
            if options.includeTimestamp && options.timestampPosition == .end {
                content += " [\(formatTime(sentence.startTime)) → \(formatTime(sentence.endTime))]"
            }
            content += "\n"
        }
        
        return content.data(using: .utf8)!
    }
}
```

#### 2.4.3 SRT 导出器

```swift
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
    
    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}
```

---

### 2.5 状态管理

#### 2.5.1 应用状态

```swift
/// 应用状态
@MainActor
final class AppState: ObservableObject {
    /// 当前视图
    @Published var currentView: AppView = .home
    
    /// 当前转录任务
    @Published var currentTask: TranscriptionTask?
    
    /// 历史记录
    @Published var history: [TranscriptionTask] = []
    
    /// 用户设置
    @Published var settings: AppSettings = AppSettings()
    
    enum AppView {
        case home
        case transcribing
        case result
        case settings
    }
}
```

#### 2.5.2 转录用 ViewModel

```swift
@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var audioFile: AudioFile?
    @Published var isTranscribing = false
    @Published var progress: Double = 0
    @Published var result: TranscriptionResult?
    @Published var errorMessage: String?
    
    private let transcriptionService: TranscriptionService
    
    func loadAudio(url: URL) {
        // 加载音频文件
    }
    
    func startTranscription() async {
        guard let audio = audioFile else { return }
        
        isTranscribing = true
        progress = 0
        
        do {
            result = try await transcriptionService.transcribe(
                audio: audio,
                model: AppSettings.shared.selectedModel
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isTranscribing = false
    }
    
    func cancelTranscription() {
        // 取消转录
    }
}
```

---

## 3. 数据流

### 3.1 转录流程

```
用户操作 → ViewModel → UseCase → Service → Model → Result

详细流程：

1. 用户拖放文件
   ↓
2. TranscriptionViewModel.loadAudio(url:)
   ↓
3. 验证文件格式，创建 AudioFile 对象
   ↓
4. 用户点击"开始转录"
   ↓
5. TranscriptionViewModel.startTranscription()
   ↓
6. TranscriptionUseCase.execute(audio:, model:)
   ↓
7. TranscriptionService.transcribe()
   ↓
8. AudioPreprocessor.convertToModelFormat()
   ↓
9. ASRModel.transcribe() (MLX 推理)
   ↓
10. TimestampAggregator.aggregate()
    ↓
11. ChinesePostProcessor.process()
    ↓
12. 返回 TranscriptionResult
    ↓
13. 更新 UI 状态
```

### 3.2 导出流程

```
用户点击导出 → 选择格式 → Exporter.export() → 保存文件

1. 用户选择导出格式（TXT/SRT/Markdown）
   ↓
2. ViewModel 选择对应 Exporter
   ↓
3. Exporter.export(result:, options:)
   ↓
4. 生成文件内容
   ↓
5. NSSavePanel 选择保存路径
   ↓
6. FileManager 写入文件
```

---

## 4. 技术栈

### 4.1 核心框架

| 组件 | 技术选型 | 说明 |
|------|---------|------|
| UI 框架 | SwiftUI | 声明式 UI |
| 状态管理 | Combine + @Observable | 响应式 |
| 音频处理 | AVFoundation | 苹果官方框架 |
| 模型推理 | MLX Swift | Apple Silicon 优化 |
| 异步编程 | async/await + Task | 现代 Swift 并发 |
| 文件处理 | Foundation | 标准库 |

### 4.2 依赖管理

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
    .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.5.0"),
    // 其他依赖
]
```

### 4.3 最低系统要求

- **macOS**: 13.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **芯片**: Apple Silicon（推荐）/ Intel（基础支持）

---

## 5. 目录结构

```
ShenMan/
├── ShenManApp.swift              # App 入口
├── Info.plist                    # App 配置
│
├── Views/                        # UI 视图
│   ├── HomeView.swift           # 主页（拖放区域）
│   ├── TranscribingView.swift   # 转录中（进度条）
│   ├── ResultView.swift         # 结果展示
│   ├── SettingsView.swift       # 设置
│   └── Components/              # 可复用组件
│       ├── DropZone.swift
│       ├── ProgressBar.swift
│       └── TimestampText.swift
│
├── ViewModels/                   # ViewModel
│   ├── TranscriptionViewModel.swift
│   ├── SettingsViewModel.swift
│   └── AppState.swift
│
├── Models/                       # 数据模型
│   ├── AudioFile.swift
│   ├── TranscriptionResult.swift
│   ├── Language.swift
│   └── AppSettings.swift
│
├── Services/                     # 服务层
│   ├── TranscriptionService.swift
│   ├── AudioPreprocessor.swift
│   └── ModelRegistry.swift
│
├── Models/ASR/                   # ASR 模型实现
│   ├── ASRModel.swift           # 协议
│   ├── Qwen3ASRModel.swift
│   ├── WhisperModel.swift
│   └── ...
│
├── Processors/                   # 处理器
│   ├── TimestampAggregator.swift
│   ├── ChinesePostProcessor.swift
│   └── ...
│
├── Exporters/                    # 导出器
│   ├── Exporter.swift           # 协议
│   ├── TXTExporter.swift
│   ├── SRTExporter.swift
│   └── MarkdownExporter.swift
│
├── Repositories/                 # 数据仓库
│   ├── FileRepository.swift
│   └── SettingsRepository.swift
│
├── Utilities/                    # 工具类
│   ├── AudioMetadataReader.swift
│   ├── TimeFormatter.swift
│   └── ...
│
└── Resources/                    # 资源文件
    ├── Assets.xcassets
    └── Localizable.strings
```

---

## 6. 性能优化策略

### 6.1 内存管理

```swift
// 使用 actor 隔离状态
actor AudioPreprocessor {
    // 避免数据竞争
}

// 使用 Task 管理生命周期
Task {
    try await service.transcribe()
}

// 大文件流式处理
for try await chunk in audioStream {
    // 处理分块
}
```

### 6.2 并发策略

```swift
// 并行处理多个文件
await withTaskGroup(of: Result.self) { group in
    for audio in audioFiles {
        group.addTask {
            await service.transcribe(audio: audio)
        }
    }
}
```

### 6.3 缓存策略

```swift
// 模型缓存
class ModelCache {
    private var cache: [String: Any] = [:]
    
    func get<T>(key: String) -> T? {
        cache[key] as? T
    }
    
    func set<T>(key: String, value: T) {
        cache[key] = value
    }
}
```

---

## 7. 测试策略

### 7.1 单元测试

```swift
final class TimestampAggregatorTests: XCTestCase {
    func testAggregateByPunctuation() {
        // 测试标点聚合
    }
    
    func testExportSRT() {
        // 测试 SRT 导出
    }
}
```

### 7.2 集成测试

```swift
final class TranscriptionIntegrationTests: XCTestCase {
    func testFullTranscriptionFlow() async throws {
        // 测试完整转录流程
    }
}
```

### 7.3 UI 测试

```swift
final class ShenManUITests: XCTestCase {
    func testDropFileAndTranscribe() {
        // 测试拖放和转录
    }
}
```

---

## 8. 安全与隐私

### 8.1 沙盒权限

```xml
<!-- Entitlements -->
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

### 8.2 隐私保护

- 无网络请求（完全离线）
- 无数据收集
- 无用户追踪
- 代码开源可审查

---

## 9. 扩展性设计

### 9.1 插件架构（v2.0）

```swift
protocol ASRPlugin {
    var pluginName: String { get }
    func createModel() -> ASRModel
}

class PluginManager {
    func loadPlugins() {
        // 扫描插件目录
        // 加载插件
    }
}
```

### 9.2 模型热更新

```swift
class ModelUpdater {
    func checkForUpdates() async -> [ModelUpdate]
    func downloadUpdate(model: ASRModel) async throws
}
```

---

**文档版本**：v1.0  
**创建日期**：2026-03-19  
**作者**：Kappa + AI Assistant
