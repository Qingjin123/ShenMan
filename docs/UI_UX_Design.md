# 声声慢 (ShenMan) - UI/UX 设计文档

## 📖 文档概述

**版本**：v1.0  
**创建日期**：2026-03-19  
**设计风格**：macOS 26 (Sequoia) 液态玻璃风格  
**目标**：打造现代、优雅、易用的中文语音转文字工具

---

## 🎨 设计理念

### 核心设计原则

```
1. 液态通透 (Liquid Transparency)
   └─ 使用半透明材质、模糊效果，营造轻盈感

2. 层次分明 (Clear Hierarchy)
   └─ 通过深度、阴影、透明度建立视觉层次

3. 聚焦内容 (Content First)
   └─ UI 退居幕后，让音频和文字成为主角

4. 流畅自然 (Fluid Motion)
   └─ 优雅的动画过渡，符合物理直觉

5. 中文友好 (Chinese First)
   └─ 专为中文排版优化，字体、间距、标点
```

---

## 🌈 色彩系统

### 主色调

```swift
// 声声慢品牌色 - 灵感来自"水墨丹青"
struct ShenManColors {
    // 主色 - 黛蓝 (深邃的蓝紫色)
    static let primary = Color(red: 0.15, green: 0.25, blue: 0.55)
    static let primaryLight = Color(red: 0.35, green: 0.45, blue: 0.75)
    static let primaryDark = Color(red: 0.08, green: 0.15, blue: 0.35)
    
    // 辅助色 - 青瓷 (清新的青绿色)
    static let accent = Color(red: 0.25, green: 0.55, blue: 0.55)
    static let accentLight = Color(red: 0.45, green: 0.70, blue: 0.70)
    
    // 成功色 - 竹青
    static let success = Color(red: 0.25, green: 0.55, blue: 0.35)
    
    // 警告色 - 杏黄
    static let warning = Color(red: 0.85, green: 0.65, blue: 0.15)
    
    // 错误色 - 朱砂
    static let error = Color(red: 0.75, green: 0.20, blue: 0.20)
}
```

### 中性色体系

```swift
// 中性色 - 适应亮色/暗色模式
struct NeutralColors {
    // 背景色
    static let background = Color("Background")  // 系统背景
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let backgroundTertiary = Color("BackgroundTertiary")
    
    // 卡片/表面色
    static let surface = Color("Surface")
    static let surfaceElevated = Color("SurfaceElevated")
    
    // 边框色
    static let border = Color("Border").opacity(0.12)
    static let borderStrong = Color("Border").opacity(0.20)
    
    // 文字色
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary").opacity(0.75)
    static let textTertiary = Color("TextTertiary").opacity(0.50)
    static let textDisabled = Color("TextDisabled").opacity(0.30)
}
```

### 液态玻璃材质

```swift
// macOS 26 液态玻璃效果
struct LiquidGlassMaterial {
    // 超轻透玻璃
    static let ultraThin = Material.ultraThinMaterial
        .opacity(0.7)
        .background(.regularMaterial)
    
    // 常规玻璃
    static let regular = Material.regularMaterial
        .opacity(0.85)
    
    // 厚玻璃（用于模态框）
    static let thick = Material.thickMaterial
        .opacity(0.95)
    
    // 自定义液态效果
    static let liquid = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .background(.ultraThinMaterial)
    .blur(radius: 20)
}
```

### 暗色模式适配

```swift
// 暗色模式色彩映射
extension Color {
    static let shenManBackground = Color(
        light: Color(red: 0.98, green: 0.98, blue: 0.99),
        dark: Color(red: 0.08, green: 0.09, blue: 0.11)
    )
    
    static let shenManCard = Color(
        light: Color.white.opacity(0.85),
        dark: Color(red: 0.15, green: 0.16, blue: 0.19).opacity(0.80)
    )
    
    static let shenManPrimary = Color(
        light: Color(red: 0.15, green: 0.25, blue: 0.55),
        dark: Color(red: 0.35, green: 0.50, blue: 0.80)
    )
}
```

---

## 📐 布局系统

### 间距规范

