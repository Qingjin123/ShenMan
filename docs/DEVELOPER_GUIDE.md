# 声声慢 (ShenMan) - 开发者指南

## 📖 文档说明

本文档面向开发者，提供项目开发、构建、测试和维护的详细指导。

**目标读者**：
- 项目维护者
- 贡献者
- 想要了解项目实现的开发者

---

## 📁 项目结构

```
ShenMan/
├── docs/                           # 项目文档
│   ├── DEVELOPER_GUIDE.md         # 本文档
│   ├── ARCHITECTURE.md            # 架构设计
│   ├── CODING_STANDARDS.md        # 编码规范
│   └── TROUBLESHOOTING.md         # 故障排除
│
├── ShenMan/                        # 源代码
│   ├── Models/                    # 数据模型
│   │   ├── ASR/                   # ASR 模型实现
│   │   ├── AudioFile.swift        # 音频文件模型
│   │   ├── TranscriptionResult.swift # 转录结果
│   │   ├── Language.swift         # 语言定义
│   │   └── AppSettings.swift      # 应用设置
│   │
│   ├── Views/                     # SwiftUI 视图
│   │   ├── Components/            # 可复用组件
│   │   ├── HomeView.swift         # 主页
│   │   ├── TranscribingView.swift # 转录中
│   │   ├── ResultView.swift       # 结果展示
│   │   └── SettingsView.swift     # 设置
│   │
│   ├── ViewModels/                # 视图模型
│   │   ├── AppState.swift         # 应用状态
│   │   ├── BatchProcessingViewModel.swift
│   │   └── ModelManagerViewModel.swift
│   │
│   ├── Services/                  # 业务服务
│   │   ├── TranscriptionService.swift # 转录服务
│   │   ├── BatchProcessingService.swift # 批量处理
│   │   ├── BatchExportService.swift # 批量导出
│   │   ├── ModelManager.swift     # 模型管理
│   │   └── ModelRegistry.swift    # 模型注册表
│   │
│   ├── Processors/                # 数据处理器
│   │   ├── TimestampAggregator.swift # 时间戳聚合
│   │   └── ChinesePostProcessor.swift # 中文后处理
│   │
│   ├── Exporters/                 # 导出器
│   │   ├── Exporter.swift         # 导出协议
│   │   ├── TXTExporter.swift      # TXT 导出
│   │   ├── SRTExporter.swift      # SRT 导出
│   │   └── MarkdownExporter.swift # Markdown 导出
│   │
│   ├── Repositories/              # 数据仓库
│   │   ├── FileRepository.swift   # 文件仓库
│   │   └── HistoryRepository.swift # 历史记录
│   │
│   ├── Utilities/                 # 工具类
│   │   ├── Constants.swift        # 常量定义
│   │   ├── AudioMetadataReader.swift # 元数据读取
│   │   ├── TimeFormatter.swift    # 时间格式化
│   │   ├── ErrorRecovery.swift    # 错误恢复
│   │   └── DependencyContainer.swift # 依赖注入
│   │
│   ├── Resources/                 # 资源文件
│   ├── Info.plist                 # 应用配置
│   └── ShenManApp.swift           # App 入口
│
├── ShenManTests/                   # 测试代码
│   ├── Models/
│   ├── Services/
│   ├── Processors/
│   ├── Exporters/
│   └── Integration/
│
├── Package.swift                   # SPM 配置
├── project.yml                     # XcodeGen 配置
└── README.md                       # 项目说明
```

---

## 🛠️ 开发环境配置

### 系统要求

- **操作系统**: macOS 14.0+
- **Xcode**: 15.0+
- **Swift**: 6.0+
- **芯片**: Apple Silicon (M1/M2/M3) 推荐

### 依赖安装

```bash
# 克隆项目
git clone https://github.com/your-username/shenman.git
cd shenman

# 解析依赖
swift package resolve

# 生成 Xcode 项目（如使用 XcodeGen）
xcodegen generate

# 打开项目
open ShenMan.xcodeproj
```

### 依赖项

项目使用 Swift Package Manager 管理依赖：

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift.git", branch: "main"),
    .package(url: "https://github.com/Blaizzy/mlx-audio-swift.git", branch: "main")
]
```

**核心依赖**：
- **MLX Swift**: Apple Silicon 机器学习框架
- **MLX-Audio-Swift**: 音频模型 Swift 绑定
- **Qwen3-ASR**: 语音识别模型（通过 MLX-Audio-Swift）

---

## 🏗️ 架构设计

### 分层架构

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│      (SwiftUI Views + VM)           │
├─────────────────────────────────────┤
│         Business Logic Layer        │
│         (Services + UseCases)       │
├─────────────────────────────────────┤
│          Data Access Layer          │
│       (Repositories + Models)       │
├─────────────────────────────────────┤
│        Infrastructure Layer         │
│      (Frameworks + Models)          │
└─────────────────────────────────────┘
```

