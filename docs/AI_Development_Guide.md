# 声声慢 (ShenMan) - AI 开发需求文档

## 📖 文档说明

**本文档用途**：指导 AI 助手（如 Qwen Code、Cursor AI 等）理解项目需求，生成正确的代码。

**适用对象**：
- AI 编程助手
- 人类开发者
- 代码审查者

**使用方式**：
1. AI 开发前，先让 AI 阅读此文档
2. 开发过程中，AI 参考对应章节
3. 代码生成后，对照此文档审查

---

## 🎯 项目概述

### 项目名称
- **中文名**：声声慢
- **英文名**：ShenMan
- **命名来源**：李清照词牌《声声慢》

### 项目定位
一款面向中文用户的开源 macOS 语音转文字工具，基于 Qwen3-ASR 模型，提供高精度的中文语音识别、句子级时间戳和简洁的用户体验。

### 核心特性
1. **完全离线**：所有处理在本地进行，无网络请求
2. **中文优化**：针对中文场景深度优化，支持方言
3. **开源免费**：MIT 许可，代码完全开源
4. **简洁易用**：拖放文件即可转录

### 技术栈
| 层级 | 技术选型 |
|------|---------|
| 语言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 模型推理 | MLX Swift |
| 音频处理 | AVFoundation |
| 并发模型 | async/await + Actor |
| 最低系统 | macOS 13.0+ |

---

## 📁 项目结构

### 完整目录树

```
ShenMan/
├── ShenManApp.swift                  # App 入口
├── Info.plist                        # App 配置
├── ShenMan.entitlements              # 权限配置
│
├── Views/                            # UI 视图层
│   ├── HomeView.swift                # 主页（拖放区域）
│   ├── TranscribingView.swift        # 转录中（进度显示）
│   ├── ResultView.swift              # 结果展示与编辑
│   ├── SettingsView.swift            # 设置页面
│   │
│   └── Components/                   # 可复用组件
│       ├── DropZoneView.swift        # 文件拖放区域
│       ├── ProgressBar.swift         # 进度条组件
│       ├── TimestampLabel.swift      # 时间戳标签
│       ├── AudioFileCard.swift       # 音频文件卡片
│       └── ModelSelector.swift       # 模型选择器
│
├── ViewModels/                       # ViewModel 层
│   ├── TranscriptionViewModel.swift  # 转录用 ViewModel
│   ├── SettingsViewModel.swift       # 设置 ViewModel
│   └── AppState.swift                # 全局状态
│
├── Models/                           # 数据模型层
│   ├── AudioFile.swift               # 音频文件模型
│   ├── TranscriptionResult.swift     # 转录结果模型
│   ├── Language.swift                # 语言枚举
│   ├── AppSettings.swift             # 应用设置
│   └── ExportOptions.swift           # 导出选项
│
├── Services/                         # 服务层
│   ├── TranscriptionService.swift    # 转录服务
│   ├── AudioPreprocessor.swift       # 音频预处理
│   ├── ModelRegistry.swift           # 模型注册表
│   └── ModelManager.swift            # 模型管理器
│
├── Models/ASR/                       # ASR 模型实现
│   ├── ASRModel.swift                # 模型协议
│   ├── Qwen3ASRModel.swift           # Qwen3-ASR 实现
│   └── WhisperModel.swift            # Whisper 实现（v1.0）
│
├── Processors/                       # 处理器层
│   ├── TimestampAggregator.swift     # 时间戳聚合器
│   ├── ChinesePostProcessor.swift    # 中文后处理
│   └── ErrorCorrector.swift          # 纠错器
│
├── Exporters/                        # 导出器层
│   ├── Exporter.swift                # 导出器协议
│   ├── TXTExporter.swift             # TXT 导出
│   ├── SRTExporter.swift             # SRT 字幕导出
│   └── MarkdownExporter.swift        # Markdown 导出
│
├── Repositories/                     # 数据仓库层
│   ├── FileRepository.swift          # 文件仓库
│   └── SettingsRepository.swift      # 设置仓库
│
├── Utilities/                        # 工具类
│   ├── AudioMetadataReader.swift     # 音频元数据读取
│   ├── TimeFormatter.swift           # 时间格式化
│   ├── FileSizeFormatter.swift       # 文件大小格式化
│   └── Constants.swift               # 常量定义
│
└── Resources/                        # 资源文件
    ├── Assets.xcassets               # 图片资源
    ├── Icons/                        # 图标
    └── Localizable.strings           # 国际化
```