```swift
// 基于 8pt 栅格系统
struct ShenManSpacing {
    static let xx: CGFloat = 2      // 超小间距
    static let xs: CGFloat = 4      // 特小间距
    static let sm: CGFloat = 8      // 小间距
    static let md: CGFloat = 16     // 中间距
    static let lg: CGFloat = 24     // 大间距
    static let xl: CGFloat = 32     // 特大间距
    static let xxl: CGFloat = 48    // 超大间距
    static let xxxl: CGFloat = 64   // 巨大间距
}
```

### 圆角规范

```swift
// 圆角层级
struct CornerRadius {
    static let none: CGFloat = 0
    static let sm: CGFloat = 6      // 小组件
    static let md: CGFloat = 10     // 按钮、卡片
    static let lg: CGFloat = 16     // 大卡片
    static let xl: CGFloat = 24     // 模态框
    static let xxl: CGFloat = 32    // 全屏容器
    
    // 液态圆角（连续曲率）
    static func liquid(_ radius: CGFloat) -> CGFloat {
        radius * 1.2  // 略微放大，更柔和
    }
}
```

### 阴影系统

```swift
// 阴影层级 - 模拟不同高度
struct ShadowElevation {
    // 0 - 无阴影（平面）
    static let flat: Shadow = Shadow(color: .clear, radius: 0, y: 0)
    
    // 1 - 轻微浮起
    static let lifted: Shadow = Shadow(
        color: Color.black.opacity(0.05),
        radius: 8,
        y: 2
    )
    
    // 2 - 卡片高度
    static let card: Shadow = Shadow(
        color: Color.black.opacity(0.08),
        radius: 16,
        y: 4
    )
    
    // 3 - 悬浮高度
    static let floating: Shadow = Shadow(
        color: Color.black.opacity(0.12),
        radius: 24,
        y: 8
    )
    
    // 4 - 模态框高度
    static let modal: Shadow = Shadow(
        color: Color.black.opacity(0.16),
        radius: 32,
        y: 12
    )
    
    // 5 - 弹出菜单高度
    static let popover: Shadow = Shadow(
        color: Color.black.opacity(0.20),
        radius: 40,
        y: 16
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}
```

---

## 🔤 排版系统

### 字体选择

```swift
// 中文字体优先级
struct ChineseFonts {
    // macOS 26 系统字体
    static let system = Font.system
    
    // 中文优化字体
    static let pingfang = "PingFang SC"        // 苹方 - 首选
    static let songti = "Songti SC"             // 宋体 - 正文备选
    static let kaiti = "Kaiti SC"               // 楷体 - 特殊场景
    
    // 等宽字体（时间戳、代码）
    static let monospace = Font.monospacedDigitSystem
}

// 字号系统 - 基于 1.25 比例
struct FontSizes {
    static let xs: CGFloat = 11     // 辅助文字
    static let sm: CGFloat = 13     // 次要文字
    static let md: CGFloat = 15     // 正文字
    static let lg: CGFloat = 18     // 大标题
    static let xl: CGFloat = 22     // 主标题
    static let xxl: CGFloat = 28    // 超大标题
    static let xxxl: CGFloat = 36   // 展示标题
}
```

### 字重规范

```swift
// 字重使用场景
struct FontWeightGuide {
    // regular - 正文、长文本
    static let body = Font.Weight.regular
    
    // medium - 按钮、标签
    static let label = Font.Weight.medium
    
    // semibold - 小标题、强调
    static let emphasis = Font.Weight.semibold
    
    // bold - 主标题、重要信息
    static let heading = Font.Weight.bold
    
    // heavy - 展示性文字
    static let display = Font.Weight.heavy
}
```

### 行高与间距

```swift
// 行高规范
struct LineHeight {
    // 紧凑 - 标题
    static let tight: CGFloat = 1.2
    
    // 标准 - 正文
    static let normal: CGFloat = 1.5
    
    // 宽松 - 长文阅读
    static let relaxed: CGFloat = 1.75
    
    // 中文优化行高
    static let chinese: CGFloat = 1.8  // 中文需要更大行高
}

// 字间距
struct LetterSpacing {
    // 中文默认
    static let chinese: CGFloat = 0
    
    // 英文略微展开
    static let english: CGFloat = 0.2
    
    // 标题略微收紧
    static let heading: CGFloat = -0.3
}
```

---

## 🧩 组件库选择

### 推荐开源组件库

#### 1. **SwiftUI-Introspect** (必需)
```swift
// GitHub: https://github.com/siteline/SwiftUI-Introspect
// 用途：访问底层 UIKit/AppKit 组件，实现更精细的控制

// 安装
// SPM: https://github.com/siteline/SwiftUI-Introspect
```

