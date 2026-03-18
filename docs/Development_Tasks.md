# 声声慢 (ShenMan) - AI 驱动开发任务规划

## 📋 文档说明

**目标**：将项目开发拆解为 AI 可执行的具体任务，每个任务都有明确的输入、输出和验收标准。

**开发模式**：个人 + AI 协作
- AI 负责：代码生成、单元测试、文档草稿
- 人类负责：架构决策、代码审查、UI 调整、测试验证

**预计周期**：4-8 周（兼职）

---

## 🎯 总体里程碑

```
Week 1-2:  项目脚手架 + 基础 UI
Week 3-4:  转录核心功能
Week 5-6:  时间戳 + 导出功能
Week 7-8:  中文优化 + 测试发布
```

---

## 📅 Week 1-2: 项目脚手架 + 基础 UI

### 任务 1.1: 创建项目结构

**任务描述**：创建 Xcode 项目和目录结构

**输入**：
- 本文档
- Xcode 15+

**输出**：
- ShenMan.xcodeproj
- 完整目录结构
- Info.plist 配置
- Entitlements 配置

**AI Prompt 示例**：
```
请帮我创建一个 macOS SwiftUI 项目，要求：
1. 项目名称：ShenMan
2. 最低系统：macOS 13.0
3. 语言：Swift 5.9
4. 创建以下目录结构：
   - Views/
   - ViewModels/
   - Models/
   - Services/
   - Processors/
   - Exporters/
   - Utilities/
5. 配置 Entitlements 允许文件访问
```

**验收标准**：
- [ ] Xcode 项目可以编译
- [ ] 运行后显示空白窗口
- [ ] 目录结构符合要求

**预计时间**：2 小时

---

### 任务 1.2: 实现 App 入口和基础导航

**任务描述**：创建 App 入口和基础导航结构

**输入**：
- 任务 1.1 的项目
- PRD 中的 UI 规范

**输出**：
- ShenManApp.swift
- ContentView.swift
- 基础导航

**代码要点**：
```swift
import SwiftUI

@main
struct ShenManApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
```

**验收标准**：
- [ ] App 可以启动
- [ ] 窗口大小正确
- [ ] 导航结构正常

**预计时间**：3 小时

---

### 任务 1.3: 实现 DropZoneView（拖放组件）

**任务描述**：实现文件拖放组件

**输入**：
- AI_Development_Guide.md 中的 DropZoneView 规范
- 配色和字体规范

**输出**：
- Views/Components/DropZoneView.swift
- 支持拖放和点击选择
- 文件格式验证

**AI Prompt 示例**：
```
请实现一个 SwiftUI 拖放组件 DropZoneView，要求：
1. 支持拖放音频/视频文件
2. 支持点击选择文件
3. 验证文件格式（mp3, wav, m4a, mp4, mov 等）
4. 悬停和拖入时有视觉反馈
5. 使用 SwiftUI 的 .onDrop modifier
6. 文件格式不支持时显示错误提示
参考 AI_Development_Guide.md 中的详细规范
```

**验收标准**：
- [ ] 可以拖放文件
- [ ] 可以点击选择文件
- [ ] 格式验证正常
- [ ] 视觉反馈正常
- [ ] 错误提示清晰

**预计时间**：4 小时

---

### 任务 1.4: 实现 AudioFile 模型和元数据读取

**任务描述**：实现音频文件模型和元数据读取功能

**输入**：
- AI_Development_Guide.md 中的 AudioFile 规范

**输出**：
- Models/AudioFile.swift
- Utilities/AudioMetadataReader.swift

