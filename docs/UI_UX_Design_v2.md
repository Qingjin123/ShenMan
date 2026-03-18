# 声声慢 (ShenMan) - UI/UX 设计文档 v2

## 📖 文档概述

**版本**：v2.0（重新设计）  
**创建日期**：2026-03-19  
**设计风格**：macOS 26 原生 + 适度 Liquid Glass  
**设计参考**：Arc Browser、Raycast  
**核心原则**：功能 > 设计，适度美化，内容优先

---

## 🎯 设计理念

### 核心原则

```
1. 功能优先 (Function First)
   └─ UI 为功能服务，不为了美观牺牲可用性

2. 原生质感 (Native Feel)
   └─ 使用标准 SwiftUI 组件，符合 macOS 习惯

3. 适度玻璃 (Subtle Glass)
   └─ 仅在侧边栏、工具栏使用 Liquid Glass

4. 内容清晰 (Content Clarity)
   └─ 文字可读性第一，背景不干扰内容

5. 快速响应 (Fast Response)
   └─ 像 Raycast 一样快速、流畅
```

### 设计灵感

#### Arc Browser 的借鉴
```
✅ 侧边栏导航（可折叠）
✅ 内容区域最大化
✅ 适度透明材质
✅ 清晰的视觉层次
✅ 标签式管理（未来扩展）
```

#### Raycast 的借鉴
```
✅ 命令面板式交互
✅ 键盘快捷键优先
✅ 搜索结果即时显示
✅ 深色模式优秀
✅ 功能丰富但不杂乱
```

---

## 🌈 色彩系统（简化版）

### 主色

```swift
// 声声慢品牌色 - 黛蓝（适度使用）
struct ShenManColors {
    // 主色 - 仅用于强调和状态
    static let primary = Color(red: 0.25, green: 0.35, blue: 0.65)
    
    // 强调色 - 少量点缀
    static let accent = Color(red: 0.30, green: 0.55, blue: 0.55)
    
    // 成功/警告/错误
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
}
```

### 中性色（使用系统色）

```swift
// 优先使用系统颜色，自动适配亮色/暗色模式
struct SystemColors {
    // 背景
    static let background = Color.background          // 系统背景
    static let backgroundSecondary = Color.secondaryBackground
    static let backgroundTertiary = Color.tertiaryBackground
    
    // 表面
    static let surface = Color.backgroundSurface
    static let surfaceElevated = Color.backgroundSurfaceElevated
    
    // 文字
    static let textPrimary = Color.primaryLabel       // 系统主文字色
    static let textSecondary = Color.secondaryLabel
    static let textTertiary = Color.tertiaryLabel
    
    // 边框
    static let border = Color.separator.opacity(0.5)
    static let borderStrong = Color.separator
}
```

### Liquid Glass 材质（适度使用）

```swift
// 仅在特定区域使用玻璃材质
struct GlassMaterials {
    // 侧边栏 - ultraThinMaterial
    static let sidebar = Color.clear
        .background(.ultraThinMaterial)
    
    // 工具栏 - ultraThinMaterial
    static let toolbar = Color.clear
        .background(.ultraThinMaterial)
    
    // 卡片 - 不用玻璃，用纯色 + 阴影
    static let card = Color.backgroundSecondary
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    
    // 弹窗 - thickMaterial
    static let popover = Color.clear
        .background(.thickMaterial)
}
```

**关键决策**：
- ✅ 侧边栏：使用玻璃材质
- ✅ 工具栏：使用玻璃材质
- ❌ 卡片：纯色背景 + 轻微阴影（保证可读性）
- ❌ 内容区：纯色背景（不干扰文字）

---

## 📐 布局系统

### 间距规范（基于 8pt）

```swift
struct Spacing {
    static let xs: CGFloat = 4      // 超小
    static let sm: CGFloat = 8      // 小
    static let md: CGFloat = 16     // 中
    static let lg: CGFloat = 24     // 大
    static let xl: CGFloat = 32     // 超大
    static let xxl: CGFloat = 48    // 巨大
}
```

### 圆角规范

```swift
struct CornerRadius {
    static let sm: CGFloat = 6      // 小组件
    static let md: CGFloat = 10     // 按钮、输入框
    static let lg: CGFloat = 14     // 卡片
    static let xl: CGFloat = 18     // 大容器
}
```

### 字体系统（使用系统字体）

```swift
// 优先使用系统字体，自动适配用户设置
struct Typography {
    // 标题
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    
    // 正文
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    // 等宽（时间戳）
    static let monospaced = Font.monospacedDigitSystem
}
```

---

## 🏗️ 应用架构

