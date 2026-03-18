# 声声慢 (ShenMan) - 故障排除指南

## 📋 文档说明

本文档提供声声慢应用常见问题的排查和解决方案。

**目标读者**：
- 开发者
- 技术支持人员
- 高级用户

---

## 🔍 问题诊断流程

### 通用诊断步骤

```
1. 复现问题
   ↓
2. 查看错误日志
   ↓
3. 定位问题模块
   ↓
4. 分析根本原因
   ↓
5. 应用解决方案
   ↓
6. 验证修复
```

---

## 1. 编译问题

### 1.1 错误：Module 'os' has no member named 'AtomicBool'

**症状**：
```
error: module 'os' has no member named 'AtomicBool'
```

**原因**：
- `os.AtomicBool` 在 macOS 15.0 才引入
- 项目最低支持 macOS 14.0

**解决方案**：

方案 1：使用 `@MainActor`
```swift
// ❌ 错误
private let isCancelledFlag = os.AtomicBool(false)

// ✅ 正确
@MainActor private var isCancelled = false
```

方案 2：使用 `NSLock`
```swift
private let lock = NSLock()
private var _isCancelled = false

var isCancelled: Bool {
    get { lock.withLock { _isCancelled } }
    set { lock.withLock { _isCancelled = newValue } }
}
```

### 1.2 错误：Stored property is mutable

**症状**：
```
error: stored property 'services' of 'Sendable'-conforming class is mutable
```

**原因**：
- `Sendable` 协议要求所有属性不可变

**解决方案**：
```swift
// ❌ 错误
final class DependencyContainer: Sendable {
    private var services: [String: Any] = [:]
}

// ✅ 正确
final class DependencyContainer: @unchecked Sendable {
    private var services: [String: Any] = [:]
}
```

### 1.3 错误：Type does not conform to protocol

**症状**：
```
error: type 'FileRepository' does not conform to protocol 'FileRepositoryProtocol'
```

**原因**：
- 协议要求的方法签名不匹配

**解决方案**：
```swift
// 检查方法签名是否完全匹配
protocol FileRepositoryProtocol {
    func writeFile(_ data: Data, to url: URL) throws
}

// 实现必须完全匹配
func writeFile(_ data: Data, to url: URL) throws {
    // 实现
}
```

### 1.4 错误：Call can throw but is not marked with 'try'

**症状**：
```
error: call can throw but is not marked with 'try'
```

**原因**：
- 调用的异步方法可能抛出错误

**解决方案**：
```swift
// ❌ 错误
let results = await batchService.startBatch(modelId: modelId)

// ✅ 正确
do {
    let results = try await batchService.startBatch(modelId: modelId)
} catch {
    handleError(error)
}
```

---

## 2. 运行时问题

### 2.1 应用启动崩溃

**症状**：
- 应用启动时立即崩溃
- 控制台显示错误信息

**排查步骤**：

1. 查看崩溃日志
```bash
# 查看 macOS 崩溃报告
open ~/Library/Logs/DiagnosticReports/
```

2. 检查常见原因

**原因 1：Entitlements 配置错误**
```xml
<!-- 检查 ShenMan.entitlements -->
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

**原因 2：Info.plist 配置错误**
```xml
<!-- 检查最低系统版本 -->
<key>LSMinimumSystemVersion</key>
<string>14.0</string>
```

**原因 3：资源文件缺失**
```swift
// 检查资源文件是否存在
guard let modelPath = Bundle.main.path(forResource: "model", ofType: "mlmodel") else {
    print("资源文件缺失")
    return
}
```

### 2.2 内存泄漏

**症状**：
- 应用运行时间越长，内存占用越高
- 系统警告内存不足

**排查工具**：
```bash
# 使用 Instruments Leaks
xcrun instruments -t Leaks ShenMan.app

# 使用 Instruments Allocations
xcrun instruments -t Allocations ShenMan.app
```

**常见原因和解决方案**：

**原因 1：循环引用**
```swift
// ❌ 错误
currentTask = Task {
    self.updateUI()  // 强引用 self
}

// ✅ 正确
currentTask = Task { [weak self] in
    guard let self = self else { return }
    self.updateUI()
}
```

**原因 2：未取消的 Task**
```swift
// ❌ 错误
init() {
    Task {
        await loadData()
    }
}

// ✅ 正确
private var loadTask: Task<Void, Never>?

init() {
    loadTask = Task {
        await loadData()
    }
}

deinit {
    loadTask?.cancel()
}
```

**原因 3：闭包捕获**
```swift
// ❌ 错误
model.download { progress in
    self.updateProgress(progress)
}