### 核心流程

#### 转录流程

```
用户操作 → ViewModel → Service → Model → Result

1. 用户拖放文件
   ↓
2. AppState.loadAudioFile(url:)
   ↓
3. 创建 AudioFile 对象
   ↓
4. 用户点击"开始转录"
   ↓
5. TranscriptionViewModel.startTranscription()
   ↓
6. TranscriptionService.transcribe()
   ↓
7. AudioPreprocessor.convertToModelFormat()
   ↓
8. ASRModel.transcribe() (MLX 推理)
   ↓
9. TimestampAggregator.aggregate()
   ↓
10. ChinesePostProcessor.process()
    ↓
11. 返回 TranscriptionResult
    ↓
12. 更新 UI 状态
```

#### 导出流程

```
用户点击导出 → 选择格式 → Exporter.export() → 保存文件

1. 用户选择导出格式
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

## 📝 编码规范

### Swift 语言版本

- **Swift 6.0**
- **语言模式**: Swift 6
- **并发检查**: StrictConcurrency=complete

### 命名约定

```swift
// 类型命名
final class TranscriptionService { }  // 类：PascalCase
struct AudioFile { }                   // 结构体：PascalCase
protocol ASRModel { }                  // 协议：PascalCase
enum Language { }                      // 枚举：PascalCase

// 成员命名
let fileName: String                   // 属性：camelCase
func transcribe() async { }            // 方法：camelCase

// 枚举值
case chineseCantonese                  // 枚举值：camelCase

// 常量
static let defaultSampleRate = 16000   // 常量：camelCase
```

### 注释规范

```swift
/// 转录服务
/// 核心业务逻辑，协调模型、处理器完成转录任务
///
/// ## Swift 6 并发安全说明
///
/// 本类型使用 `@unchecked Sendable` 因为：
/// 1. **协议约束限制**: 需要持有 `ASRModel` 协议实例
/// 2. **实际安全性保证**:
///    - 所有公共方法都是 `async` 的
///    - 调用方通过 `await` 序列化访问
///
/// ## 使用注意
/// - 所有公共方法都是 `async` 的，请在正确的并发上下文中调用
/// - 使用 `cancel()` 方法可以请求取消正在进行的转录
final class TranscriptionService: @unchecked Sendable {
    /// 当前使用的模型
    private var currentModel: ASRModel?
    
    /// 执行转录
    /// - Parameters:
    ///   - audioFile: 音频文件
    ///   - model: ASR 模型
    ///   - language: 语言（nil 为自动检测）
    ///   - progressHandler: 进度回调
    /// - Returns: 转录结果
    /// - Throws: ASRError 当转录失败时
    func transcribe(
        audioFile: AudioFile,
        model: ASRModel,
        language: Language? = nil,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        // 实现
    }
}
```

### 并发编程规范

```swift
// 1. 优先使用 actor 隔离状态
actor AudioPreprocessor {
    private var cache: [String: Data] = [:]
    
    func process(audio: AudioFile) async throws -> Data {
        // 线程安全
    }
}

// 2. 使用 @MainActor 标记 UI 相关类型
@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var progress: Double = 0
}

// 3. 合理使用 @unchecked Sendable
/// 文档说明为什么使用 @unchecked Sendable
final class TranscriptionService: @unchecked Sendable {
    @MainActor private var isCancelled = false
    
    func cancel() {
        Task { @MainActor in
            isCancelled = true
        }
    }
}

// 4. Task 管理
final class AppState: ObservableObject {
    private var loadHistoryTask: Task<Void, Never>?
    
    init() {
        loadHistoryTask = Task {
            await loadHistory()
        }
    }
    
    deinit {
        loadHistoryTask?.cancel()
    }
}
```

### 错误处理规范

```swift
// 1. 定义明确的错误类型
enum ASRError: LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case audioLoadFailed
    case inferenceFailed(String)
    case outOfMemory
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "模型未找到，请先下载模型"
        case .modelLoadFailed:
            return "模型加载失败"
        // ...
        }
    }
}

// 2. 提供恢复建议
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