#### 2. **SwiftUI-Chart** (系统自带)
```swift
// macOS 13+ 自带 Charts 框架
// 用途：转录统计、时长分析图表

import Charts
```

#### 3. **Lottie-SwiftUI** (可选)
```swift
// GitHub: https://github.com/airbnb/lottie-ios
// 用途：精美动画（加载、成功、错误状态）

// 使用场景：
// - 转录加载动画
// - 完成庆祝动画
// - 空状态插图
```

#### 4. **SwiftUI-Flow** (推荐)
```swift
// GitHub: https://github.com/groue/SwiftUI-Flow
// 用途：自动布局流式标签（支持格式标签）
```

#### 5. **KeyboardShortcuts** (推荐)
```swift
// GitHub: https://github.com/sindresorhus/KeyboardShortcuts
// 用途：全局快捷键设置
```

### 自定义组件清单

```
声声慢自定义组件：

基础组件：
├── LiquidCard          - 液态玻璃卡片
├── GlassButton         - 玻璃质感按钮
├── TimestampLabel      - 时间戳标签
├── ProgressBar         - 液态进度条
└── Avatar              - 说话人头像

复合组件：
├── AudioFileCard       - 音频文件卡片
├── TranscriptionRow    - 转录结果行
├── SpeakerBadge        - 说话人标签
├── ModelSelector       - 模型选择器
└── ExportSheet         - 导出对话框

布局组件：
├── SplitView           - 分栏视图
├── Sidebar             - 侧边栏导航
└── Toolbar             - 自定义工具栏
```

---

## 🏠 页面详细设计

### 1. 主页 (HomeView)

#### 布局结构

```
┌─────────────────────────────────────────────────────────┐
│  菜单栏                                                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                                                  │   │
│  │              声声慢                              │   │
│  │           ShenMan                               │   │
│  │                                                  │   │
│  │    让声音慢下来，沉淀为文字                        │   │
│  │                                                  │   │
│  │    ┌───────────────────────────────────────┐    │   │
│  │    │                                       │    │   │
│  │    │                                       │    │   │
│  │    │           📁                          │    │   │
│  │    │                                       │    │   │
│  │    │      拖放音频文件到此处                │    │   │
│  │    │          或点击选择文件                │    │   │   │
│  │    │                                       │    │   │
│  │    │                                       │    │   │
│  │    │   MP3 · WAV · M4A · MP4 · MOV         │    │   │
│  │    │                                       │    │   │
│  │    └───────────────────────────────────────┘    │   │
│  │                                                  │   │
│  │    ┌──────────────┐  ┌──────────────┐          │   │
│  │    │  最近文件     │  │  使用教程     │          │   │
│  │    └──────────────┘  └──────────────┘          │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 交互细节

```swift
// 拖放区域状态
enum DropZoneState {
    case idle           // 默认状态
    case hovering       // 鼠标悬停
    case draggingOver   // 拖拽经过
    case accepting      // 可接受文件
    case processing     // 处理中
}

// 状态对应的视觉效果
struct DropZoneVisuals {
    // 默认
    static let idle = DropZoneStyle(
        background: Color.shenManCard.opacity(0.5),
        border: Color.border.opacity(0.12),
        borderWidth: 1,
        scale: 1.0,
        blur: 20
    )
    
    // 悬停
    static let hovering = DropZoneStyle(
        background: Color.shenManCard.opacity(0.7),
        border: Color.shenManPrimary.opacity(0.3),
        borderWidth: 2,
        scale: 1.02,
        blur: 25
    )
    
    // 拖拽经过
    static let draggingOver = DropZoneStyle(
        background: Color.shenManPrimary.opacity(0.1),
        border: Color.shenManPrimary.opacity(0.6),
        borderWidth: 3,
        scale: 1.03,
        blur: 30
    )
    
    // 动画曲线
    static let animation = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0.2
    )
}
```

#### 代码实现要点

```swift
struct HomeView: View {
    @Environment(AppState.self) var appState
    @State private var dropZoneState: DropZoneState = .idle
    @State private var isShowingFilePicker = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient
            