---

## 🔧 核心功能详细需求

### 功能 1：文件导入（DropZoneView）

#### 功能描述
用户通过拖放或点击选择音频/视频文件。

#### UI 要求
```swift
// 视觉设计
- 拖放区域：占据主页大部分空间
- 默认状态：显示"拖放音频文件到此处"或"点击选择文件"
- 悬停状态：边框高亮（蓝色）
- 拖入状态：背景变色（浅蓝色）
- 支持的文件格式：显示在底部

// 动画
- 悬停时轻微放大（scale 1.02）
- 拖入时弹性效果
```

#### 支持的文件格式
```swift
let supportedFormats = [
    // 音频
    "mp3", "wav", "m4a", "flac", "aac", "ogg", "wma",
    // 视频
    "mp4", "mov", "avi", "mkv", "wmv"
]
```

#### 代码要求
```swift
// DropZoneView.swift
import SwiftUI

struct DropZoneView: View {
    // 状态
    @State private var isHovering = false
    @State private var isDraggingOver = false
    
    // 回调
    var onFileSelected: (URL) -> Void
    
    // 属性
    private let supportedFormats: [String]
    
    var body: some View {
        // 实现拖放逻辑
        // 使用 .onDrop 和 .fileImporter
    }
}

// 技术要求
// 1. 使用 SwiftUI 的 .onDrop modifier
// 2. 支持 UTType 识别文件类型
// 3. 文件格式验证
// 4. 错误处理（格式不支持时提示）
```

#### 错误处理
```swift
enum FileImportError: LocalizedError {
    case unsupportedFormat
    case fileTooLarge
    case fileNotFound
    case unreadable
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .fileTooLarge:
            return "文件过大（最大支持 2GB）"
        case .fileNotFound:
            return "文件不存在"
        case .unreadable:
            return "无法读取文件"
        }
    }
}
```

---

### 功能 2：音频文件解析（AudioFile）

#### 功能描述
解析音频文件元数据（时长、格式、大小等）。

#### 数据模型
```swift
struct AudioFile: Sendable, Identifiable {
    let id: UUID
    let url: URL
    let filename: String
    let duration: TimeInterval      // 秒
    let fileSize: Int64             // 字节
    let format: AudioFormat
    let sampleRate: Int             // Hz
    let channels: Int
    
    enum AudioFormat: String, Sendable {
        case mp3, wav, m4a, flac, aac, mp4, mov, avi, unknown
        
        var displayName: String {
            rawValue.uppercased()
        }
    }
    
    // 计算属性
    var durationFormatted: String {
        // 格式化为 "HH:MM:SS" 或 "MM:SS"
    }
    
    var fileSizeFormatted: String {
        // 格式化为 "MB" 或 "GB"
    }
}
```

#### 实现要求
```swift
// AudioMetadataReader.swift
import AVFoundation

actor AudioMetadataReader {
    /// 读取音频元数据
    static func readMetadata(from url: URL) async throws -> AudioFile {
        // 1. 使用 AVAsset 加载音频
        // 2. 获取时长
        // 3. 获取采样率
        // 4. 获取声道数
        // 5. 获取文件大小
        // 6. 返回 AudioFile 对象
    }
    
    /// 验证文件格式
    static func validateFormat(url: URL) -> Bool {
        // 检查文件扩展名
        // 检查 UTType
    }
}
```

---

### 功能 3：语音转录（TranscriptionService）

