# 声声慢 (ShenMan) - 编码规范

## 📋 文档说明

本文档定义声声慢项目的编码规范，所有贡献者都应遵循这些规范以保持代码质量和一致性。

**目标读者**：
- 项目开发者
- 代码审查者
- 贡献者

---

## 1. Swift 语言规范

### 1.1 语言版本

- **Swift 版本**: 6.0
- **语言模式**: Swift 6
- **并发检查**: StrictConcurrency=complete
- **最低系统**: macOS 14.0

### 1.2 访问控制

```swift
// 优先使用最严格的访问控制
private let privateVar = 0      // 仅当前类型可见
fileprivate let filePrivate = 0 // 仅当前文件可见
internal let internalVar = 0    // 仅当前模块可见（默认）
public let publicVar = 0        // 所有模块可见
```

**原则**：
- 默认使用 `private`
- 需要跨文件访问时使用 `fileprivate`
- 需要跨模块访问时使用 `public`
- 避免使用 `open`（除非需要子类化）

### 1.3 类型

#### 1.3.1 类 (Class)

```swift
/// 文档注释说明类的用途
///
/// ## 使用示例
/// ```swift
/// let service = TranscriptionService()
/// try await service.transcribe(audioFile: audio)
/// ```
final class TranscriptionService: @unchecked Sendable {
    // 实现
}
```

**规范**：
- 优先使用 `final class`（除非需要继承）
- 提供完整的文档注释
- 说明并发安全特性

#### 1.3.2 结构体 (Struct)

```swift
/// 音频文件模型
///
/// 表示一个待转录或已转录的音频文件
struct AudioFile: Sendable {
    let url: URL
    let filename: String
    let duration: TimeInterval
}
```

**规范**：
- 值类型优先使用 `struct`
- 实现 `Sendable` 保证并发安全
- 使用 `let` 声明不可变属性

#### 1.3.3 枚举 (Enum)

```swift
/// 语言类型
enum Language: String, Codable, CaseIterable, Sendable {
    case auto = "auto"
    case chinese = "zh"
    case chineseCantonese = "zh-HK"
    case english = "en"
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .auto: return "自动检测"
        case .chinese: return "普通话"
        case .chineseCantonese: return "粤语"
        case .english: return "英语"
        }
    }
}
```

**规范**：
- 实现 `CaseIterable` 支持遍历
- 实现 `Codable` 支持序列化
- 实现 `Sendable` 保证并发安全
- 提供原始值便于存储

#### 1.3.4 协议 (Protocol)

```swift
/// ASR 模型协议
///
/// 所有语音识别模型必须实现此协议
protocol ASRModel: Sendable {
    /// 模型唯一标识符
    var id: String { get }
    
    /// 模型显示名称
    var name: String { get }
    
    /// 模型描述
    var description: String { get }
    
    /// 下载模型
    /// - Parameter progressHandler: 进度回调
    func download(progressHandler: @escaping @Sendable (Double) -> Void) async throws
    