            VStack(spacing: .xxl) {
                // 标题区域
                titleSection
                
                Spacer()
                
                // 拖放区域
                dropZoneSection
                
                Spacer()
                
                // 快捷入口
                quickAccessSection
            }
            .padding(.xxl)
        }
        .frame(minWidth: 900, minHeight: 650)
    }
    
    // MARK: - 子视图
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.shenManBackground,
                Color.shenManPrimary.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var titleSection: some View {
        VStack(spacing: .md) {
            Text("声声慢")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.shenManPrimary,
                            Color.shenManAccent
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("ShenMan")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
            
            Text("让声音慢下来，沉淀为文字")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.textTertiary)
                .tracking(2)
        }
    }
    
    private var dropZoneSection: some View {
        DropZoneView(
            state: $dropZoneState,
            onFileSelected: { url in
                handleFileSelection(url)
            }
        )
        .frame(maxWidth: 700, maxHeight: 350)
    }
    
    private var quickAccessSection: some View {
        HStack(spacing: .lg) {
            QuickAccessCard(
                icon: "clock",
                title: "最近文件",
                subtitle: "快速继续"
            ) {
                // 打开历史记录
            }
            
            QuickAccessCard(
                icon: "book",
                title: "使用教程",
                subtitle: "新手指南"
            ) {
                // 打开教程
            }
        }
    }
}
```

---

### 2. 转录中页面 (TranscribingView)

#### 布局结构

```
┌─────────────────────────────────────────────────────────┐
│  ← 取消                              声声慢             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📁 meeting_recording.mp3                        │   │
│  │  MP4 · 02:35:18 · 256 MB                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│                                                         │
│              ╭─────────────────────────╮               │
│              │                         │               │
│              │      正在转录...         │               │
│              │                         │               │
│              ╰─────────────────────────╯               │
│                                                         │
│         ╭───────────────────────────────────╮          │
│         │████████████████░░░░░░░░░░ 65%     │          │
│         ╰───────────────────────────────────╯          │
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

#### 液态进度条设计

```swift
struct LiquidProgressBar: View {
    let progress: Double  // 0.0 - 1.0
    let height: CGFloat = 12
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.backgroundSecondary)
                    .frame(height: height)
                
                // 进度填充 - 液态效果
                Group {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.shenManPrimary,
                                    Color.shenManAccent
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * animatedProgress,
                            height: height
                        )
                    
                    // 高光效果
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: geometry.size.width * animatedProgress,
                            height: height
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: height / 2))
                
                // 前端光晕
                if animatedProgress > 0 && animatedProgress < 1 {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.shenManPrimary.opacity(0.8),
                                    Color.shenManPrimary.opacity(0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .offset(x: geometry.size.width * animatedProgress - 12)
                        .blur(radius: 8)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}
```

#### 状态消息轮播

```swift
struct StatusMessageCarousel: View {
    let messages: [String]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: .sm) {
            ForEach(messages.indices, id: \.self) { index in
                Text(messages[index])
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .opacity(index == currentIndex ? 1 : 0)
                    .offset(y: index == currentIndex ? 0 : (index < currentIndex ? -20 : 20))
                    .animation(.easeInOut(duration: 0.4), value: currentIndex)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation {
                    currentIndex = (currentIndex + 1) % messages.count
                }
            }
        }
    }
}

// 使用示例
let statusMessages = [
    "正在加载模型...",
    "正在预处理音频...",
    "正在转录...",
    "正在优化标点...",
    "正在生成时间戳...",
    "正在后处理..."
]
```

---

### 3. 结果页面 (ResultView)

#### 布局结构 - 三栏设计

```
┌───────────────────────────────────────────────────────────────────────┐
│  ← 返回    meeting_recording.mp3                    导出  ⚙️         │
├────────┬────────────────────────────────────────────┬────────────────┤
│        │                                            │                │
│ 信息   │              转录内容                       │   说话人       │
│        │                                            │                │
│ ┌────┐ │  [00:00:01.2 → 00:00:05.8]                │  ┌──────────┐  │
│ │ 📁 │ │  今天我们讨论一下新产品的发布计划          │  │ 说话人 1  │  │
│ │    │ │                                            │  │   65%    │  │
│ │    │ │  [00:00:06.1 → 00:00:12.3]                │  └──────────┘  │
│ │    │ │  好的，我觉得我们可以先从市场调研开始      │                │
│ │    │ │                                            │  ┌──────────┐  │
│ │    │ │  [00:00:12.8 → 00:00:18.5]                │  │ 说话人 2  │  │
│ │    │ │  我同意，我已经联系了几家调研公司          │  │   35%    │  │
│ │    │ │                                            │  └──────────┘  │
│ │    │ │                                            │                │
│ │    │ │                                            │  统计信息      │
│ │    │ │                                            │                │
│ │    │ │                                            │  总时长：      │
│ │    │ │                                            │  2:35:18       │
│ │    │ │                                            │                │
│ │    │ │                                            │  总句数：      │
│ │    │ │                                            │  1,245         │
│ │    │ │                                            │                │
│ │    │ │                                            │  说话人数：    │
│ │    │ │                                            │  2             │
│ │    │ │                                            │                │
│ └────┘ │                                            │                │
│        │                                            │                │
└────────┴────────────────────────────────────────────┴────────────────┘
```