**代码要点**：
```swift
import AVFoundation

actor AudioMetadataReader {
    static func readMetadata(from url: URL) async throws -> AudioFile {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)
        
        // 获取音频轨道
        let audioTracks = tracks.filter { $0.mediaType == .audio }
        guard let audioTrack = audioTracks.first else {
            throw AudioError.noAudioTrack
        }
        
        // 获取格式、采样率等
        let format = AudioFile.AudioFormat(rawValue: url.pathExtension.lowercased()) ?? .unknown
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        
        return AudioFile(
            id: UUID(),
            url: url,
            filename: url.lastPathComponent,
            duration: CMTimeGetSeconds(duration),
            fileSize: fileSize,
            format: format,
            sampleRate: try await audioTrack.load(.formatDescription).sampleRate,
            channels: try await audioTrack.load(.formatDescription).channelCount
        )
    }
}
```

**验收标准**：
- [ ] 可以读取音频时长
- [ ] 可以读取文件格式
- [ ] 可以读取文件大小
- [ ] 错误处理正常

**预计时间**：3 小时

---

### 任务 1.5: 实现 AudioFileCard 组件

**任务描述**：实现音频文件信息展示卡片

**输入**：
- UI 规范中的 AudioFileCard 设计

**输出**：
- Views/Components/AudioFileCard.swift

**验收标准**：
- [ ] 显示文件名
- [ ] 显示时长（格式化）
- [ ] 显示文件大小（格式化）
- [ ] 显示格式图标
- [ ] 样式符合设计

**预计时间**：2 小时

---

### 任务 1.6: 实现基础设置页面

**任务描述**：实现设置页面框架

**输入**：
- PRD 中的设置需求
- AppSettings 模型

**输出**：
- Views/SettingsView.swift
- ViewModels/SettingsViewModel.swift
- Models/AppSettings.swift

**验收标准**：
- [ ] 可以打开设置页面
- [ ] 显示模型选择
- [ ] 显示语言选择
- [ ] 设置可以保存

**预计时间**：3 小时

---

### Week 1-2 总结

**总预计时间**：17 小时（约 2-3 个工作日）

**交付物**：
- ✅ 完整的 Xcode 项目
- ✅ 可运行的 App（无转录功能）
- ✅ 拖放文件功能
- ✅ 文件信息展示
- ✅ 基础设置页面

**测试重点**：
- 拖放功能稳定性
- 文件格式验证准确性
- UI 响应流畅度

---

## 📅 Week 3-4: 转录核心功能

### 任务 2.1: 实现 ASRModel 协议

**任务描述**：定义 ASR 模型协议

**输入**：
- Technical_Architecture.md 中的 ASRModel 协议设计

**输出**：
- Models/ASR/ASRModel.swift

**代码要点**：
```swift
protocol ASRModel: Sendable {
    var name: String { get }
    var description: String { get }
    var supportedLanguages: [Language] { get }
    var sizeGB: Double { get }
    var isDownloaded: Bool { get }
    
    func download() async throws
    func transcribe(
        audio: AudioBuffer,
        language: Language?,
        progressHandler: @Sendable @escaping (Double) -> Void
    ) async throws -> RawTranscriptionResult
}
```

**验收标准**：
- [ ] 协议定义完整
- [ ] 支持 Sendable
- [ ] 文档注释完整

**预计时间**：2 小时

---

### 任务 2.2: 集成 MLX Swift

**任务描述**：配置 MLX Swift 依赖

**输入**：
- MLX Swift 官方文档
- Qwen3-ASR 模型信息

**输出**：
- Package.swift 配置
- MLX 环境测试代码

**AI Prompt 示例**：
```
请帮我配置 MLX Swift 依赖，要求：
1. 在 Package.swift 中添加 MLX Swift 依赖
2. 创建一个测试用例验证 MLX 可以正常运行
3. 编写一个简单的矩阵乘法测试
参考：https://github.com/ml-explore/mlx-swift
```

**验收标准**：
- [ ] SPM 依赖配置正确
- [ ] 项目可以编译
- [ ] MLX 基础功能测试通过

**预计时间**：3 小时

---

### 任务 2.3: 实现 Qwen3ASRModel