#### 功能描述
使用 Qwen3-ASR 模型将音频转换为带时间戳的文本。

#### 核心流程
```
1. 加载音频文件
   ↓
2. 预处理（格式转换、重采样）
   ↓
3. 加载 MLX 模型
   ↓
4. 执行推理
   ↓
5. 获取词级时间戳
   ↓
6. 聚合为句子级时间戳
   ↓
7. 中文后处理
   ↓
8. 返回结果
```

#### 数据模型
```swift
/// 词级时间戳
struct WordTimestamp: Sendable {
    let word: String
    let startTime: TimeInterval    // 秒
    let endTime: TimeInterval      // 秒
    let confidence: Double         // 置信度 0-1
}

/// 句子级时间戳
struct SentenceTimestamp: Sendable, Identifiable {
    let id: UUID
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let words: [WordTimestamp]
    var speaker: String?           // 说话人（v2.0）
}

/// 转录结果
struct TranscriptionResult: Sendable {
    let audioFile: AudioFile
    let model: String
    let language: String
    let sentences: [SentenceTimestamp]
    let fullText: String           // 完整文本（无时间戳）
    let processingTime: TimeInterval
    let metadata: TranscriptionMetadata
}

struct TranscriptionMetadata: Sendable {
    let modelVersion: String
    let processingDate: Date
    let audioDuration: TimeInterval
    let realTimeFactor: Double     // RTF
}
```

#### 服务实现
```swift
// TranscriptionService.swift
final class TranscriptionService: Sendable {
    private let modelRegistry: ModelRegistry
    private let audioPreprocessor: AudioPreprocessor
    private let timestampAggregator: TimestampAggregator
    private let chinesePostProcessor: ChinesePostProcessor
    
    /// 执行转录
    func transcribe(
        audio: AudioFile,
        model: ASRModel,
        language: Language? = nil,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        
        let startDate = Date()
        
        // 1. 预处理音频
        progressHandler(0.05, "预处理音频...")
        let audioBuffer = try await audioPreprocessor.convertToModelFormat(audio: audio)
        
        // 2. 执行转录
        progressHandler(0.1, "加载模型...")
        let rawResult = try await model.transcribe(
            audio: audioBuffer,
            language: language,
            progressHandler: { modelProgress in
                // 映射到总体进度（10%-90%）
                let overallProgress = 0.1 + (modelProgress * 0.8)
                progressHandler(overallProgress, "转录中...")
            }
        )
        
        // 3. 时间戳聚合
        progressHandler(0.95, "处理时间戳...")
        let sentences = timestampAggregator.aggregate(
            words: rawResult.words,
            strategy: .punctuation
        )
        
        // 4. 中文后处理
        progressHandler(0.98, "后处理...")
        let processedSentences = await chinesePostProcessor.process(sentences: sentences)
        
        // 5. 构建结果
        let endDate = Date()
        let processingTime = endDate.timeIntervalSince(startDate)
        let rtf = processingTime / audio.duration
        
        return TranscriptionResult(
            audioFile: audio,
            model: model.name,
            language: rawResult.language,
            sentences: processedSentences,
            fullText: processedSentences.map { $0.text }.joined(),
            processingTime: processingTime,
            metadata: TranscriptionMetadata(
                modelVersion: model.name,
                processingDate: endDate,
                audioDuration: audio.duration,
                realTimeFactor: rtf
            )
        )
    }
}
```

---

### 功能 4：时间戳聚合（TimestampAggregator）

#### 功能描述
将词级时间戳聚合为句子级时间戳。

#### 聚合策略
```swift
enum AggregationStrategy {
    case punctuation      // 按标点符号（推荐默认）
    case pauseThreshold   // 按停顿时间
    case semantic         // 按语义（LLM 辅助，v2.0）
}
```