    /// 转录音频
    /// - Parameters:
    ///   - audioFile: 音频文件
    ///   - language: 语言
    ///   - progressHandler: 进度回调
    /// - Returns: 转录结果
    func transcribe(
        audioFile: AudioFile,
        language: Language?,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> RawTranscriptionResult
}
```

**规范**：
- 协议名称使用名词或动词 + 名词
- 提供完整的参数和返回值文档
- 使用 `Sendable` 保证并发安全

---

## 2. 命名规范

### 2.1 类型命名

```swift
// PascalCase
final class TranscriptionService { }
struct AudioFile { }
protocol ASRModel { }
enum Language { }
```

### 2.2 成员命名

```swift
// 属性：camelCase
let fileName: String
var progress: Double

// 方法：camelCase
func transcribe() async throws { }
func cancel() { }

// 枚举值：camelCase
case chineseCantonese
case pauseThreshold

// 常量：camelCase
static let defaultSampleRate = 16000
```

### 2.3 缩写规则

```swift
// 首字母缩略词全部小写
let url: URL
let id: String
let html: String

// 但在类型名称中保持大写
struct URLValidator { }
enum IDType { }
```

### 2.4 布尔值命名

```swift
// 使用 is/has/should/can 等前缀
var isProcessing: Bool
var hasError: Bool
var shouldRetry: Bool
var canCancel: Bool

// 避免使用否定形式
var isEnabled: Bool      // ✅ 好
var isDisabled: Bool     // ❌ 避免
```

### 2.5 闭包命名

```swift
// 使用描述性的名称
progressHandler: @escaping (Double) -> Void
completionHandler: @escaping (Result) -> Void
errorHandler: @escaping (Error) -> Void

// 避免使用过于通用的名称
handler: @escaping (Any) -> Void  // ❌ 避免
```

---

## 3. 注释规范

### 3.1 文档注释

```swift
/// 转录服务
///
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
///
/// ## 示例
/// ```swift
/// let service = TranscriptionService()
/// let result = try await service.transcribe(
///     audioFile: audio,
///     model: model
/// ) { progress, message in
///     print("进度：\(progress)")
/// }
/// ```
final class TranscriptionService {
    // 实现
}
```

### 3.2 函数注释

```swift
/// 执行转录
///
/// 协调模型、处理器完成完整的转录流程，包括：
/// 1. 检查模型下载
/// 2. 执行转录
/// 3. 时间戳聚合
/// 4. 后处理
///
/// - Parameters:
///   - audioFile: 音频文件
///   - model: ASR 模型
///   - language: 语言（nil 为自动检测）
///   - progressHandler: 进度回调（0.0 - 1.0）
///
/// - Returns: 转录结果，包含句子级时间戳
///
/// - Throws:
///   - ASRError.modelLoadFailed: 模型加载失败
///   - ASRError.audioLoadFailed: 音频加载失败
///   - ASRError.inferenceFailed: 推理失败
///   - ASRError.cancelled: 用户取消
func transcribe(
    audioFile: AudioFile,
    model: ASRModel,
    language: Language?,
    progressHandler: @escaping (Double, String) -> Void
) async throws -> TranscriptionResult
```

### 3.3 行内注释

```swift
// 1. 使用双斜杠加空格
// 注释说明代码的意图，而不是代码本身

// ✅ 好
// 检查模型是否已下载，未下载则先下载
if !model.isDownloaded {
    try await model.download()
}

// ❌ 避免
// 检查 isDownloaded
if !model.isDownloaded {
    // 下载
    try await model.download()
}

// 2. 复杂逻辑添加注释
// 使用归一化时间戳计算相对时间
let relativeStartTime = word.startTime - segmentStartTime
let relativeEndTime = word.endTime - segmentStartTime
```

### 3.4 TODO 注释

```swift
// TODO: 实现模型缓存机制
// TODO: [性能] 优化大文件处理
// FIXME: 修复内存泄漏问题
// NOTE: 注意这里需要特殊处理
// HACK: 临时解决方案，待重构
```

**格式**：
- `TODO`: 待实现的功能
- `FIXME`: 需要修复的问题
- `NOTE`: 需要注意的事项
- `HACK`: 临时解决方案

---

## 4. 代码格式

### 4.1 缩进

```swift
// 使用 4 个空格缩进
func example() {
    if condition {
        doSomething()
    }
}

// 不使用制表符
```

### 4.2 空行

```swift
// 1. 类型之间空一行
class A { }

class B { }

// 2. MARK 注释前后空一行
class C {
    // MARK: - 属性
    
    let property: String
    
    // MARK: - 方法
    