**任务描述**：实现 Qwen3-ASR 模型封装

**输入**：
- Qwen3-ASR 模型文档
- ASRModel 协议
- MLX Swift API

**输出**：
- Models/ASR/Qwen3ASRModel.swift

**实现要点**：
```swift
final class Qwen3ASRModel: ASRModel {
    let name = "Qwen3-ASR-0.6B"
    let description = "阿里开源，中文优化，支持 22 种方言"
    let supportedLanguages: [Language] = [.chinese, .chineseCantonese, .english]
    let sizeGB: Double = 2.5
    
    private let modelPath: URL
    private let mlxContext: MLXContext
    
    func transcribe(
        audio: AudioBuffer,
        language: Language?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> RawTranscriptionResult {
        // 1. 加载模型
        // 2. 预处理音频
        // 3. 执行 MLX 推理
        // 4. 解析结果（词 + 时间戳）
        // 5. 返回 RawTranscriptionResult
    }
}
```

**⚠️ 注意**：此任务需要参考 mlx-audio 的实现，可能需要 Python 桥接或等待 Qwen3-ASR 的 Swift 版本。

**备选方案**：
- 方案 A：使用 mlx-audio 的 Python 实现，通过 Process 调用
- 方案 B：等待 Qwen3-ASR 官方 Swift 支持
- 方案 C：先用 WhisperKit 替代，后续切换

**验收标准**：
- [ ] 可以加载模型
- [ ] 可以执行转录
- [ ] 返回词级时间戳
- [ ] 进度回调正常

**预计时间**：8-12 小时（取决于 MLX 生态成熟度）

---

### 任务 2.4: 实现 AudioPreprocessor

**任务描述**：实现音频预处理服务

**输入**：
- Technical_Architecture.md 中的 AudioPreprocessor 设计

**输出**：
- Services/AudioPreprocessor.swift

**功能要求**：
- 将音频转换为模型所需格式（16kHz，单声道，PCM）
- 使用 AVFoundation 解码
- 重采样
- 声道混合

**验收标准**：
- [ ] 可以转换不同格式的音频
- [ ] 输出格式符合模型要求
- [ ] 处理速度快

**预计时间**：4 小时

---

### 任务 2.5: 实现 TranscriptionService

**任务描述**：实现转录服务（核心业务逻辑）

**输入**：
- Technical_Architecture.md 中的 TranscriptionService 设计
- ASRModel 实现
- AudioPreprocessor

**输出**：
- Services/TranscriptionService.swift

**验收标准**：
- [ ] 可以执行完整转录流程
- [ ] 进度回调正常
- [ ] 错误处理完善
- [ ] 性能达标（RTF < 0.2）

**预计时间**：6 小时

---

### 任务 2.6: 实现 TranscribingView（转录中页面）

**任务描述**：实现转录进度展示页面

**输入**：
- UI 规范中的 TranscribingView 设计

**输出**：
- Views/TranscribingView.swift
- ViewModels/TranscriptionViewModel.swift

**验收标准**：
- [ ] 显示文件信息
- [ ] 显示进度条
- [ ] 显示百分比
- [ ] 显示状态消息
- [ ] 显示预计剩余时间
- [ ] 支持取消操作

**预计时间**：4 小时

---

### 任务 2.7: 实现 TranscriptionViewModel

**任务描述**：实现转录用 ViewModel

**输入**：
- Technical_Architecture.md 中的 ViewModel 设计

**输出**：
- ViewModels/TranscriptionViewModel.swift

**功能要求**：
- 管理转录状态
- 调用 TranscriptionService
- 更新进度
- 处理错误

**验收标准**：
- [ ] 状态管理正确
- [ ] 进度更新及时
- [ ] 错误处理完善
- [ ] 支持取消

**预计时间**：4 小时

---

### Week 3-4 总结

**总预计时间**：31-37 小时（约 4-5 个工作日）