// 3. 使用 Result 类型处理可选失败
func loadModel() async -> Result<Model, Error> {
    do {
        let model = try await load()
        return .success(model)
    } catch {
        return .failure(error)
    }
}
```

---

## 🧪 测试指南

### 测试结构

```
ShenManTests/
├── Models/
│   ├── AudioFileTests.swift
│   └── TranscriptionResultTests.swift
├── Services/
│   ├── TranscriptionServiceTests.swift
│   └── ModelManagerTests.swift
├── Processors/
│   ├── TimestampAggregatorTests.swift
│   └── ChinesePostProcessorTests.swift
├── Exporters/
│   ├── TXTExporterTests.swift
│   ├── SRTExporterTests.swift
│   └── MarkdownExporterTests.swift
├── Repositories/
│   ├── FileRepositoryTests.swift
│   └── HistoryRepositoryTests.swift
└── Integration/
    └── TranscriptionIntegrationTests.swift
```

### 单元测试示例

```swift
import XCTest
@testable import ShenMan

final class TimestampAggregatorTests: XCTestCase {
    private var aggregator: TimestampAggregator!
    
    override func setUp() {
        super.setUp()
        aggregator = TimestampAggregator()
    }
    
    func testAggregateByPunctuation() async {
        // Given
        let words = [
            WordTimestamp(word: "今天", startTime: 0, endTime: 0.5),
            WordTimestamp(word: "天气", startTime: 0.5, endTime: 1.0),
            WordTimestamp(word: "不错", startTime: 1.0, endTime: 1.5),
            WordTimestamp(word: "。", startTime: 1.5, endTime: 1.6)
        ]
        
        // When
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        // Then
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0].text, "今天天气不错。")
        XCTAssertEqual(sentences[0].startTime, 0)
        XCTAssertEqual(sentences[0].endTime, 1.6)
    }
    
    func testMergeShortSentences() async {
        // Given
        let sentences = [
            SentenceTimestamp(text: "你好", startTime: 0, endTime: 0.5),
            SentenceTimestamp(text: "世界", startTime: 0.6, endTime: 1.0)
        ]
        
        // When
        let merged = aggregator.mergeShortSentences(sentences: sentences)
        
        // Then
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].text, "你好世界")
    }
}
```

### 集成测试示例

```swift
final class TranscriptionIntegrationTests: XCTestCase {
    func testFullTranscriptionFlow() async throws {
        // Given
        let service = TranscriptionService()
        let model = Qwen3ASRModelWrapper(huggingFaceId: "mlx-community/Qwen3-ASR-0.6B-8bit")
        let audioFile = try AudioFile(
            url: Bundle.main.url(forResource: "test", withExtension: "mp3")!
        )
        
        // When
        var progressUpdates: [Double] = []
        let result = try await service.transcribe(
            audioFile: audioFile,
            model: model,
            language: .chinese
        ) { progress, _ in
            progressUpdates.append(progress)
        }
        
        // Then
        XCTAssertGreaterThan(result.sentences.count, 0)
        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertEqual(progressUpdates.last, 1.0)
    }
}
```

### 运行测试

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter TimestampAggregatorTests

# 生成测试覆盖率报告
swift test --enable-code-coverage

# 查看覆盖率报告
llvm-cov report .build/debug/ShenManPackageTests.xctest/Contents/MacOS/ShenManPackageTests \
  -instr-profile .build/debug/codecov/default.profdata
```

---

## 🔧 调试技巧

### 日志调试

```swift
// 使用 os.log 进行结构化日志
import os

private let logger = Logger(subsystem: "com.shenman", category: "Transcription")

func transcribe() async throws {
    logger.info("开始转录")
    
    do {
        let result = try await model.transcribe()
        logger.info("转录完成，句子数：\(result.sentences.count)")
    } catch {
        logger.error("转录失败：\(error.localizedDescription)")
        throw error
    }
}
```

### Instruments 性能分析

1. **内存泄漏检测**
   ```bash
   # 使用 Leaks Instrument
   xcrun instruments -t Leaks ShenMan.app
   ```

2. **CPU 使用分析**
   ```bash
   # 使用 Time Profiler
   xcrun instruments -t "Time Profiler" ShenMan.app
   ```

3. **内存分配分析**
   ```bash
   # 使用 Allocations
   xcrun instruments -t Allocations ShenMan.app
   ```

### 常见调试场景

#### 场景 1：转录速度慢

```swift
// 1. 添加性能日志
let startTime = CFAbsoluteTimeGetCurrent()
let result = try await model.transcribe()
let duration = CFAbsoluteTimeGetCurrent() - startTime
logger.info("转录耗时：\(duration)秒")

// 2. 使用 Instruments 分析热点
// 运行 Time Profiler，查看耗时函数

// 3. 优化建议
// - 检查音频预处理是否高效
// - 检查模型加载是否重复
// - 考虑使用模型缓存
```

#### 场景 2：内存占用过高