    func method() { }
}

// 3. 逻辑块之间空一行
func process() {
    // 准备数据
    let data = prepareData()
    
    // 处理数据
    let result = transform(data)
    
    // 返回结果
    return result
}
```

### 4.3 行宽

```swift
// 最大行宽：120 字符
// 超过时适当换行

let longString = "这是一个非常长的字符串，超过了 120 字符的限制，需要换行处理"

// 函数参数过多时换行
func process(
    param1: String,
    param2: Int,
    param3: Bool
) {
    // 实现
}
```

### 4.4 大括号

```swift
// 左大括号不换行
func example() {
    // 实现
}

// 控制语句同样
if condition {
    // 实现
} else {
    // 实现
}

// 单行控制语句可以写在一行
if condition { return }
```

### 4.5 类型注解

```swift
// 需要类型注解的情况
let items: [String] = []  // 空数组需要
let dict: [String: Int] = [:]  // 空字典需要

// 类型可以推断时省略
let count = 0  // ✅ 好
let name = "John"  // ✅ 好

// 闭包参数需要类型注解
let handler: (Double) -> Void = { progress in
    print(progress)
}
```

---

## 5. 并发编程规范

### 5.1 actor 使用

```swift
// 1. 优先使用 actor 隔离可变状态
actor DataProcessor {
    private var cache: [String: Data] = [:]
    
    func process(id: String) async throws -> Data {
        if let cached = cache[id] {
            return cached
        }
        
        let data = try await fetchData(id: id)
        cache[id] = data
        return data
    }
}

// 2. 在 actor 外部调用需要 await
let processor = DataProcessor()
let data = try await processor.process(id: "123")
```

### 5.2 @MainActor 使用

```swift
// 1. UI 相关类型使用 @MainActor
@MainActor
final class ViewModel: ObservableObject {
    @Published var progress: Double = 0
    
    func updateProgress(_ progress: Double) {
        self.progress = progress  // 自动在 MainActor 上
    }
}

// 2. 需要切换到 MainActor 时使用 Task
func download() async throws {
    let data = try await fetchData()
    
    Task { @MainActor in
        self.uiUpdate(data)
    }
}
```

### 5.3 @unchecked Sendable 使用

```swift
/// 文档说明为什么使用 @unchecked Sendable
///
/// 本类型使用 @unchecked Sendable 因为：
/// 1. 持有非 Sendable 的依赖（如 FileManager）
/// 2. 所有方法都是线程安全的
/// 3. 通过其他机制保证并发安全
final class FileRepository: @unchecked Sendable {
    private let fileManager: FileManager  // FileManager 不是 Sendable
    
    // 方法都是线程安全的
    func readFile(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}
```

### 5.4 Task 管理

```swift
// 1. 保存 Task 引用以便取消
final class AppState: ObservableObject {
    private var loadTask: Task<Void, Never>?
    
    init() {
        loadTask = Task {
            await loadData()
        }
    }
    
    deinit {
        loadTask?.cancel()
    }
}

// 2. 使用 weak self 避免内存泄漏
currentTask = Task { [weak self] in
    guard let self = self else { return }
    // 逻辑
}

// 3. 使用 Task.detached 进行后台处理
Task.detached {
    let result = try await heavyComputation()
    await MainActor.run {
        self.updateUI(result)
    }
}
```

### 5.5 异步序列

```swift
// 使用 AsyncStream 进行流式处理
func processStream() -> AsyncStream<String> {
    AsyncStream { continuation in
        Task {
            for try await line in fileLines {
                continuation.yield(line)
            }
            continuation.finish()
        }
    }
}

// 使用
for try await line in processStream() {
    print(line)
}
```

---

## 6. 错误处理规范

### 6.1 错误类型定义

```swift
enum TranscriptionError: LocalizedError {
    case modelNotFound
    case audioLoadFailed
    case inferenceFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "模型未找到"
        case .audioLoadFailed:
            return "音频加载失败"
        case .inferenceFailed(let reason):
            return "推理失败：\(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "请在设置中下载模型"
        default:
            return nil
        }
    }
}
```

### 6.2 错误传播

```swift
// 1. 使用 throws 传播错误
func transcribe() async throws -> TranscriptionResult {
    try await model.download()
    try await model.transcribe()
}

// 2. 在边界处处理错误
do {
    let result = try await service.transcribe()
    showResult(result)
} catch let error as TranscriptionError {
    showError(error.errorDescription ?? "未知错误")
    if let suggestion = error.recoverySuggestion {
        showSuggestion(suggestion)
    }
} catch {
    showError("发生错误：\(error.localizedDescription)")
}
```

### 6.3 错误转换

```swift
// 将底层错误转换为业务错误
func loadData() async throws -> Data {
    do {
        return try repository.readFile()
    } catch FileError.fileNotFound {
        throw TranscriptionError.modelNotFound
    } catch {
        throw TranscriptionError.inferenceFailed(reason: error.localizedDescription)
    }
}
```

### 6.4 Result 类型

```swift
// 对于可选失败的场景，使用 Result
func loadModel() async -> Result<Model, Error> {
    do {
        let model = try await load()
        return .success(model)
    } catch {
        return .failure(error)
    }
}