### 整体布局

```
┌─────────────────────────────────────────────────────────────┐
│  菜单栏 (系统原生)                                           │
│  文件  编辑  视图  窗口  帮助                                │
├─────────────────────────────────────────────────────────────┤
│  工具栏 (玻璃材质)                                           │
│  [←] [→]  [🔍 搜索]                      [⚙️] [+]          │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                  │
│  侧边栏   │              主内容区                             │
│  (玻璃)   │              (纯色背景)                          │
│          │                                                  │
│  • 主页   │  ┌────────────────────────────────────────┐    │
│  • 历史   │  │                                        │    │
│  • 设置   │  │         拖放区域                        │    │
│          │  │                                        │    │
│  最近     │  └────────────────────────────────────────┘    │
│  • 会议   │                                                  │
│  • 课程   │  最近文件                                        │
│  • 访谈   │  • 会议记录.mp3                    2 小时前      │
│          │  • 课程 01.mp4                     昨天          │
│          │  • 访谈张三.m4a                    3 天前         │
│          │                                                  │
└──────────┴──────────────────────────────────────────────────┘
     200px                    可调整
```

### 页面结构

```
应用采用三栏布局：

1. 工具栏 (Toolbar)
   - 高度：44pt（系统标准）
   - 材质：.ultraThinMaterial
   - 内容：导航按钮、搜索、操作按钮

2. 侧边栏 (Sidebar)
   - 宽度：200pt（可折叠）
   - 材质：.ultraThinMaterial
   - 内容：导航、历史记录

3. 主内容区 (Main Content)
   - 宽度：自适应
   - 背景：纯色（系统背景色）
   - 内容：核心功能区域
```

---

## 📱 页面详细设计

### 1. 主页 (HomeView)

#### 布局

```
┌─────────────────────────────────────────────────────────┐
│  声声慢                                    [⚙️] [+]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                                                         │
│              让声音慢下来，沉淀为文字                     │
│                                                         │
│                                                         │
│    ┌───────────────────────────────────────────────┐   │
│    │                                               │   │
│    │                                               │   │
│    │              📁                               │   │
│    │                                               │   │
│    │          拖放音频文件到此处                    │   │
│    │              或点击选择                        │   │
│    │                                               │   │
│    │     MP3 · WAV · M4A · FLAC · MP4 · MOV       │   │
│    │                                               │   │
│    └───────────────────────────────────────────────┘   │
│                                                         │
│                                                         │
│  最近文件                                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 📄 会议记录.mp3           02:35:18    2 小时前   │   │
│  │ 📄 课程 01.mp4             01:45:30    昨天      │   │
│  │ 📄 访谈张三.m4a            00:58:12    3 天前    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 代码实现

```swift
import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) var appState
    @State private var isDraggingOver = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: .xl) {
                // 标题区域
                titleSection
                
                // 拖放区域
                dropZoneSection
                
                // 最近文件
                recentFilesSection
            }
            .padding(.xl)
            .frame(maxWidth: 700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - 标题区域
    
    private var titleSection: some View {
        VStack(spacing: .sm) {
            Text("声声慢")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("让声音慢下来，沉淀为文字")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, .xxl)
    }
    
    // MARK: - 拖放区域
    
    private var dropZoneSection: some View {
        Button(action: {
            // 打开文件选择器
        }) {
            VStack(spacing: .md) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("拖放音频文件到此处")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("或点击选择")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("MP3 · WAV · M4A · FLAC · MP4 · MOV")
                    .font(.caption)
                    .foregroundColor(.tertiaryLabel)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background(
                RoundedRectangle(cornerRadius: .lg)
                    .fill(isDraggingOver ? 
                          Color.accentColor.opacity(0.1) : 
                          Color.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .lg)
                    .stroke(
                        isDraggingOver ? 
                            Color.accentColor.opacity(0.5) : 
                            Color.border,
                        lineWidth: isDraggingOver ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
    }
    
    // MARK: - 最近文件
    
    private var recentFilesSection: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text("最近文件")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: .xs) {
                RecentFileRow(
                    filename: "会议记录.mp3",
                    duration: "02:35:18",
                    date: "2 小时前"
                )
                
                RecentFileRow(
                    filename: "课程 01.mp4",
                    duration: "01:45:30",
                    date: "昨天"
                )
                
                RecentFileRow(
                    filename: "访谈张三.m4a",
                    duration: "00:58:12",
                    date: "3 天前"
                )
            }
        }
    }
}

// MARK: - 最近文件行

struct RecentFileRow: View {
    let filename: String
    let duration: String
    let date: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(filename)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(duration)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
            