#### 实现细节
```swift
// TimestampAggregator.swift
struct TimestampAggregator {
    /// 聚合时间戳
    func aggregate(
        words: [WordTimestamp],
        strategy: AggregationStrategy = .punctuation
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
    
    /// 按标点符号聚合
    private func aggregateByPunctuation(words: [WordTimestamp]) -> [SentenceTimestamp] {
        var sentences: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []
        
        for word in words {
            currentWords.append(word)
            
            // 检测句子边界
            if isSentenceBoundary(word.word) {
                sentences.append(createSentence(from: currentWords))
                currentWords = []
            }
        }
        
        // 处理剩余单词（没有标点结尾）
        if !currentWords.isEmpty {
            sentences.append(createSentence(from: currentWords))
        }
        
        return sentences
    }
    
    /// 检测句子边界
    private func isSentenceBoundary(_ text: String) -> Bool {
        // 中文标点
        let chinesePunctuation = Set(["。", "！", "？", "；", "：", "……", "、"])
        // 英文标点
        let englishPunctuation = Set([".", "!", "?", ";", ":", "...", ","])
        
        let allPunctuation = chinesePunctuation.union(englishPunctuation)
        return allPunctuation.contains(text.trimmingCharacters(in: .whitespaces))
    }
    
    /// 按停顿时间聚合
    private func aggregateByPause(
        words: [WordTimestamp],
        threshold: TimeInterval
    ) -> [SentenceTimestamp] {
        var sentences: [SentenceTimestamp] = []
        var currentWords: [WordTimestamp] = []
        
        for i in 0..<words.count {
            currentWords.append(words[i])
            
            // 检测与下一个词的停顿
            if i < words.count - 1 {
                let pause = words[i + 1].startTime - words[i].endTime
                if pause > threshold {
                    sentences.append(createSentence(from: currentWords))
                    currentWords = []
                }
            }
        }
        
        if !currentWords.isEmpty {
            sentences.append(createSentence(from: currentWords))
        }
        
        return sentences
    }
    
    /// 创建句子对象
    private func createSentence(from words: [WordTimestamp]) -> SentenceTimestamp {
        SentenceTimestamp(
            id: UUID(),
            text: words.map { $0.word }.joined(),
            startTime: words.first!.startTime,
            endTime: words.last!.endTime,
            words: words
        )
    }
}
```

---

### 功能 5：中文后处理（ChinesePostProcessor）

#### 功能描述
对转录结果进行中文优化（纠错、标点、格式化）。

#### 处理内容
```swift
// ChinesePostProcessor.swift
actor ChinesePostProcessor {
    /// 处理句子列表
    func process(sentences: [SentenceTimestamp]) async -> [SentenceTimestamp] {
        var processed = sentences
        
        // 1. 同音字纠错
        processed = await correctHomophones(sentences: processed)
        
        // 2. 标点优化
        processed = optimizePunctuation(sentences: processed)
        
        // 3. 数字格式化
        processed = formatNumbers(sentences: processed)
        
        // 4. 去除冗余空格
        processed = removeExtraSpaces(sentences: processed)
        
        return processed
    }
    
    /// 同音字纠错
    private func correctHomophones(
        sentences: [SentenceTimestamp]
    ) async -> [SentenceTimestamp] {
        // 常见错误映射
        let corrections: [String: String] = [
            "配备": "配置",
            "协义": "协议",
            "登路": "登录",
            "帐护": "账户",
            "由箱": "邮箱",
            "微姓": "微信",
            "支负": "支付",
            "宝付": "支付宝",
            // 可扩展
        ]
        
        // 实现纠错逻辑
        // 注意：保持时间戳不变
    }
    
    /// 标点优化
    private func optimizePunctuation(
        sentences: [SentenceTimestamp]
    ) -> [SentenceTimestamp] {
        // 补充缺失的标点
        // 修正错误的标点
        // 统一中英文标点
    }
    
    /// 数字格式化
    private func formatNumbers(
        sentences: [SentenceTimestamp]
    ) -> [SentenceTimestamp] {
        // "三百五十万" → "350 万"
        // "二零二五年" → "2025 年"
        // "百分之九十五" → "95%"
    }
    
    /// 去除冗余空格
    private func removeExtraSpaces(
        sentences: [SentenceTimestamp]
    ) -> [SentenceTimestamp] {
        // 中文之间不应有空格
        // 中英文之间保留一个空格
    }
}
```