#### 转录行组件

```swift
struct TranscriptionRow: View {
    let sentence: SentenceTimestamp
    let showTimestamp: Bool
    let showSpeaker: Bool
    let isSelected: Bool
    let isPlaying: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: .md) {
            // 时间戳
            if showTimestamp {
                TimestampLabel(time: sentence.startTime)
                    .monospacedDigit()
                    .foregroundColor(.shenManPrimary)
                    .frame(width: 110, alignment: .trailing)
            }
            
            // 说话人标识（v2.0）
            if showSpeaker, let speaker = sentence.speaker {
                SpeakerBadge(speaker: speaker)
                    .frame(width: 80)
            }
            
            // 文本内容
            VStack(alignment: .leading, spacing: .xs) {
                Text(sentence.text)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(4)
                
                // 词级高亮（播放时）
                if isPlaying {
                    WordHighlightView(
                        words: sentence.words,
                        currentTime: audioPlayer.currentTime
                    )
                }
            }
            
            Spacer()
            
            // 操作按钮（悬停显示）
            if isHovering {
                RowActionsView(
                    onPlay: { playFrom(sentence.startTime) },
                    onEdit: { editSentence(sentence) },
                    onCopy: { copyText(sentence.text) }
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .background(
            RoundedRectangle(cornerRadius: .md)
                .fill(
                    isSelected ?
                        Color.shenManPrimary.opacity(0.1) :
                        isHovering ?
                            Color.backgroundSecondary :
                            Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: .md)
                .stroke(
                    isSelected ?
                        Color.shenManPrimary.opacity(0.3) :
                        Color.clear,
                    lineWidth: 1.5
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectSentence(sentence)
        }
        .contextMenu {
            ContextMenuItems(sentence: sentence)
        }
    }
}
```

#### 时间戳标签

```swift
struct TimestampLabel: View {
    let time: TimeInterval
    let format: TimestampFormat = .milliseconds
    
    var body: some View {
        Text(formatTime(time, format: format))
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(.shenManPrimary)
            .padding(.horizontal, .sm)
            .padding(.vertical, .xs)
            .background(
                Capsule()
                    .fill(Color.shenManPrimary.opacity(0.1))
            )
    }
    
    private func formatTime(_ time: TimeInterval, format: TimestampFormat) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        
        switch format {
        case .seconds:
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        case .milliseconds:
            if hours > 0 {
                return String(format: "%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
            } else {
                return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
            }
        }
    }
}
```

---

### 4. 设置页面 (SettingsView)

#### 布局结构