            Text(date)
                .font(.caption)
                .foregroundColor(.tertiaryLabel)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.sm)
        .background(Color.background)
        .cornerRadius(.md)
        .contentShape(Rectangle())
    }
}
```

---

### 2. 转录中页面 (TranscribingView)

#### 布局

```
┌─────────────────────────────────────────────────────────┐
│  ← 取消                              正在转录...         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📄 会议记录.mp3                                │   │
│  │  MP3 · 02:35:18 · 256 MB                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│                                                         │
│                    65%                                  │
│         ╭──────────────────────────────╮               │
│         │████████████████░░░░░░░░░░░░░░│               │
│         ╰──────────────────────────────╯               │
│                                                         │
│              已处理 1 小时 42 分 / 共 2 小时 35 分         │
│              预计剩余：8 分钟                            │
│                                                         │
│              正在优化标点...                            │
│                                                         │
│                                                         │
│                    ┌─────────┐                         │
│                    │  取消   │                         │
│                    └─────────┘                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 代码实现

```swift
import SwiftUI

struct TranscribingView: View {
    @Environment(AppState.self) var appState
    @State private var progress: Double = 0.65
    @State private var statusMessage = "正在优化标点..."
    
    var body: some View {
        VStack(spacing: .xl) {
            // 文件信息卡片
            fileInfoCard
            
            Spacer()
            
            // 进度显示
            progressSection
            
            Spacer()
            
            // 取消按钮
            cancelButton
        }
        .padding(.xl)
        .frame(maxWidth: 500)
    }
    
    // MARK: - 文件信息
    
    private var fileInfoCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.accentColor)
                Text(appState.currentAudioFile?.filename ?? "未知文件")
                    .font(.title3)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: .md) {
                Label(appState.currentAudioFile?.format.displayName ?? "", 
                      systemImage: "music.note")
                Label(appState.currentAudioFile?.durationFormatted ?? "", 
                      systemImage: "clock")
                Label(appState.currentAudioFile?.fileSizeFormatted ?? "", 
                      systemImage: "doc.badge.gearshape")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryBackground)
        .cornerRadius(.lg)
    }
    
    // MARK: - 进度显示
    
    private var progressSection: some View {
        VStack(spacing: .md) {
            // 百分比
            Text("\(Int(progress * 100))%")
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()
            
            // 进度条
            ProgressView(value: progress)
                .scaleEffect(y: 1.5)
                .frame(maxWidth: .infinity)
            
            // 详细信息
            VStack(spacing: .xs) {
                Text("已处理 1 小时 42 分 / 共 2 小时 35 分")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("预计剩余：8 分钟")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 状态消息
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.accentColor)
                .padding(.top, .sm)
        }
    }
    
    // MARK: - 取消按钮
    
    private var cancelButton: some View {
        Button("取消转录") {
            appState.cancelTranscription()
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
    }
}
```

---

### 3. 结果页面 (ResultView)

#### 布局

```
┌─────────────────────────────────────────────────────────────────────┐
│  ← 返回    会议记录.mp3                          [导出] [⚙️]        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  统计信息                                                    │   │
│  │  总时长：2:35:18    总句数：1,245    处理时间：45 秒         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  转录内容                                                           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                                                              │   │
│  │  [00:00:01.2]  今天我们讨论一下新产品的发布计划              │   │
│  │                                                              │   │
│  │  [00:00:06.1]  好的，我觉得我们可以先从市场调研开始          │   │
│  │                                                              │   │
│  │  [00:00:12.8]  我同意，我已经联系了几家调研公司              │   │
│  │                                                              │   │
│  │  [00:00:18.5]  那太好了，我们下周可以安排一次会议            │   │
│  │                                                              │   │
│  │  [00:00:24.2]  没问题，我会准备好相关的资料                  │   │
│  │                                                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### 代码实现

```swift
import SwiftUI

struct ResultView: View {
    @Environment(AppState.self) var appState
    @State private var selectedSentence: SentenceTimestamp?
    @State private var isShowingExportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 统计信息卡片
            statsCard
            
            Divider()
            
            // 转录内容列表
            transcriptionList
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("导出") {
                    isShowingExportSheet = true
                }
                