```swift
// 1. 监控内存
func logMemoryUsage() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        let memoryMB = Double(info.resident_size) / 1024.0 / 1024.0
        logger.info("内存使用：\(String(format: "%.2f", memoryMB)) MB")
    }
}

// 2. 优化建议
// - 使用流式处理代替全量加载
// - 及时释放大对象
// - 使用autoreleasepool
```

---

## 📦 构建和发布

### 构建配置

```bash
# Debug 构建
swift build

# Release 构建
swift build -c release

# 指定架构
swift build --arch arm64

# 清理构建
swift package clean
```

### 代码签名

项目使用开发证书签名（个人开发者）：

1. 在 Xcode 中选择项目
2. Signing & Capabilities
3. 选择 Team（个人）
4. 勾选 "Automatically manage signing"

### 无签名分发

由于是个人开发者账号，分发的 App 会有"无法验证开发者"的警告。

**用户解决方案**：
```bash
# 1. 首次运行时右键点击打开
# 2. 或在系统偏好设置 → 安全性与隐私 中允许
```

### 发布流程

1. **更新版本号**
   ```bash
   # 更新 Info.plist 中的 CFBundleShortVersionString
   # 更新 Package.swift 中的版本
   ```

2. **编写 Release Notes**
   - 新功能
   - Bug 修复
   - 性能改进
   - 已知问题

3. **创建 Git Tag**
   ```bash
   git tag -a v0.1.0 -m "Release v0.1.0 - MVP"
   git push origin v0.1.0
   ```

4. **构建 Release**
   ```bash
   swift build -c release
   ```

5. **创建 GitHub Release**
   - 上传 App
   - 添加 Release Notes
   - 标注为 Pre-release（如适用）

---

## 🐛 故障排除

### 常见问题

#### 问题 1：编译错误 "Module 'os' has no member named 'AtomicBool'"

**原因**：`os.AtomicBool` 在 macOS 15.0 才引入

**解决方案**：
```swift
// 使用 @MainActor 代替
@MainActor private var isCancelled = false

// 或使用 DispatchSemaphore
private let lock = NSLock()
private var _isCancelled = false
var isCancelled: Bool {
    get { lock.withLock { _isCancelled } }
    set { lock.withLock { _isCancelled = newValue } }
}
```

#### 问题 2：MLX 模型加载失败

**症状**：
```
Error: Model load failed
```

**排查步骤**：
1. 检查模型是否已下载
2. 检查模型路径是否正确
3. 检查内存是否充足
4. 查看模型文件完整性

**解决方案**：
```bash
# 重新下载模型
rm -rf ~/Library/Application\ Support/ShenMan/models
# 重启 App
```

#### 问题 3：转录结果为空

**可能原因**：
- 音频格式不支持
- 模型与音频采样率不匹配
- 音频音量过低

**排查步骤**：
1. 检查音频文件格式
2. 检查音频预处理输出
3. 添加调试日志

```swift
logger.info("音频采样率：\(audioFile.sampleRate)")
logger.info("音频时长：\(audioFile.duration)秒")
```

#### 问题 4：UI 卡顿

**可能原因**：
- 主线程阻塞
- 大量文本更新
- 内存压力

**解决方案**：
```swift
// 1. 将耗时操作移到后台
Task.detached {
    let result = try await service.transcribe()
    await MainActor.run {
        self.result = result
    }
}

// 2. 批量更新 UI
withAnimation(.easeInOut(duration: 0.3)) {
    self.progress = newProgress
}

// 3. 使用 Instruments 分析
```

---

## 📚 参考资源

### 官方文档

- [Swift 官方文档](https://docs.swift.org/swift-book/)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [MLX Swift 文档](https://ml-explore.github.io/mlx-swift/)
- [AVFoundation 编程指南](https://developer.apple.com/documentation/avfoundation)

### 技术文章

- [Swift 并发编程](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI 最佳实践](https://developer.apple.com/documentation/swiftui)
- [MVVM 架构模式](https://developer.apple.com/documentation/swiftui/model-view-presenter)

### 相关项目

- [mlx-swift](https://github.com/ml-explore/mlx-swift)
- [mlx-audio-swift](https://github.com/Blaizzy/mlx-audio-swift)
- [WhisperKit](https://github.com/argmaxinc/WhisperKit)

---

## 🤝 贡献指南

### 提交代码

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

### 代码审查清单

- [ ] 代码符合 Swift 编码规范
- [ ] 添加了必要的注释
- [ ] 编写了单元测试
- [ ] 所有测试通过
- [ ] 没有编译警告
- [ ] 性能没有明显下降
- [ ] 没有内存泄漏

---

**文档版本**: v1.0  
**最后更新**: 2026-03-18  
**维护者**: ShenMan Team