```
┌─────────────────────────────────────────────────────────┐
│  设置                                  ✕               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  模型设置                                        │   │
│  │                                                  │   │
│  │  默认模型                                        │   │
│  │  ┌────────────────────────────────────────┐     │   │
│  │  │ ▼ Qwen3-ASR-0.6B                       │     │   │
│  │  └────────────────────────────────────────┘     │   │
│  │                                                  │   │
│  │  自动下载新模型                                   │   │
│  │  ○ 开启                                         │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  语言设置                                        │   │
│  │                                                  │   │
│  │  默认语言                                        │   │
│  │  ┌────────────────────────────────────────┐     │   │
│  │  │ ▼ 自动检测                             │     │   │
│  │  └────────────────────────────────────────┘     │   │
│  │                                                  │   │
│  │  方言优化                                        │   │
│  │  ☑ 粤语    ☑ 川渝话    ☐ 闽南话                │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  转录设置                                        │   │
│  │                                                  │   │
│  │  时间戳显示                                      │   │
│  │  ● 句首    ○ 句尾    ○ 不显示                  │   │
│  │                                                  │   │
│  │  聚合策略                                        │   │
│  │  ┌────────────────────────────────────────┐     │   │
│  │  │ ▼ 按标点符号                           │     │   │
│  │  └────────────────────────────────────────┘     │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  中文优化                                        │   │
│  │                                                  │   │
│  │  ☑ 同音字纠错                                   │   │
│  │  ☑ 标点优化                                     │   │
│  │  ☑ 数字格式化                                   │   │
│  │  ☑ 去除冗余空格                                 │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  导出设置                                        │   │
│  │                                                  │   │
│  │  默认导出格式                                    │   │
│  │  ┌────────────────────────────────────────┐     │   │
│  │  │ ▼ TXT                                  │     │   │
│  │  └────────────────────────────────────────┘     │   │
│  │                                                  │   │
│  │  默认导出路径                                    │   │
│  │  ~/Documents/Transcriptions          选择...    │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎭 交互动画

### 页面过渡动画

```swift
// 页面过渡效果
struct PageTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.98)
            .offset(y: isActive ? 0 : 20)
            .animation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.7,
                    blendDuration: 0.2
                ),
                value: isActive
            )
    }
}

// 使用
.transition(PageTransition(isActive: isActive))
```

### 列表项进入动画

```swift
//  staggered 列表动画
struct StaggeredEntry: ViewModifier {
    let index: Int
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(x: isActive ? 0 : -20)
            .animation(
                .easeOut(duration: 0.4)
                .delay(Double(index) * 0.05),
                value: isActive
            )
    }
}
```

### 按钮反馈动画

```swift
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.shenManPrimary,
                        Color.shenManPrimaryDark
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .background(
                RoundedRectangle(cornerRadius: .md)
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: .md))
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(
                color: Color.shenManPrimary.opacity(0.3),
                radius: isHovering ? 12 : 8,
                y: isHovering ? 6 : 4
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}
```

---

## 📱 响应式布局

### 断点定义

```swift
// 响应式断点
struct ResponsiveBreakpoints {
    // 紧凑模式（小窗口）
    static let compact: CGFloat = 700
    
    // 常规模式
    static let regular: CGFloat = 900
    
    // 宽敞模式（大窗口）
    static let spacious: CGFloat = 1200
    
    // 侧边栏显示阈值
    static let sidebarThreshold: CGFloat = 1000
}
```

### 自适应布局

```swift
struct AdaptiveLayoutView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var windowWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width < ResponsiveBreakpoints.compact {
                    // 紧凑布局 - 单栏
                    CompactLayoutView()
                } else if geometry.size.width < ResponsiveBreakpoints.spacious {
                    // 常规布局 - 双栏
                    RegularLayoutView()
                } else {
                    // 宽敞布局 - 三栏
                    SpaciousLayoutView()
                }
            }
            .onAppear {
                windowWidth = geometry.size.width
            }
        }
    }
}
```

---

## ♿ 无障碍设计

### VoiceOver 支持

```swift
// 完整的无障碍标签
struct AccessibleTranscriptionRow: View {
    let sentence: SentenceTimestamp
    
    var body: some View {
        HStack {
            // ... 内容
            
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("转录内容")
        .accessibilityValue("\(sentence.text)，时间戳 \(formatTime(sentence.startTime))")
        .accessibilityHint("双击播放从此处开始")
        .accessibilityAddTraits(.isButton)
    }
}
```

### 键盘导航

```swift
// 键盘快捷键
struct KeyboardShortcuts {
    // 全局
    static let newTranscription = KeyboardShortcut("n", modifiers: .command)
    static let openSettings = KeyboardShortcut(",", modifiers: .command)
    
    // 转录中
    static let cancelTranscription = KeyboardShortcut(.escape)
    
    // 结果页
    static let export = KeyboardShortcut("e", modifiers: .command)
    static let copy = KeyboardShortcut("c", modifiers: .command)
    static let playPause = KeyboardShortcut(.space)
    
    // 搜索
    static let search = KeyboardShortcut("f", modifiers: .command)
}
```

### 动态字体

```swift
// 支持系统字体大小调整
struct DynamicFontText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}
```

---

## 🔮 未来扩展考虑

### v2.0 功能预留

```
1. 说话人分离 UI
   - 说话人头像/颜色标识
   - 说话人重命名
   - 说话人统计图表

