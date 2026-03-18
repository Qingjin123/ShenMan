# 声声慢 (ShenMan) - UI/UX 响应测试方案

## 📋 测试目标

验证前端 UI/UX 的响应性、交互流畅度和用户操作反馈是否符合 UI_UX_Design_v2.md 的设计规范。

---

## 🧪 测试环境

### 硬件要求
- **设备**: MacBook Pro / MacBook Air (Apple Silicon)
- **内存**: 最低 8GB，推荐 16GB+
- **存储**: 至少 5GB 可用空间

### 软件要求
- **macOS**: 14.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

---

## 🎯 测试类别

### 1. 布局响应测试

#### 1.1 窗口大小调整
```swift
// 测试脚本
func testWindowResize() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 获取主窗口
    let window = app.windows.firstMatch
    
    // 测试最小尺寸 (400x300)
    window.resize(to: CGSize(width: 400, height: 300))
    sleep(1)
    assert(app.staticTexts["声声慢"].exists)
    
    // 测试中等尺寸 (800x600)
    window.resize(to: CGSize(width: 800, height: 600))
    sleep(1)
    assert(app.staticTexts["声声慢"].exists)
    
    // 测试最大尺寸
    window.resize(to: CGSize(width: 1200, height: 800))
    sleep(1)
    assert(app.staticTexts["声声慢"].exists)
}
```

**验收标准**:
- [ ] 窗口调整时 UI 不闪烁
- [ ] 内容区域自适应填充
- [ ] 侧边栏可折叠（宽度 < 600pt 时自动折叠）
- [ ] 文字不换行溢出

#### 1.2 侧边栏折叠测试
```swift
func testSidebarCollapse() async throws {
    let app = XCUIApplication()
    app.launch()
    
    let window = app.windows.firstMatch
    let sidebar = app.groups["SidebarView"]
    
    // 展开状态
    assert(sidebar.exists)
    assert(sidebar.frame.width == 200)
    
    // 缩小窗口
    window.resize(to: CGSize(width: 500, height: 600))
    sleep(1)
    
    // 侧边栏应该折叠
    assert(sidebar.frame.width == 0 || !sidebar.isVisible)
}
```

---

### 2. 交互响应测试

#### 2.1 拖放文件响应
```swift
func testFileDropResponse() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 准备测试文件
    let testFile = URL(fileURLWithPath: "/path/to/test.mp3")
    
    // 拖放区域
    let dropZone = app.otherElements["DropZoneView"]
    
    // 模拟拖入
    dropZone.hover()
    sleep(0.2)
    
    // 验证高亮状态
    assert(dropZone.backgroundColor == .accentColor.opacity(0.1))
    
    // 释放文件
    dropZone.drop(testFile)
    sleep(0.5)
    
    // 验证文件加载
    assert(app.staticTexts["test.mp3"].exists)
}
```

**验收标准**:
- [ ] 拖入时立即显示高亮（< 100ms）
- [ ] 释放后显示文件信息（< 500ms）
- [ ] 不支持格式显示错误提示

#### 2.2 按钮点击反馈
```swift
func testButtonClickFeedback() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 开始转录按钮
    let startButton = app.buttons["开始转录"]
    
    // 记录点击前时间
    let startTime = CACurrentMediaTime()
    
    // 点击按钮
    startButton.tap()
    
    // 验证按钮状态变化
    sleep(0.1)
    assert(startButton.isEnabled == false)
    assert(app.progressIndicators.firstMatch.exists)
    
    // 验证响应时间 < 200ms
    let responseTime = CACurrentMediaTime() - startTime
    assert(responseTime < 0.2)
}
```

---

### 3. 动画流畅度测试

#### 3.1 页面切换动画
```swift
func testPageTransitionAnimation() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 从主页切换到转录页面
    let startButton = app.buttons["开始转录"]
    startButton.tap()
    
    // 记录动画帧率
    let fpsRecorder = FPSRecorder()
    fpsRecorder.start()
    
    // 等待页面切换完成
    waitForElementToAppear(app.staticTexts["正在转录"])
    
    fpsRecorder.stop()
    
    // 验证平均帧率 > 50fps
    assert(fpsRecorder.averageFPS > 50)
    
    // 验证无卡顿（最低帧率 > 30fps）
    assert(fpsRecorder.minimumFPS > 30)
}
```

**验收标准**:
- [ ] 页面切换动画流畅（60fps）
- [ ] 无可见闪烁
- [ ] 过渡时间 < 300ms

