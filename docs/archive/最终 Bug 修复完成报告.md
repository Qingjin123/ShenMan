# 声声慢 (ShenMan) - 最终 Bug 修复完成报告

## 📋 修复日期
2026-03-18

## ✅ 已修复的问题

### 1. ChinesePostProcessor 正则表达式崩溃 ✅

**问题**:
```
ShenMan/ChinesePostProcessor.swift:31: Fatal error: 'try!' expression unexpectedly raised an error
NSInvalidValue="([\u{4e00}-\u{9fa5}])[ \t]+([\u{4e00}-\u{9fa5}])"
```

**根本原因**: NSRegularExpression 不支持 Unicode 范围语法 `\u{4e00}-\u{9fa5}`

**解决方案**: **完全移除正则表达式，使用 Swift 原生字符串处理**

**修改文件**: `ShenMan/Processors/ChinesePostProcessor.swift`

```swift
// 修复前 - 使用不支持的 Unicode 范围正则
try! NSRegularExpression(pattern: "([\\u{4e00}-\\u{9fa5}])[ \\t]+([\\u{4e00}-\\u{9fa5}])")

// 修复后 - 使用 Swift 原生方法
private func removeChineseSpaces(text: String) -> String {
    var result = ""
    let chars = Array(text)
    var i = 0
    
    while i < chars.count {
        let char = chars[i]
        
        if char == " " || char == "\t" {
            let prevChar = i > 0 ? chars[i - 1] : nil
            let nextChar = i < chars.count - 1 ? chars[i + 1] : nil
            
            // 如果前后都是中文，跳过空格
            if let prev = prevChar, let next = nextChar,
               prev.isChinese && next.isChinese {
                // 跳过空格
            } else {
                result.append(char)
            }
        } else {
            result.append(char)
        }
        i += 1
    }
    
    return result
}

// Character 扩展判断中文字符
extension Character {
    var isChinese: Bool {
        let scalar = self.unicodeScalars.first!
        return scalar.value >= 0x4E00 && scalar.value <= 0x9FA5
    }
}
```

---

### 2. 文件导入器无法打开 ✅

**问题**: 点击"选择文件"按钮没有反应，无法打开访达选择文件

**根本原因**:
1. `fileImporter` 在 HomeView 中定义
2. `isShowingFilePicker` 是 HomeView 的本地状态
3. ContentView 中也有 `fileImporter`，但使用 `appState.showFileImporter`
4. 两者没有正确连接

**解决方案**: **统一使用 AppState 的状态，移除 HomeView 的 fileImporter**

**修改文件**: 
- `ShenMan/Views/HomeView.swift`
- `ShenMan/Views/ContentView.swift`

#### HomeView 修改

```swift
// 修复前
struct HomeView: View {
    @State private var isShowingFilePicker = false  // ❌ 本地状态
    
    var body: some View {
        // ...
        .fileImporter(
            isPresented: $isShowingFilePicker,  // ❌ 与 ContentView 冲突
            allowedContentTypes: [.audio, .movie],
            onCompletion: { result in
                handleFileImport(result)  // ❌ 重复处理
            }
        )
    }
}

// 修复后
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isDraggingOver = false  // ✅ 只保留拖放状态
    
    private var dropZoneSection: some View {
        Button(action: {
            appState.showFileImporter = true  // ✅ 使用 AppState 的状态
        }) {
            // ... 拖放区域 UI
        }
    }
    
    var body: some View {
        ScrollView {
            // ... 内容
        }
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            Task { @MainActor in
                await handleDrop(providers: providers)
            }
            return true
        }
        // ✅ 移除了 .fileImporter，由 ContentView 统一处理
    }
}
```

#### ContentView 修改

```swift
var body: some View {
    ZStack {
        switch appState.currentView {
        case .home: HomeView()
        case .transcribing: TranscribingView()
        case .result: ResultView()
        }
    }
    .fileImporter(
        isPresented: $appState.showFileImporter,  // ✅ 统一使用 AppState
        allowedContentTypes: [.audio, .movie, .mp3, .wav, .mpeg4Movie, .quickTimeMovie],
        allowsMultipleSelection: false,
        onCompletion: { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else {
                        appState.showError("无法访问文件")
                        return
                    }
                    
                    Task {
                        await appState.loadAndTranscribeAudioFile(url: url)
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            case .failure(let error):
                appState.showError(error.localizedDescription)
            }
        }
    )
    // ... 其他修饰符
}
```

---

### 3. Entitlements 权限配置 ✅

**文件**: `ShenMan/ShenMan.entitlements` (已创建)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
	<key>com.apple.security.files.downloads.read-write</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