**交付物**：
- ✅ Qwen3-ASR 模型集成
- ✅ 完整的转录流程
- ✅ 进度展示
- ✅ 错误处理

**测试重点**：
- 转录准确性
- 处理速度（RTF）
- 内存占用
- 长时间运行稳定性

**风险点**：
- ⚠️ Qwen3-ASR 的 Swift 支持可能不成熟
- ⚠️ MLX 生态可能有限制
- **应对**：准备 WhisperKit 作为备选

---

## 📅 Week 5-6: 时间戳 + 导出功能

### 任务 3.1: 实现 TimestampAggregator

**任务描述**：实现时间戳聚合器

**输入**：
- AI_Development_Guide.md 中的 TimestampAggregator 设计

**输出**：
- Processors/TimestampAggregator.swift

**功能要求**：
- 按标点符号聚合
- 按停顿时间聚合
- 输出句子级时间戳

**验收标准**：
- [ ] 聚合逻辑正确
- [ ] 标点检测准确
- [ ] 停顿阈值可配置
- [ ] 单元测试覆盖

**预计时间**：4 小时

---

### 任务 3.2: 实现 ChinesePostProcessor

**任务描述**：实现中文后处理器

**输入**：
- AI_Development_Guide.md 中的 ChinesePostProcessor 设计

**输出**：
- Processors/ChinesePostProcessor.swift

**功能要求**：
- 同音字纠错（基础规则）
- 标点优化
- 数字格式化
- 去除冗余空格

**验收标准**：
- [ ] 纠错规则生效
- [ ] 标点优化正常
- [ ] 数字格式化正确
- [ ] 处理速度快

**预计时间**：6 小时

---

### 任务 3.3: 实现 Exporter 协议

**任务描述**：定义导出器协议

**输入**：
- AI_Development_Guide.md 中的 Exporter 设计

**输出**：
- Exporters/Exporter.swift
- Exporters/ExportOptions.swift

**验收标准**：
- [ ] 协议定义完整
- [ ] 支持多种格式扩展

**预计时间**：2 小时

---

### 任务 3.4: 实现 TXTExporter

**任务描述**：实现 TXT 导出器

**输入**：
- AI_Development_Guide.md 中的 TXTExporter 设计

**输出**：
- Exporters/TXTExporter.swift

**验收标准**：
- [ ] 导出格式正确
- [ ] 时间戳格式可选
- [ ] 编码正确（UTF-8）

**预计时间**：2 小时

---

### 任务 3.5: 实现 SRTExporter

**任务描述**：实现 SRT 字幕导出器

**输入**：
- AI_Development_Guide.md 中的 SRTExporter 设计

**输出**：
- Exporters/SRTExporter.swift

**验收标准**：
- [ ] SRT 格式正确
- [ ] 时间轴准确
- [ ] 可在视频播放器中使用

**预计时间**：3 小时

---

### 任务 3.6: 实现 MarkdownExporter

**任务描述**：实现 Markdown 导出器

**输入**：
- AI_Development_Guide.md 中的 MarkdownExporter 设计

**输出**：
- Exporters/MarkdownExporter.swift

**验收标准**：
- [ ] Markdown 格式正确
- [ ] 包含元数据
- [ ] 可读性好

**预计时间**：2 小时

---

### 任务 3.7: 实现 ExportSheet（导出对话框）

**任务描述**：实现导出选择对话框

**输入**：
- UI 规范

**输出**：
- Views/Components/ExportSheet.swift

**功能要求**：
- 选择导出格式
- 选择是否包含时间戳
- 选择保存路径
- 执行导出

**验收标准**：
- [ ] UI 友好
- [ ] 选项完整
- [ ] 导出成功
- [ ] 错误提示清晰

**预计时间**：4 小时

---

### 任务 3.8: 实现 ResultView（结果页面）

**任务描述**：实现转录结果展示页面

**输入**：
- UI 规范中的 ResultView 设计