                Button(action: {}) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $isShowingExportSheet) {
            ExportSheet(result: appState.latestResult)
        }
    }
    
    // MARK: - 统计卡片
    
    private var statsCard: some View {
        HStack(spacing: .xl) {
            StatItem(
                label: "总时长",
                value: appState.latestResult?.audioFile.durationFormatted ?? "-"
            )
            
            StatItem(
                label: "总句数",
                value: appState.latestResult?.sentences.count.formatted() ?? "-"
            )
            
            StatItem(
                label: "处理时间",
                value: String(format: "%.1f 秒", 
                             appState.latestResult?.processingTime ?? 0)
            )
            
            Spacer()
        }
        .padding(.md)
        .background(Color.secondaryBackground)
        .cornerRadius(.lg)
        .padding(.md)
    }
    
    // MARK: - 转录列表
    
    private var transcriptionList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .sm) {
                ForEach(appState.latestResult?.sentences ?? []) { sentence in
                    TranscriptionRow(
                        sentence: sentence,
                        isSelected: selectedSentence?.id == sentence.id
                    )
                    .onTapGesture {
                        selectedSentence = sentence
                    }
                    .contextMenu {
                        ContextMenuItems(sentence: sentence)
                    }
                }
            }
            .padding(.md)
        }
    }
}

// MARK: - 统计项

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: .xs) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

// MARK: - 转录行

struct TranscriptionRow: View {
    let sentence: SentenceTimestamp
    let isSelected: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: .md) {
            // 时间戳
            Text(formatTime(sentence.startTime))
                .font(.caption)
                .foregroundColor(.accentColor)
                .monospacedDigit()
                .frame(width: 90, alignment: .trailing)
            
            // 文本
            Text(sentence.text)
                .font(.body)
                .lineSpacing(4)
            
            Spacer()
        }
        .padding(.md)
        .background(
            RoundedRectangle(cornerRadius: .md)
                .fill(isSelected ? 
                      Color.accentColor.opacity(0.1) : 
                      isHovering ? 
                      Color.secondaryBackground : 
                      Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .md)
                .stroke(
                    isSelected ? 
                        Color.accentColor.opacity(0.3) : 
                        Color.clear,
                    lineWidth: 1.5
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contentShape(Rectangle())
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
}
```

---

### 4. 侧边栏 (SidebarView)

#### 布局

```
┌─────────────────────┐
│                     │
│  声声慢             │
│                     │
│  ─────────────────  │
│                     │
│  🏠 主页            │
│  📋 历史记录        │
│  ⚙️ 设置            │
│                     │
│  ─────────────────  │
│                     │
│  最近               │
│  • 会议 (12)        │
│  • 课程 (8)         │
│  • 访谈 (5)         │
│                     │
└─────────────────────┘
```

#### 代码实现

```swift
import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab: AppView = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // 应用标题
            appTitle
            
            Divider()
            
            // 主导航
            mainNavigation
            
            Divider()
            
            // 最近分类
            recentCategories
            
            Spacer()
        }
        .padding(.sm)
        .frame(width: 200)
        // 侧边栏使用玻璃材质
        .background(.ultraThinMaterial)
    }
    
    // MARK: - 应用标题
    
    private var appTitle: some View {
        VStack(spacing: .xs) {
            Text("声声慢")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("ShenMan")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, .md)
    }
    
    // MARK: - 主导航
    
    private var mainNavigation: some View {
        VStack(alignment: .leading, spacing: .xs) {
            SidebarNavItem(
                icon: "house.fill",
                title: "主页",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
                appState.currentView = .home
            }
            
            SidebarNavItem(
                icon: "list.bullet",
                title: "历史记录",
                isSelected: selectedTab == .history
            ) {
                selectedTab = .history
            }
            
            SidebarNavItem(
                icon: "gear",
                title: "设置",
                isSelected: selectedTab == .settings
            ) {
                selectedTab = .settings
            }
        }
        .padding(.vertical, .sm)
    }
    
    // MARK: - 最近分类
    
    private var recentCategories: some View {
        VStack(alignment: .leading, spacing: .xs) {
            Text("最近")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, .sm)
            
            SidebarCategoryItem(title: "会议", count: 12)
            SidebarCategoryItem(title: "课程", count: 8)
            SidebarCategoryItem(title: "访谈", count: 5)
        }
        .padding(.top, .sm)
    }
}

// MARK: - 侧边栏导航项

struct SidebarNavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                Image(systemName: icon)
                    .frame(width: 16)
                
                Text(title)
                    .font(.subheadline)
                
                Spacer()
            }
            .padding(.horizontal, .sm)
            .padding(.vertical, .xs)
            .background(
                RoundedRectangle(cornerRadius: .sm)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 侧边栏分类项

struct SidebarCategoryItem: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text("• \(title)")
                .font(.subheadline)
            
            Spacer()
            
            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, .sm)
        .padding(.vertical, .xs)
    }
}
```

---

## 🎭 交互动画

### 原则

```
1. 快速响应 (< 200ms)
2. 符合物理直觉
3. 不干扰内容
4. 适度使用
```

### 页面过渡

```swift
// 使用系统默认过渡（最自然）
.transition(.opacity)