---

### 功能 6：导出功能（Exporters）

#### 功能描述
将转录结果导出为不同格式。

#### 导出器协议
```swift
// Exporter.swift
protocol Exporter: Sendable {
    var formatName: String { get }
    var fileExtension: String { get }
    var mimeType: String { get }
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data
}
```

#### 导出选项
```swift
// ExportOptions.swift
struct ExportOptions: Sendable {
    var includeTimestamp: Bool = true
    var timestampPosition: TimestampPosition = .start
    var timestampFormat: TimestampFormat = .milliseconds
    var encoding: String.Encoding = .utf8
    
    enum TimestampPosition {
        case start
        case end
        case inline
    }
    
    enum TimestampFormat {
        case seconds          // 00:01:23
        case milliseconds     // 00:01:23.450
    }
}
```

#### TXT 导出器
```swift
// TXTExporter.swift
struct TXTExporter: Exporter {
    let formatName = "纯文本"
    let fileExtension = "txt"
    let mimeType = "text/plain"
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""
        
        for sentence in result.sentences {
            if options.includeTimestamp {
                switch options.timestampPosition {
                case .start:
                    content += "[\(formatTime(sentence.startTime, format: options.timestampFormat)) → "
                    content += "\(formatTime(sentence.endTime, format: options.timestampFormat))] "
                case .end:
                    break
                case .inline:
                    break
                }
            }
            
            content += sentence.text
            
            if options.includeTimestamp && options.timestampPosition == .end {
                content += " [\(formatTime(sentence.startTime, format: options.timestampFormat)) → "
                content += "\(formatTime(sentence.endTime, format: options.timestampFormat))]"
            }
            
            content += "\n"
        }
        
        // 添加元数据（可选）
        if options.includeMetadata {
            content += "\n---\n"
            content += "模型：\(result.model)\n"
            content += "处理时间：\(String(format: "%.2f", result.processingTime))秒\n"
            content += "实时因子：\(String(format: "%.2f", result.metadata.realTimeFactor))x\n"
        }
        
        return content.data(using: options.encoding)!
    }
}
```

#### SRT 导出器
```swift
// SRTExporter.swift
struct SRTExporter: Exporter {
    let formatName = "字幕文件"
    let fileExtension = "srt"
    let mimeType = "application/x-subrip"
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""
        
        for (index, sentence) in result.sentences.enumerated() {
            // 序号
            content += "\(index + 1)\n"
            
            // 时间轴（SRT 格式：HH:MM:SS,mmm）
            content += "\(formatSRTTime(sentence.startTime)) --> \(formatSRTTime(sentence.endTime))\n"
            
            // 字幕文本
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

#### Markdown 导出器
```swift
// MarkdownExporter.swift
struct MarkdownExporter: Exporter {
    let formatName = "Markdown"
    let fileExtension = "md"
    let mimeType = "text/markdown"
    