**输出**：
- Views/ResultView.swift

**功能要求**：
- 展示转录结果
- 显示时间戳
- 支持文本编辑
- 支持导出
- 支持复制

**验收标准**：
- [ ] 结果展示清晰
- [ ] 时间戳可读
- [ ] 文本可编辑
- [ ] 导出功能正常
- [ ] 滚动流畅

**预计时间**：6 小时

---

### Week 5-6 总结

**总预计时间**：29 小时（约 3-4 个工作日）

**交付物**：
- ✅ 时间戳聚合功能
- ✅ 中文后处理
- ✅ 三种导出格式
- ✅ 结果展示页面

**测试重点**：
- 时间戳准确性
- 导出格式兼容性
- 中文纠错效果
- 大数据量性能

---

## 📅 Week 7-8: 中文优化 + 测试发布

### 任务 4.1: 完善中文纠错规则

**任务描述**：扩充中文纠错规则库

**输入**：
- 常见同音字错误列表
- 中文语料库

**输出**：
- Processors/ChinesePostProcessor.swift（增强版）
- Resources/Corrections.json（可选）

**验收标准**：
- [ ] 纠错规则覆盖常见错误
- [ ] 不误纠正确文本
- [ ] 性能影响小

**预计时间**：4 小时

---

### 任务 4.2: 实现 ModelRegistry 和 ModelManager

**任务描述**：实现模型注册和管理

**输入**：
- Technical_Architecture.md 中的设计

**输出**：
- Services/ModelRegistry.swift
- Services/ModelManager.swift

**功能要求**：
- 注册可用模型
- 下载模型
- 切换模型
- 检查更新

**验收标准**：
- [ ] 模型管理正常
- [ ] 下载进度显示
- [ ] 切换模型生效

**预计时间**：6 小时

---

### 任务 4.3: 实现 WhisperModel（备选模型）

**任务描述**：集成 Whisper 作为备选模型

**输入**：
- WhisperKit 文档
- ASRModel 协议

**输出**：
- Models/ASR/WhisperModel.swift

**验收标准**：
- [ ] Whisper 转录正常
- [ ] 可以切换模型
- [ ] 性能达标

**预计时间**：6 小时

---

### 任务 4.4: 编写单元测试

**任务描述**：为核心功能编写单元测试

**输入**：
- 各模块代码

**输出**：
- Tests/ 目录下所有测试文件

**测试覆盖**：
- TimestampAggregator
- ChinesePostProcessor
- Exporters
- AudioMetadataReader
- 业务逻辑

**验收标准**：
- [ ] 核心功能测试覆盖 > 80%
- [ ] 所有测试通过
- [ ] CI 配置完成

**预计时间**：8 小时

---

### 任务 4.5: 性能优化

**任务描述**：优化性能和内存

**输入**：
- Instruments 分析报告

**输出**：
- 优化后的代码
- 性能测试报告

**优化方向**：
- 减少内存峰值
- 加快处理速度
- 优化 UI 响应

**验收标准**：
- [ ] RTF < 0.2
- [ ] 内存 < 4GB
- [ ] UI 无卡顿

**预计时间**：6 小时

---

### 任务 4.6: 编写用户文档

**任务描述**：编写用户使用指南

**输入**：
- 产品功能
- 使用场景

**输出**：
- Docs/UserGuide.md
- README.md（草稿）

**内容**：
- 安装说明
- 使用教程
- 常见问题
- 故障排除

**验收标准**：
- [ ] 文档清晰易懂
- [ ] 包含截图
- [ ] 覆盖常见问题

**预计时间**：4 小时

---

### 任务 4.7: 打包和发布准备

**任务描述**：准备 Release 包

**输入**：
- 完整项目

**输出**：
- Release 版本的 App
- GitHub Release 页面
- 发布说明

**步骤**：
1. 构建 Release 版本
2. 测试无签名运行
3. 编写 Release Notes
4. 创建 GitHub Release
5. 上传 App