// ✅ 正确
model.download { [weak self] progress in
    guard let self = self else { return }
    self.updateProgress(progress)
}
```

### 2.3 UI 卡顿

**症状**：
- 界面响应慢
- 滚动卡顿
- 动画不流畅

**排查工具**：
```bash
# 使用 Time Profiler
xcrun instruments -t "Time Profiler" ShenMan.app
```

**常见原因和解决方案**：

**原因 1：主线程阻塞**
```swift
// ❌ 错误
func processLargeFile() {
    let data = try! Data(contentsOf: url)  // 阻塞主线程
    self.textView.string = String(data: data, encoding: .utf8)
}

// ✅ 正确
Task.detached {
    let data = try! Data(contentsOf: url)
    await MainActor.run {
        self.textView.string = String(data: data, encoding: .utf8)
    }
}
```

**原因 2：大量文本更新**
```swift
// ❌ 错误
for sentence in sentences {
    textView.string += sentence.text  // 每次都触发重绘
}

// ✅ 正确
let fullText = sentences.map { $0.text }.joined(separator: "\n")
textView.string = fullText  // 一次性更新
```

**原因 3：频繁的状态更新**
```swift
// ❌ 错误
for progress in 0...100 {
    self.progress = Double(progress)  // 100 次状态更新
}

// ✅ 正确
withAnimation(.easeInOut(duration: 0.3)) {
    self.progress = newProgress
}
```

---

## 3. 转录问题

### 3.1 转录结果为空

**症状**：
- 转录完成后结果为空
- 没有错误提示

**排查步骤**：

1. 检查音频文件
```swift
print("音频路径：\(audioFile.url)")
print("音频时长：\(audioFile.duration)")
print("音频格式：\(audioFile.format)")
```

2. 检查模型状态
```swift
print("模型已下载：\(model.isDownloaded)")
print("模型名称：\(model.name)")
```

3. 添加调试日志
```swift
func transcribe() async throws {
    logger.info("开始转录")
    
    do {
        let result = try await model.transcribe()
        logger.info("转录完成，句子数：\(result.sentences.count)")
    } catch {
        logger.error("转录失败：\(error)")
        throw error
    }
}
```

**常见原因**：

**原因 1：模型未下载**
```bash
# 解决方案：重新下载模型
rm -rf ~/Library/Application\ Support/ShenMan/models
# 重启应用，触发下载
```

**原因 2：音频格式不支持**
```swift
// 检查支持的格式
let supportedFormats = ["mp3", "wav", "m4a", "flac", "aac"]
if !supportedFormats.contains(audioFile.format.rawValue) {
    throw TranscriptionError.unsupportedFormat
}
```

**原因 3：音频音量过低**
```bash
# 使用 ffprobe 检查音频音量
ffprobe -i audio.mp3 -af volumedetect -f null /dev/null
```

### 3.2 转录速度慢

**症状**：
- 转录时间远超预期
- RTF (Real Time Factor) > 0.5

**排查步骤**：

1. 测量各阶段耗时
```swift
let startTime = CFAbsoluteTimeGetCurrent()

let modelLoadTime = CFAbsoluteTimeGetCurrent()
try await model.download()
logger.info("模型加载耗时：\(CFAbsoluteTimeGetCurrent() - modelLoadTime)")

let transcribeTime = CFAbsoluteTimeGetCurrent()
let result = try await model.transcribe()
logger.info("转录耗时：\(CFAbsoluteTimeGetCurrent() - transcribeTime)")

logger.info("总耗时：\(CFAbsoluteTimeGetCurrent() - startTime)")
```

2. 使用 Instruments 分析

**常见原因**：

**原因 1：模型重复加载**
```swift
// ❌ 错误
func transcribe() {
    let model = try await loadModel()  // 每次都重新加载
}

// ✅ 正确
private var cachedModel: ASRModel?

func transcribe() async throws {
    if cachedModel == nil {
        cachedModel = try await loadModel()
    }
    let model = cachedModel!
}
```

**原因 2：音频预处理低效**
```swift
// 优化音频加载
private func loadAudioAsMLXArray(from url: URL) throws -> MLXArray {
    // 使用流式处理代替全量加载
    var samples: [Float] = []
    for chunk in audioChunks {
        samples.append(contentsOf: chunk)
    }
    return MLXArray(samples)
}
```

**原因 3：内存压力**
```swift
// 监控内存使用
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
```

### 3.3 转录准确率低

**症状**：
- 识别错误多
- 同音字错误频繁

**排查步骤**：

1. 检查模型选择
```swift
// 确认使用的是正确的模型
print("当前模型：\(settings.selectedModel)")
```

2. 检查后处理是否生效
```swift
// 添加调试输出
func correctHomophones(sentences: [SentenceTimestamp]) -> [SentenceTimestamp] {
    sentences.map { sentence in
        var correctedText = sentence.text
        for (wrong, correct) in Self.homophoneCorrections {
            if correctedText.contains(wrong) {
                logger.info("纠错：\(wrong) → \(correct)")
                correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
            }
        }
        return sentence.with(text: correctedText)
    }
}
```

**常见原因**：

**原因 1：模型不适合当前场景**
```swift
// 根据场景选择模型
if audioFile.duration > 3600 {  // 长音频
    selectedModel = .qwen3ASR06B8bit  // 小模型，速度快
} else {
    selectedModel = .qwen3ASR17B8bit  // 大模型，准确率高
}
```

**原因 2：音频质量问题**
```bash
# 检查音频质量
ffprobe -i audio.mp3 -show_streams -select_streams a
```

**原因 3：后处理规则不足**
```swift
// 添加更多纠错规则
private static let homophoneCorrections: [String: String] = [
    // 会议相关
    "配备": "配置",
    "协义": "协议",
    // 技术相关
    "网路": "网络",
    "软体": "软件",
    // 添加更多...
]
```

---

## 4. 导出问题

### 4.1 导出失败

**症状**：
- 点击导出无反应
- 导出后文件为空

**排查步骤**：

1. 检查导出路径
```swift
let savePanel = NSSavePanel()
savePanel.allowedContentTypes = [.text]