// 或轻微滑动
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### 按钮反馈

```swift
// 使用系统按钮样式
Button("点击") {
    // 操作
}
.buttonStyle(.bordered)

// 或自定义
Button("点击") {
    // 操作
}
.buttonStyle(.plain)
.scaleEffect(isPressed ? 0.98 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)
```

---

## ⌨️ 键盘快捷键

### 全局快捷键

```swift
// 参考 Raycast 的键盘优先设计
struct KeyboardShortcuts {
    // 文件
    static let newTranscription = KeyboardShortcut("n", modifiers: .command)
    static let openFile = KeyboardShortcut("o", modifiers: .command)
    
    // 编辑
    static let copy = KeyboardShortcut("c", modifiers: .command)
    static let selectAll = KeyboardShortcut("a", modifiers: .command)
    
    // 视图
    static let toggleSidebar = KeyboardShortcut("s", modifiers: .command)
    static let search = KeyboardShortcut("f", modifiers: .command)
    
    // 操作
    static let export = KeyboardShortcut("e", modifiers: .command)
    static let settings = KeyboardShortcut(",", modifiers: .command)
    
    // 导航
    static let goBack = KeyboardShortcut("[", modifiers: .command)
    static let goForward = KeyboardShortcut("]", modifiers: .command)
}
```

---

## 🌙 暗色模式

### 自动适配

```swift
// 使用系统颜色，自动适配暗色模式
var body: some View {
    VStack {
        // 内容
    }
    .background(Color.background)  // 自动适配
    .foregroundColor(.primary)     // 自动适配
}
```

### 暗色模式优化

```
暗色模式要点：
✅ 使用系统颜色（自动适配）
✅ 避免纯黑（用深灰色）
✅ 降低对比度（保护眼睛）
✅ 测试玻璃材质效果
```

---

## ♿ 无障碍支持

### VoiceOver

```swift
// 完整的无障碍标签
Button("导出") {
    // 操作
}
.accessibilityLabel("导出转录结果")
.accessibilityHint("双击打开导出对话框")
```

### 动态字体

```swift
// 支持系统字体大小调整
Text("内容")
    .font(.body)
    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
```

### 键盘导航

```swift
// 支持 Tab 键导航
TextField("搜索", text: $searchText)
    .keyboardShortcut(.defaultAction)
```

---

## 📊 设计验收标准

### 视觉验收

- [ ] 侧边栏玻璃材质清晰但不影响可读性
- [ ] 内容区域背景为纯色（无玻璃）
- [ ] 文字对比度符合 WCAG AA 标准
- [ ] 暗色模式所有页面正常显示
- [ ] 动画流畅（60fps）

### 功能验收

- [ ] 拖放操作流畅
- [ ] 进度显示准确
- [ ] 结果列表滚动流畅
- [ ] 键盘快捷键可用
- [ ] 导出功能正常

### 性能验收

- [ ] 首页加载 < 1 秒
- [ ] 列表滚动 60fps
- [ ] 内存占用 < 500MB（空闲）
- [ ] 大文件（1000+ 行）滚动流畅

---

## 🔮 未来扩展

### v2.0 功能预留

```
1. 标签式管理
   - 多文档标签
   - 标签切换动画

2. 说话人分离
   - 说话人标识
   - 颜色区分

3. 实时转录
   - 波形可视化
   - 实时滚动

4. 插件系统
   - 模型市场
   - 主题插件
```

---

## 📝 总结

### 设计特点

```
✅ 功能优先：UI 为功能服务
✅ 原生质感：使用系统组件
✅ 适度玻璃：仅侧边栏、工具栏
✅ 内容清晰：纯色背景保证可读性
✅ 快速响应：像 Raycast 一样流畅
```

### 与 v1 的区别

| 方面 | v1（旧版） | v2（新版） |
|------|-----------|-----------|
| 设计风格 | 过度设计 | 适度美化 |
| 玻璃材质 | 大面积使用 | 仅侧边栏/工具栏 |
| 背景 | 渐变 + 玻璃 | 纯色为主 |
| 组件 | 大量自定义 | 系统组件优先 |
| 开发成本 | 高 | 低 |
| 可读性 | 受影响 | 优先保证 |

---

**文档版本**：v2.0  
**创建日期**：2026-03-19  
**设计风格**：macOS 26 Native + Subtle Glass  
**参考应用**：Arc Browser, Raycast  
**核心原则**：功能 > 设计