**验收标准**：
- [ ] App 可以运行
- [ ] 无签名警告处理说明
- [ ] Release Notes 清晰

**预计时间**：3 小时

---

### Week 7-8 总结

**总预计时间**：37 小时（约 4-5 个工作日）

**交付物**：
- ✅ 双模型支持
- ✅ 中文优化完善
- ✅ 单元测试覆盖
- ✅ 性能达标
- ✅ 用户文档
- ✅ v0.1 Release

**测试重点**：
- 全功能回归测试
- 不同 Mac 机型兼容性
- 长时间运行稳定性
- 边界条件测试

---

## 📊 总体进度跟踪

### 时间汇总

| 阶段 | 预计时间 | 实际时间 | 状态 |
|------|---------|---------|------|
| Week 1-2 | 17h | - | ⏳ 待开始 |
| Week 3-4 | 31-37h | - | ⏳ 待开始 |
| Week 5-6 | 29h | - | ⏳ 待开始 |
| Week 7-8 | 37h | - | ⏳ 待开始 |
| **总计** | **114-120h** | - | - |

### 里程碑

| 里程碑 | 预计完成 | 实际完成 | 状态 |
|--------|---------|---------|------|
| MVP 原型 | Week 2 | - | ⏳ |
| 核心转录 | Week 4 | - | ⏳ |
| 完整功能 | Week 6 | - | ⏳ |
| v0.1 Release | Week 8 | - | ⏳ |

---

## 🎯 每日开发流程建议

### 标准开发日（3-4 小时）

```
1. 回顾昨日进度（10 分钟）
2. 查看今日任务清单（10 分钟）
3. 与 AI 协作开发（2-3 小时）
   - 让 AI 生成代码
   - 人工审查和调整
   - 运行测试
4. 提交代码（10 分钟）
5. 更新任务状态（5 分钟）
```

### AI 协作流程

```
1. 给 AI 明确的任务描述
2. AI 生成代码
3. 人工审查：
   - 逻辑是否正确
   - 是否符合规范
   - 是否有安全隐患
4. 运行测试
5. 发现问题 → 让 AI 修复
6. 通过 → 提交代码
```

---

## ⚠️ 风险与应对

### 技术风险

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|---------|
| Qwen3-ASR Swift 支持不成熟 | 高 | 高 | 备选 WhisperKit |
| MLX 性能不达标 | 中 | 中 | 优化或量化模型 |
| 内存占用过高 | 中 | 中 | 流式处理 |
| 时间戳不准确 | 低 | 高 | 调整聚合策略 |

### 进度风险

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|---------|
| 兼职时间不足 | 高 | 高 | 调整里程碑 |
| AI 生成代码质量低 | 中 | 中 | 加强审查 |
| 测试发现重大 bug | 中 | 高 | 预留缓冲时间 |

---

## 🎉 成功标准

### MVP 成功标准（v0.1）

- [ ] 可以转录 1 分钟音频
- [ ] 准确率 > 90%（普通话）
- [ ] RTF < 0.2
- [ ] 导出 TXT/SRT
- [ ] 无崩溃
- [ ] GitHub 10+ Stars

### v1.0 成功标准

- [ ] 支持双模型
- [ ] 中文优化生效
- [ ] 单元测试覆盖 > 80%
- [ ] GitHub 100+ Stars
- [ ] 有真实用户使用

---

**文档版本**：v1.0  
**创建日期**：2026-03-19  
**下次更新**：每周末回顾进度

**开始开发前，请**：
1. 通读所有文档（PRD、Technical_Architecture、AI_Development_Guide）
2. 准备好开发环境（Xcode 15+、macOS 13.0+）
3. 安装 MLX Swift 依赖
4. 下载 Qwen3-ASR 模型
5. 从 Week 1 任务 1.1 开始

**祝开发顺利！🚀**