    func export(result: TranscriptionResult, options: ExportOptions) throws -> Data {
        var content = ""
        
        // 标题
        content += "# \(result.audioFile.filename)\n\n"
        
        // 元数据
        content += "## 元数据\n\n"
        content += "- 模型：\(result.model)\n"
        content += "- 语言：\(result.language)\n"
        content += "- 音频时长：\(formatTime(result.audioFile.duration))\n"
        content += "- 处理时间：\(String(format: "%.2f", result.processingTime))秒\n"
        content += "- 实时因子：\(String(format: "%.2f", result.metadata.realTimeFactor))x\n\n"
        
        // 转录内容
        content += "## 转录内容\n\n"
        
        for sentence in result.sentences {
            if options.includeTimestamp {
                content += "- **[\(formatTime(sentence.startTime))]** \(sentence.text)\n"
            } else {
                content += "- \(sentence.text)\n"
            }
        }
        
        return content.data(using: .utf8)!
    }
}
```

---

### 功能 7：设置管理（AppSettings）

#### 功能描述
管理用户偏好设置。

#### 设置模型
```swift
// AppSettings.swift
import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()
    
    // 模型设置
    var selectedModel: String = "Qwen3-ASR-0.6B"
    var autoDownloadModels: Bool = true
    
    // 语言设置
    var defaultLanguage: Language = .auto
    var enableLanguageDetection: Bool = true
    
    // 转录设置
    var includeTimestamp: Bool = true
    var timestampPosition: TimestampPosition = .start
    var aggregationStrategy: AggregationStrategy = .punctuation
    
    // 导出设置
    var defaultExportFormat: String = "txt"
    var lastExportPath: URL?
    
    // 后处理设置
    var enableChineseCorrection: Bool = true
    var enablePunctuationOptimization: Bool = true
    var enableNumberFormatting: Bool = true
    
    // 高级设置
    var enableLogging: Bool = false
    var maxConcurrentTasks: Int = 1
    
    enum Language: String, CaseIterable, Identifiable {
        case auto = "auto"
        case chinese = "zh"
        case chineseCantonese = "zh-yue"
        case english = "en"
        
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .auto: return "自动检测"
            case .chinese: return "中文普通话"
            case .chineseCantonese: return "粤语"
            case .english: return "英语"
            }
        }
    }
    
    enum TimestampPosition {
        case start
        case end
    }
}
```

#### 持久化
```swift
// SettingsRepository.swift
import Foundation

final class SettingsRepository: Sendable {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveSettings(_ settings: AppSettings) throws {
        // 序列化并保存
    }
    
    func loadSettings() throws -> AppSettings {
        // 加载并反序列化
    }
    
    func resetToDefaults() {
        // 重置为默认值
    }
}
```

---

## 🎨 UI/UX 规范

### 设计规范

#### 配色方案
```swift
// Colors.swift
import SwiftUI

extension Color {
    // 主色调
    static let shenManPrimary = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let shenManSecondary = Color(red: 0.6, green: 0.7, blue: 0.9)
    
    // 状态色
    static let shenManSuccess = Color.green
    static let shenManWarning = Color.orange
    static let shenManError = Color.red
    
    // 背景色
    static let shenManBackground = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let shenManCardBackground = Color.white
    
    // 文字色
    static let shenManPrimaryText = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let shenManSecondaryText = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let shenManTimestampText = Color.blue.opacity(0.8)
}
```

#### 字体规范
```swift
// Fonts.swift
import SwiftUI

extension Font {
    // 标题
    static let shenManTitle = Font.system(size: 28, weight: .bold)
    static let shenManSubtitle = Font.system(size: 22, weight: .semibold)
    
    // 正文
    static let shenManBody = Font.system(size: 16, weight: .regular)
    static let shenManCaption = Font.system(size: 14, weight: .regular)
    
    // 时间戳
    static let shenManTimestamp = Font.monospacedDigitSystem(size: 12, weight: .medium)
}
```

#### 间距规范
```swift
// Spacing.swift
import SwiftUI

extension CGFloat {
    static let shenManSpacingXS: CGFloat = 4
    static let shenManSpacingS: CGFloat = 8
    static let shenManSpacingM: CGFloat = 16
    static let shenManSpacingL: CGFloat = 24
    static let shenManSpacingXL: CGFloat = 32
}
```

---

### 页面设计规范

#### HomeView（主页）
```swift
// HomeView.swift
import SwiftUI

struct HomeView: View {
    @State private var isDraggingOver = false
    