if let url = savePanel.url {
    print("导出路径：\(url)")
    print("路径可写：\(FileManager.default.isWritableFile(atPath: url.path))")
}
```

2. 检查导出内容
```swift
let data = try exporter.export(result: result, options: options)
print("导出数据大小：\(data.count) bytes")
```

**常见原因**：

**原因 1：权限问题**
```xml
<!-- 检查 Entitlements -->
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

**原因 2：编码问题**
```swift
// ❌ 错误
let content = sentences.map { $0.text }.joined()
let data = content.data(using: .ascii)!  // ASCII 不支持中文

// ✅ 正确
let data = content.data(using: .utf8)!  // UTF-8 支持中文
```

### 4.2 SRT 时间轴错误

**症状**：
- 字幕时间轴不准确
- 字幕与声音不同步

**排查步骤**：

1. 检查时间戳格式
```swift
func formatSRTTime(_ time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    let seconds = Int(time) % 60
    let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
    return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
}
```

2. 验证输出格式
```srt
1
00:00:01,200 --> 00:00:03,500
今天天气不错
```

---

## 5. 批量处理问题

### 5.1 批量处理卡住

**症状**：
- 批量处理进行到某个文件后卡住
- 进度条不更新

**排查步骤**：

1. 检查队列状态
```swift
actor BatchProcessingService {
    func getStatus() -> String {
        return "总任务：\(tasks.count), 已完成：\(completedCount)"
    }
}
```

2. 添加超时机制
```swift
func startBatch(modelId: ModelIdentifier) async throws {
    for task in tasks {
        // 添加超时
        try await withTimeout(seconds: 300) {
            try await transcribe(task.audioFile)
        }
    }
}

private func withTimeout<T>(seconds: Double, operation: () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask(operation)
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

---

## 6. 日志和调试

### 6.1 启用日志

```swift
import os

private let logger = Logger(subsystem: "com.shenman", category: "Transcription")

// 不同级别的日志
logger.debug("调试信息")
logger.info("一般信息")
logger.warning("警告信息")
logger.error("错误信息")
```

### 6.2 查看日志

```bash
# 查看应用日志
log show --predicate 'subsystem == "com.shenman"' --last 1h

# 实时查看日志
log stream --predicate 'subsystem == "com.shenman"'
```

### 6.3 调试技巧

**技巧 1：性能分析**
```swift
func measure<T>(_ operation: () throws -> T) rethrows -> T {
    let start = CFAbsoluteTimeGetCurrent()
    let result = try operation()
    let duration = CFAbsoluteTimeGetCurrent() - start
    logger.info("操作耗时：\(String(format: "%.3f", duration))秒")
    return result
}

// 使用
let result = measure {
    try await service.transcribe()
}
```

**技巧 2：内存监控**
```swift
func logMemory(_ label: String = "") {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        let memoryMB = Double(info.resident_size) / 1024.0 / 1024.0
        logger.info("[\(label)] 内存：\(String(format: "%.2f", memoryMB)) MB")
    }
}
```

---

## 7. 联系支持

如果以上方案都无法解决问题，请收集以下信息并联系开发团队：

### 7.1 必需信息

- [ ] 应用版本
- [ ] macOS 版本
- [ ] 设备型号（M1/M2/M3）
- [ ] 问题复现步骤
- [ ] 错误日志
- [ ] 截图/录屏（如适用）

### 7.2 日志收集

```bash
# 1. 导出应用日志
log show --predicate 'subsystem == "com.shenman"' --last 24h > shenman_log.txt

# 2. 导出崩溃报告
# 打开 ~/Library/Logs/DiagnosticReports/
# 找到 ShenMan 相关的崩溃报告

# 3. 系统信息
system_profiler SPHardwareDataType > system_info.txt
```

---

**文档版本**: v1.0  
**创建日期**: 2026-03-18  
**最后更新**: 2026-03-18  
**维护者**: ShenMan Team