// 使用
let result = await loadModel()
switch result {
case .success(let model):
    useModel(model)
case .failure(let error):
    handleError(error)
}
```

---

## 7. 测试规范

### 7.1 测试类命名

```swift
// 被测试类型 + Tests
final class TimestampAggregatorTests: XCTestCase { }
final class ChinesePostProcessorTests: XCTestCase { }

// 集成测试
final class TranscriptionIntegrationTests: XCTestCase { }
```

### 7.2 测试方法命名

```swift
// test + 功能 + 预期结果
func testAggregateByPunctuation_returnsSentences() { }
func testMergeShortSentences_combinesShortSentences() { }
func testTranscribeWithProgress_updatesProgress() async { }

// 使用 Given-When-Then 模式
func testGivenPunctuation_whenAggregate_thenReturnsSentences() { }
```

### 7.3 测试结构

```swift
final class TimestampAggregatorTests: XCTestCase {
    private var aggregator: TimestampAggregator!
    
    override func setUp() {
        super.setUp()
        aggregator = TimestampAggregator()
    }
    
    override func tearDown() {
        aggregator = nil
        super.tearDown()
    }
    
    func testAggregateByPunctuation() {
        // Given
        let words = [
            WordTimestamp(word: "你好", startTime: 0, endTime: 0.5),
            WordTimestamp(word: "。", startTime: 0.5, endTime: 0.6)
        ]
        
        // When
        let sentences = aggregator.aggregate(words: words, strategy: .punctuation)
        
        // Then
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0].text, "你好。")
    }
}
```

### 7.4 测试覆盖率

```bash
# 运行测试并生成覆盖率报告
swift test --enable-code-coverage

# 目标覆盖率
# - 核心业务逻辑：> 80%
# - 处理器：> 90%
# - UI 组件：> 60%
```

---

## 8. Git 规范

### 8.1 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 8.2 类型 (type)

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构（既不是新功能也不是 bug 修复）
- `test`: 测试相关
- `chore`: 构建过程或辅助工具变动

### 8.3 提交示例

```
feat(transcription): 添加中文后处理功能

- 实现同音字纠错
- 实现标点优化
- 实现数字格式化

Closes #123

---

fix(ui): 修复转录进度显示错误

进度条在取消后没有重置的问题

Fixes #456

---

docs(readme): 更新安装说明

添加 Homebrew 安装方式
```

### 8.4 分支命名

```
main              # 主分支
develop           # 开发分支
feature/xxx       # 功能分支
bugfix/xxx        # bug 修复分支
release/v1.0.0    # 发布分支
hotfix/xxx        # 紧急修复分支
```

---

## 9. 代码审查清单

### 9.1 功能性

- [ ] 代码实现符合需求
- [ ] 边界条件已处理
- [ ] 错误处理完善
- [ ] 没有逻辑错误

### 9.2 代码质量

- [ ] 符合编码规范
- [ ] 命名清晰易懂
- [ ] 注释完整准确
- [ ] 没有重复代码
- [ ] 函数职责单一

### 9.3 性能

- [ ] 没有明显的性能问题
- [ ] 大对象处理合理
- [ ] 内存管理正确
- [ ] 没有内存泄漏

### 9.4 并发安全

- [ ] 正确使用 actor
- [ ] Sendable 合规
- [ ] 没有数据竞争
- [ ] Task 管理正确

### 9.5 测试

- [ ] 添加了必要的测试
- [ ] 测试覆盖核心逻辑
- [ ] 所有测试通过

---

**文档版本**: v1.0  
**创建日期**: 2026-03-18  
**最后更新**: 2026-03-18  
**维护者**: ShenMan Team