2. 实时转录 UI
   - 波形可视化
   - 实时滚动
   - 录音控制

3. 多文档标签页
   - 标签栏导航
   - 文档切换动画
   - 未保存提示

4. 插件系统 UI
   - 插件市场
   - 插件管理
   - 模型下载中心
```

### 国际化预留

```swift
// 文本外置
struct LocalizedStrings {
    static let welcomeTitle = String(
        localized: "welcome.title",
        defaultValue: "声声慢",
        comment: "应用主标题"
    )
    
    static let dropZoneHint = String(
        localized: "dropzone.hint",
        defaultValue: "拖放音频文件到此处",
        comment: "拖放区域提示文字"
    )
}

// 支持 RTL 语言（未来阿拉伯语等）
.layoutDirectionBehavior(.supportsMirrored)
```

---

## 📊 设计验收标准

### 视觉验收

- [ ] 液态玻璃效果在不同背景下都清晰可见
- [ ] 色彩对比度符合 WCAG AA 标准
- [ ] 暗色模式所有页面都正常显示
- [ ] 动画流畅，无卡顿（60fps）
- [ ] 所有图标在不同分辨率下都清晰

### 交互验收

- [ ] 拖放操作流畅，反馈及时
- [ ] 所有按钮都有悬停、按下状态
- [ ] 进度显示准确，更新及时
- [ ] 错误提示清晰，有解决方案
- [ ] 键盘导航完整

### 性能验收

- [ ] 首页加载时间 < 1 秒
- [ ] 列表滚动 60fps
- [ ] 大文件（1000+ 行）滚动流畅
- [ ] 内存占用合理（< 500MB 空闲）

---

## 🎨 设计资源

### 颜色代码汇总

```
主色：
- Primary: #26408C (RGB: 38, 64, 140)
- Primary Light: #5A73BF (RGB: 90, 115, 191)
- Primary Dark: #142659 (RGB: 20, 38, 89)

辅助色：
- Accent: #408C8C (RGB: 64, 140, 140)
- Accent Light: #73B2B2 (RGB: 115, 178, 178)

状态色：
- Success: #408C59 (RGB: 64, 140, 89)
- Warning: #D9A626 (RGB: 217, 166, 38)
- Error: #BF3333 (RGB: 191, 51, 51)

背景色（亮色）：
- Background: #FAFAFB (RGB: 250, 250, 251)
- Surface: #FFFFFF (RGB: 255, 255, 255)
- Surface Elevated: #FFFFFF (RGB: 255, 255, 255)

背景色（暗色）：
- Background: #14161C (RGB: 20, 22, 28)
- Surface: #262830 (RGB: 38, 40, 48)
- Surface Elevated: #2E313A (RGB: 46, 49, 58)
```

### Figma 设计文件结构

```
ShenMan Design/
├── 📁 Foundations/
│   ├── Colors
│   ├── Typography
│   ├── Spacing
│   ├── Shadows
│   └── Materials
│
├── 📁 Components/
│   ├── Buttons
│   ├── Cards
│   ├── Inputs
│   ├── Progress
│   └── Navigation
│
├── 📁 Pages/
│   ├── Home
│   ├── Transcribing
│   ├── Result
│   └── Settings
│
├── 📁 Prototypes/
│   ├── Onboarding Flow
│   ├── Transcription Flow
│   └── Export Flow
│
└── 📁 Assets/
    ├── Icons
    ├── Illustrations
    └── Animations
```

---

## 📝 总结

声声慢的 UI/UX 设计以**液态玻璃风格**为核心，融合**现代简约美学**与**中文排版优化**，打造出一款既美观又实用的语音转文字工具。

**设计亮点**：
1. ✅ macOS 26 原生液态玻璃材质
2. ✅ 专为中文优化的排版系统
3. ✅ 流畅优雅的交互动画
4. ✅ 完善的无障碍支持
5. ✅ 面向未来的扩展性设计

**下一步**：
- 在 Figma 中创建高保真原型
- 开发自定义 SwiftUI 组件库
- 进行用户测试和迭代优化

---

**文档版本**：v1.0  
**创建日期**：2026-03-19  
**设计师**：Kappa + AI Assistant  
**设计风格**：macOS 26 Liquid Glass