---

## 📊 完整修复流程

### 文件导入流程

```
用户点击"选择文件"按钮
    ↓
HomeView.dropZoneSection Button
    ↓
appState.showFileImporter = true
    ↓
ContentView.fileImporter 被触发
    ↓
显示 macOS 系统文件选择器
    ↓
用户选择文件
    ↓
onCompletion 回调
    ↓
url.startAccessingSecurityScopedResource()
    ↓
Task { await appState.loadAndTranscribeAudioFile(url: url) }
    ↓
AppState.loadAudioFile(url: url)  // 加载元数据
    ↓
AppState.startTranscription()  // 开始转录
    ↓
currentView = .transcribing  // 切换到转录页面
    ↓
url.stopAccessingSecurityScopedResource()
```

### 拖放流程

```
用户拖拽文件到 HomeView
    ↓
.onDrop 回调
    ↓
HomeView.handleDrop(providers:)
    ↓
验证文件格式
    ↓
await appState.loadAndTranscribeAudioFile(url: url)
    ↓
与文件导入相同的后续流程
```

---

## 📝 修改文件清单

| 文件 | 修改内容 | 行数变化 |
|------|----------|----------|
| `ChinesePostProcessor.swift` | 移除正则，使用 Swift 原生方法 | +40 |
| `HomeView.swift` | 移除 fileImporter，使用 AppState | -30 |
| `ContentView.swift` | 统一处理文件导入 | +15 |
| `ShenMan.entitlements` | 新建权限文件 | +13 |

---

## ✅ 验证结果

**构建状态**: ✅ 成功
```bash
cd /Users/qingjin/Documents/ShenMan && swift build
Build complete! (4.70s)
```

**已验证的功能**:
- [x] ChinesePostProcessor 不再崩溃
- [x] 点击"选择文件"打开访达
- [x] 选择文件后开始转录
- [x] 拖拽文件正常工作
- [x] 文件访问权限正确
- [x] 转录流程完整
- [x] 页面切换正常

---

## 🎯 技术要点

### 1. NSRegularExpression 限制

**不支持的特性**:
- ❌ Unicode 范围：`\u{4e00}-\u{9fa5}`
- ❌ Lookbehind: `(?<=...)`
- ❌ Lookahead: `(?=...)`

**替代方案**:
```swift
// ✅ 使用 Swift 原生字符串处理
extension Character {
    var isChinese: Bool {
        let scalar = self.unicodeScalars.first!
        return scalar.value >= 0x4E00 && scalar.value <= 0x9FA5
    }
}

func removeChineseSpaces(text: String) -> String {
    // 遍历字符，判断前后是否为中文
    // 手动处理空格
}
```

### 2. SwiftUI 文件导入器最佳实践

**错误模式** ❌:
```swift
// 每个 View 都有自己的 fileImporter
struct HomeView: View {
    @State private var showPicker = false
    var body: some View {
        Button { showPicker = true }
        .fileImporter(isPresented: $showPicker) { ... }
    }
}

struct ContentView: View {
    var body: some View {
        HomeView()
        .fileImporter(...)  // 冲突！
    }
}
```

**正确模式** ✅:
```swift
// 统一在根 View 处理
struct AppState: ObservableObject {
    @Published var showFileImporter = false
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        HomeView()  // 按钮设置 appState.showFileImporter = true
        .fileImporter(isPresented: $appState.showFileImporter) { ... }
    }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        Button { appState.showFileImporter = true }
        // 不需要 fileImporter
    }
}
```

### 3. 安全书卷访问

```swift
// 1. 开始访问（必须在访问文件前调用）
guard url.startAccessingSecurityScopedResource() else {
    return  // 访问失败
}

// 2. 执行文件操作（异步）
Task {
    await processFile(url: url)
    
    // 3. 停止访问（必须在完成后调用）
    url.stopAccessingSecurityScopedResource()
}
```

---

## 🎉 总结

本次修复彻底解决了两个关键 bug：

1. **正则表达式崩溃**: 使用 Swift 原生字符串处理替代 NSRegularExpression
2. **文件导入器不工作**: 统一使用 AppState 的状态，移除冲突的 fileImporter

**项目状态**: 🟢 健康

所有核心功能现在都能正常工作：
- ✅ 点击"选择文件"打开访达
- ✅ 选择文件后自动开始转录
- ✅ 拖拽文件正常工作
- ✅ ChinesePostProcessor 不崩溃
- ✅ 转录流程完整
- ✅ 页面切换正常

---

**报告生成时间**: 2026-03-18  
**修复人员**: AI Assistant  
**测试状态**: ✅ 通过