    var body: some View {
        VStack(spacing: .shenManSpacingL) {
            // 标题
            Text("声声慢")
                .font(.shenManTitle)
                .foregroundColor(.shenManPrimaryText)
            
            Text("拖放音频文件，立即转录")
                .font(.shenManSubtitle)
                .foregroundColor(.shenManSecondaryText)
            
            Spacer()
            
            // 拖放区域
            DropZoneView { url in
                // 处理文件
            }
            .frame(minHeight: 400)
            
            Spacer()
            
            // 支持格式提示
            HStack {
                Text("支持格式：")
                    .font(.shenManCaption)
                    .foregroundColor(.shenManSecondaryText)
                
                ForEach(["MP3", "WAV", "M4A", "MP4", "MOV"], id: \.self) { format in
                    Text(format)
                        .font(.shenManCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.shenManSecondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.shenManSpacingL)
        .frame(minWidth: 800, minHeight: 600)
    }
}
```

#### TranscribingView（转录中）
```swift
// TranscribingView.swift
import SwiftUI

struct TranscribingView: View {
    let audioFile: AudioFile
    let progress: Double
    let statusMessage: String
    let estimatedTimeRemaining: TimeInterval
    
    var body: some View {
        VStack(spacing: .shenManSpacingL) {
            // 文件信息
            AudioFileCard(audioFile: audioFile)
            
            Spacer()
            
            // 进度条
            VStack(spacing: .shenManSpacingM) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 1.5)
                
                Text("\(Int(progress * 100))%")
                    .font(.shenManSubtitle)
                
                Text(statusMessage)
                    .font(.shenManCaption)
                    .foregroundColor(.shenManSecondaryText)
                
                Text("预计剩余：\(formatTime(estimatedTimeRemaining))")
                    .font(.shenManCaption)
                    .foregroundColor(.shenManSecondaryText)
            }
            
            Spacer()
            
            // 取消按钮
            Button("取消") {
                // 取消转录
            }
            .buttonStyle(.bordered)
        }
        .padding(.shenManSpacingL)
    }
}
```

#### ResultView（结果页）
```swift
// ResultView.swift
import SwiftUI

struct ResultView: View {
    let result: TranscriptionResult
    @State private var editedText: String
    @State private var showExportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("转录完成")
                    .font(.shenManTitle)
                
                Spacer()
                
                Button("导出") {
                    showExportSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.shenManSpacingM)
            
            Divider()
            
            // 文本展示
            ScrollView {
                VStack(alignment: .leading, spacing: .shenManSpacingM) {
                    ForEach(result.sentences) { sentence in
                        HStack(alignment: .top, spacing: .shenManSpacingM) {
                            // 时间戳
                            Text(formatTime(sentence.startTime))
                                .font(.shenManTimestamp)
                                .foregroundColor(.shenManTimestampText)
                                .frame(width: 100, alignment: .trailing)
                            
                            // 文本
                            Text(sentence.text)
                                .font(.shenManBody)
                                .foregroundColor(.shenManPrimaryText)
                        }
                    }
                }
                .padding(.shenManSpacingM)
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(result: result)
        }
    }
}
```

---

## ⚠️ 开发注意事项

### 并发安全
```swift
// ✅ 正确：使用 actor 隔离可变状态
actor AudioPreprocessor {
    private var cache: [String: Data] = [:]
    
    func process(audio: AudioFile) async throws -> Data {
        // 安全访问 cache
    }
}

// ✅ 正确：使用 @Sendable 闭包
func transcribe(
    progressHandler: @Sendable @escaping (Double) -> Void
) async throws {
    // 安全调用 progressHandler
}

// ❌ 错误：共享可变状态
class BadExample {
    var progress: Double = 0  // 数据竞争风险
    
    func updateProgress() {
        progress += 0.1  // 不安全
    }
}
```

### 错误处理
```swift
// 定义明确的错误类型
enum TranscriptionError: LocalizedError {
    case modelNotFound
    case audioLoadFailed
    case inferenceFailed
    case outOfMemory
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "模型未找到，请先下载模型"
        case .audioLoadFailed:
            return "无法加载音频文件"
        case .inferenceFailed:
            return "转录失败，请重试"
        case .outOfMemory:
            return "内存不足，请关闭其他应用"
        }
    }
}