#### 3.2 进度条动画
```swift
func testProgressBarAnimation() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 开始转录
    app.buttons["开始转录"].tap()
    
    // 等待进度条出现
    let progressBar = app.progressIndicators.firstMatch
    waitForElementToAppear(progressBar)
    
    // 记录进度更新
    var progressValues: [Double] = []
    var timestamps: [TimeInterval] = []
    
    for _ in 0..<10 {
        progressValues.append(progressBar.value as? Double ?? 0)
        timestamps.append(CACurrentMediaTime())
        sleep(0.5)
    }
    
    // 验证进度递增
    for i in 1..<progressValues.count {
        assert(progressValues[i] >= progressValues[i-1])
    }
    
    // 验证更新频率（每 500ms 至少更新一次）
    for i in 1..<timestamps.count {
        assert(timestamps[i] - timestamps[i-1] <= 0.6)
    }
}
```

---

### 4. 状态同步测试

#### 4.1 转录状态同步
```swift
func testTranscriptionStateSync() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 开始转录
    app.buttons["开始转录"].tap()
    
    // 验证 UI 状态
    assert(app.staticTexts["正在转录"].exists)
    assert(app.buttons["取消转录"].exists)
    
    // 等待完成
    waitForElementToDisappear(app.progressIndicators.firstMatch)
    
    // 验证结果页面
    assert(app.staticTexts["转录完成"].exists)
    assert(app.buttons["导出"].exists)
}
```

**验收标准**:
- [ ] 状态切换无延迟
- [ ] 进度条与实际进度一致
- [ ] 错误状态正确显示

#### 4.2 编辑状态保存
```swift
func testEditStateSave() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 打开历史记录
    app.buttons["历史记录"].tap()
    
    // 选择一条记录
    app.tables.firstMatch.cells.firstMatch.tap()
    
    // 点击编辑
    app.buttons["编辑"].tap()
    
    // 修改文本
    let textView = app.textViews.firstMatch
    let originalText = textView.value as? String
    textView.typeText(" 测试修改")
    
    // 保存
    app.buttons["保存"].tap()
    
    // 重新打开验证
    app.buttons["返回"].tap()
    app.tables.firstMatch.cells.firstMatch.tap()
    
    let newText = textView.value as? String
    assert(newText == originalText + " 测试修改")
}
```

---

### 5. 性能测试

#### 5.1 内存使用测试
```swift
func testMemoryUsage() async throws {
    let app = XCUIApplication()
    let monitor = XCMemoryMonitor(app: app)
    monitor.startMonitoring()
    
    app.launch()
    
    // 加载大文件（30 分钟音频）
    let largeFile = URL(fileURLWithPath: "/path/to/large.mp3")
    app.windows.firstMatch.drop(largeFile)
    
    // 等待转录完成
    waitForTranscriptionComplete()
    
    monitor.stopMonitoring()
    
    // 验证内存峰值 < 2GB
    assert(monitor.peakMemoryUsage < 2 * 1024 * 1024 * 1024)
    
    // 验证无内存泄漏
    sleep(5)
    assert(monitor.currentMemoryUsage < monitor.peakMemoryUsage * 1.1)
}
```

**验收标准**:
- [ ] 短音频（5 分钟）内存 < 500MB
- [ ] 长音频（30 分钟）内存 < 2GB
- [ ] 无内存泄漏

#### 5.2 启动时间测试
```swift
func testLaunchTime() async throws {
    let app = XCUIApplication()
    
    let startTime = CACurrentMediaTime()
    app.launch()
    
    // 等待主页出现
    waitForElementToAppear(app.staticTexts["声声慢"])
    
    let launchTime = CACurrentMediaTime() - startTime
    
    // 验证冷启动 < 2 秒
    assert(launchTime < 2.0)
}
```

---

### 6. 可访问性测试

#### 6.1 VoiceOver 支持
```swift
func testVoiceOverSupport() async throws {
    let app = XCUIApplication()
    app.launch()
    
    // 启用 VoiceOver
    XCUIAccessibility.shared.voiceOverEnabled = true
    
    // 验证关键元素有标签
    let dropZone = app.otherElements["DropZoneView"]
    assert(dropZone.label == "拖放音频文件到此处")
    
    let startButton = app.buttons["开始转录"]
    assert(startButton.label == "开始转录")
    
    // 验证进度条有值
    let progressBar = app.progressIndicators.firstMatch
    assert(progressBar.value != nil)
}
```

**验收标准**:
- [ ] 所有按钮有明确标签
- [ ] 进度条可读
- [ ] 错误提示可朗读

---

## 📊 测试结果记录表