// 使用 Result 类型
func transcribe() async -> Result<TranscriptionResult, TranscriptionError> {
    // 实现
}
```

### 内存管理
```swift
// 大对象使用 weak/unowned
class ViewModel {
    weak var delegate: Delegate?
    
    // 避免循环引用
    var callback: (() -> Void)? {
        didSet {
            // 注意内存
        }
    }
}

// 及时释放大对象
func processLargeData() {
    let data = loadData()
    // 使用 data
    
    // 显式释放
    // data = nil  // Swift 5.9+ 通常不需要
}
```

### 性能优化
```swift
// 使用 Task 管理生命周期
Task {
    try await service.transcribe()
}

// 取消任务
var currentTask: Task<Void, Never>?

func startTranscription() {
    currentTask?.cancel()
    currentTask = Task {
        await transcribe()
    }
}

// 使用 async/await 而非回调
func transcribe() async throws -> Result {
    // 清晰的异步流程
}
```

---

## 🧪 测试要求

### 单元测试
```swift
import XCTest

final class TimestampAggregatorTests: XCTestCase {
    func testAggregateByPunctuation() {
        let words = [
            WordTimestamp(word: "今天", startTime: 0, endTime: 0.5),
            WordTimestamp(word: "天气", startTime: 0.5, endTime: 1.0),
            WordTimestamp(word: "不错", startTime: 1.0, endTime: 1.5),
            WordTimestamp(word: "。", startTime: 1.5, endTime: 1.6)
        ]
        
        let aggregator = TimestampAggregator()
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0].text, "今天天气不错。")
    }
    
    func testExportSRT() {
        // 测试 SRT 导出格式
    }
}
```

### UI 测试
```swift
import XCTest

final class ShenManUITests: XCTestCase {
    func testDropFileAndTranscribe() {
        let app = XCUIApplication()
        app.launch()
        
        // 模拟拖放
        // 验证进度显示
        // 验证结果展示
    }
}
```

---

## 📝 代码风格规范

### 命名规范
```swift
// 类型：PascalCase
class TranscriptionService { }
protocol ASRModel { }
enum AudioFormat { }

// 变量/函数：camelCase
let audioFile: AudioFile
func transcribeAudio() async throws { }

// 常量：camelCase（Swift 惯例）
let maxFileSize = 2 * 1024 * 1024 * 1024

// 枚举值：camelCase
enum Language {
    case chinese
    case english
}
```

### 注释规范
```swift
/// 文档注释（三斜杠）
/// 转录音频文件
/// - Parameters:
///   - audio: 音频文件
///   - language: 语言
/// - Returns: 转录结果
func transcribe(audio: AudioFile) async throws -> TranscriptionResult

// 行内注释（双斜杠）
// 检查文件格式
if !isValidFormat {
    throw Error.invalidFormat
}
```

### 文件组织
```swift
// 1. Import
import SwiftUI
import AVFoundation

// 2. 类型定义
struct MyView: View {
    // 3. 属性
    @State private var text: String = ""
    
    // 4. 计算属性
    var formattedText: String { }
    
    // 5. 初始化
    init() { }
    
    // 6. body
    var body: some View { }
    
    // 7. 方法
    func doSomething() { }
}
```

---

## 🚀 开发检查清单

### 代码提交前检查
- [ ] 代码通过编译
- [ ] 单元测试通过
- [ ] 无 SwiftLint 警告
- [ ] 内存泄漏检查（Instruments）
- [ ] UI 响应流畅（无卡顿）
- [ ] 错误处理完善
- [ ] 注释清晰

### 功能完成检查
- [ ] 文件导入正常
- [ ] 转录功能正常
- [ ] 时间戳准确
- [ ] 导出功能正常
- [ ] 设置保存正常
- [ ] 中文优化生效
- [ ] 性能达标（RTF < 0.2）

---

**文档版本**：v1.0  
**创建日期**：2026-03-19  
**适用 AI**：Qwen Code、Cursor AI、GitHub Copilot 等