### 测试执行记录

| 测试项 | 测试日期 | 测试结果 | 备注 |
|--------|----------|----------|------|
| 窗口大小调整 | | ⬜ 通过 ⬜ 失败 | |
| 侧边栏折叠 | | ⬜ 通过 ⬜ 失败 | |
| 拖放文件响应 | | ⬜ 通过 ⬜ 失败 | |
| 按钮点击反馈 | | ⬜ 通过 ⬜ 失败 | |
| 页面切换动画 | | ⬜ 通过 ⬜ 失败 | |
| 进度条动画 | | ⬜ 通过 ⬜ 失败 | |
| 转录状态同步 | | ⬜ 通过 ⬜ 失败 | |
| 编辑状态保存 | | ⬜ 通过 ⬜ 失败 | |
| 内存使用 | | ⬜ 通过 ⬜ 失败 | |
| 启动时间 | | ⬜ 通过 ⬜ 失败 | |
| VoiceOver 支持 | | ⬜ 通过 ⬜ 失败 | |

---

## 🛠️ 测试工具

### FPSRecorder.swift
```swift
import Foundation
import QuartzCore

class FPSRecorder {
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTime = CACurrentMediaTime()
    
    var averageFPS: Double = 0
    var minimumFPS: Double = 60
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateFPS() {
        frameCount += 1
        
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - lastTime
        
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            averageFPS = fps
            minimumFPS = min(minimumFPS, fps)
            
            frameCount = 0
            lastTime = currentTime
        }
    }
}
```

### XCMemoryMonitor.swift
```swift
import XCTest

class XCMemoryMonitor {
    private let app: XCUIApplication
    private var snapshots: [XCUIAppProcessMemorySnapshot] = []
    
    var peakMemoryUsage: Int64 = 0
    var currentMemoryUsage: Int64 = 0
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func startMonitoring() {
        snapshots = []
    }
    
    func stopMonitoring() {
        // 计算峰值和当前内存
        for snapshot in snapshots {
            let usage = snapshot.residentSize
            if usage > peakMemoryUsage {
                peakMemoryUsage = usage
            }
        }
        currentMemoryUsage = snapshots.last?.residentSize ?? 0
    }
    
    func captureSnapshot() {
        if let snapshot = try? app.processMemorySnapshot() {
            snapshots.append(snapshot)
        }
    }
}
```

---

## 🚀 自动化测试脚本

### run_ui_tests.sh
```bash
#!/bin/bash

# 声声慢 UI 测试脚本

set -e

echo "🎯 开始 UI 响应测试..."

# 1. 构建项目
echo "📦 构建项目..."
xcodebuild -project ShenMan.xcodeproj \
           -scheme ShenMan \
           -destination 'platform=macOS' \
           build

# 2. 运行 UI 测试
echo "🧪 运行 UI 测试..."
xcodebuild test \
           -project ShenMan.xcodeproj \
           -scheme ShenMan \
           -destination 'platform=macOS' \
           -only-testing:ShenManTests/UITests

# 3. 生成测试报告
echo "📊 生成测试报告..."
xcresulttool merge \
    --output UI_Tests.xcresult \
    $(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d | head -n 1)

echo "✅ 测试完成！"
```

---

## 📈 性能基准

### 响应时间基准

| 操作 | 目标响应时间 | 可接受范围 |
|------|-------------|-----------|
| 应用启动 | < 2s | < 3s |
| 页面切换 | < 300ms | < 500ms |
| 按钮点击反馈 | < 200ms | < 300ms |
| 拖放高亮 | < 100ms | < 200ms |
| 进度更新 | < 500ms | < 1s |
| 编辑保存 | < 500ms | < 1s |

### 帧率基准

| 场景 | 目标帧率 | 最低帧率 |
|------|---------|---------|
| 页面切换 | 60fps | 50fps |
| 列表滚动 | 60fps | 50fps |
| 进度动画 | 60fps | 50fps |
| 窗口调整 | 60fps | 40fps |

---

## 🐛 问题追踪模板

### UI 响应问题报告

```markdown
## 问题描述
[简要描述问题]

## 复现步骤
1. 
2. 
3. 

## 预期行为
[应该发生什么]

## 实际行为
[实际发生了什么]

## 性能数据
- 响应时间：ms
- 帧率：fps
- 内存使用：MB

## 截图/录屏
[附加截图或录屏]

## 环境
- macOS 版本：
- 设备型号：
- 应用版本：
```

---

**文档版本**: v1.0
**创建日期**: 2026-03-18
**更新**: 初始版本
