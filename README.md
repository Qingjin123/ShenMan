# 声声慢 (ShenMan)

<div align="center">

**让声音慢下来，沉淀为文字**

一款基于 Qwen3-ASR 的 macOS 语音转文字工具

---

## 📖 目录

- [动机](#-动机)
- [特性](#-特性)
- [架构](#-架构)
- [安装方式](#-安装方式)
- [使用指南](#-使用指南)
- [未来开发](#-未来开发)
- [技术栈](#-技术栈)
- [常见问题](#-常见问题)
- [贡献](#-贡献)
- [许可证](#-许可证)

---

## 🎯 动机

长期以来，语音转文字领域一直被 **Whisper** 模型主导。然而 Whisper 发布已有数年，技术架构相对陈旧。随着大模型技术的快速发展，以 **Qwen3-ASR** 为代表的新一代 ASR 模型已经相对成熟，在中文场景下展现出显著优势：

| 对比维度 | Whisper-large-v3 | Qwen3-ASR-0.6B |
|---------|------------------|----------------|
| 中文准确率 | ~88% | **~92%** |
| 模型大小 | 3.0 GB | **0.6 GB** |
| 处理速度 (RTF) | ~0.3 | **~0.15** |
| 中文方言支持 | 有限 | **22 种方言** |
| 中英混杂 | 一般 | **优秀** |

**开发本项目的初衷**：
1. 🎙️ **技术更新**：利用新一代 ASR 模型，在中文场景下提供更好的转录体验
2. 🍎 **Mac 原生**：充分利用 Apple Silicon 的 MLX 框架，实现本地高效推理
3. 🔒 **隐私优先**：完全离线处理，无网络请求，保护用户隐私
4. 📖 **开源共享**：为自己使用，也分享给有同样需求的朋友

---

## ✨ 特性

### 核心功能

- 🎯 **高精度转录**：基于 Qwen3-ASR-0.6B，中文准确率 > 92%
- ⏱️ **句子级时间戳**：自动按标点聚合，输出带时间戳的文本
- 📤 **多格式导出**：支持 TXT、SRT 字幕、Markdown 格式
- 🎨 **现代 UI**：macOS 26 液态玻璃风格，支持深色模式
- 🔌 **完全离线**：所有处理在本地进行，无需联网

### 支持格式

| 类型 | 格式 |
|------|------|
| 音频 | MP3, WAV, M4A, FLAC, AAC |
| 视频 | MP4, MOV, AVI |

### 系统要求

- **macOS**: 13.0+
- **芯片**: Apple Silicon (M1/M2/M3) —— Intel Mac 暂不支持
- **内存**: 建议 8GB+（模型占用约 2.5GB）

---

## 🏗️ 架构

### 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                      (SwiftUI UI)                        │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│                   (ViewModel / State)                    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Business Logic Layer                  │
│              (TranscriptionService, Processors)          │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                  │
│           (MLX Swift, AVFoundation, Qwen3-ASR)           │
└─────────────────────────────────────────────────────────┘
```

### 核心模块

| 模块 | 职责 |
|------|------|
| `TranscriptionService` | 转录服务，协调模型推理和后处理 |
| `TimestampAggregator` | 时间戳聚合，将词级时间戳聚合成句子级 |
| `ChinesePostProcessor` | 中文后处理，包括同音字纠错、标点优化等 |
| `Exporters` | 导出器，支持 TXT/SRT/Markdown 格式 |

详细架构文档请查看：[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## 📦 安装方式

### 方式一：从源代码构建（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/Qingjin123/ShenMan.git
cd ShenMan

# 2. 打开 Xcode 项目
open ShenMan.xcodeproj

# 3. 在 Xcode 中：
#    - 选择 Scheme: ShenMan
#    - 按下 Cmd + R 运行
```

### 方式二：下载预构建版本（开发中）

> ⚠️ **注意**：预构建版本暂未发布，预计 1-2 天内完成。

由于 macOS 应用签名需要 Apple Developer 账号，目前发布的版本可能会有"应用已损坏"的警告。解决方法：

```bash
# 如果打开时提示"应用已损坏"，在终端执行：
sudo xattr -cr /Applications/ShenMan.app
```

### 模型下载

首次运行时，应用会自动下载 Qwen3-ASR-0.6B 模型（约 2.5GB）。模型会缓存到：
```
~/Library/Caches/MLX-Audio/mlx-community_Qwen3-ASR-0.6B-8bit
```

---

## 📖 使用指南

### 快速开始

1. **打开应用**：启动 ShenMan
2. **导入音频**：拖放音频/视频文件到窗口
3. **开始转录**：点击"开始转录"按钮
4. **查看结果**：转录完成后查看带时间戳的文本
5. **导出文件**：选择导出格式（TXT/SRT/Markdown）

### 导出格式示例

#### TXT 格式
```
[00:00:01.2 → 00:00:05.8] 今天我们讨论一下新产品的发布计划
[00:00:06.1 → 00:00:12.3] 好的，我觉得我们可以先从市场调研开始
```

#### SRT 字幕格式
```srt
1
00:00:01,200 --> 00:00:05,800
今天我们讨论一下新产品的发布计划

2
00:00:06,100 --> 00:00:12,300
好的，我觉得我们可以先从市场调研开始
```

#### Markdown 格式
```markdown
# meeting_recording.mp3

## 元数据
- 模型：Qwen3-ASR-0.6B
- 音频时长：2:35:18

## 转录内容
- **[00:00:01.2]** 今天我们讨论一下新产品的发布计划
- **[00:00:06.1]** 好的，我觉得我们可以先从市场调研开始
```

---

## 🚀 未来开发

### v1.0（当前版本）
- [x] 文件导入
- [x] Qwen3-ASR 转录
- [x] 句子级时间戳
- [x] TXT/SRT/Markdown 导出
- [ ] 预构建版本发布（1-2 天内）

### v1.1（计划中）
- [ ] 双模型支持（Whisper-large-v3-turbo）
- [ ] 中文后处理优化（同音字纠错、标点优化）
- [ ] 批量处理
- [ ] 历史记录

### v2.0（长期规划）
- [ ] 说话人分离（集成 Sortformer）
- [ ] 词级对齐（集成 Qwen3-ForcedAligner）
- [ ] 实时录音转录
- [ ] 音频预处理（降噪）

### 未来功能
- [ ] AI 摘要（需用户自备 LLM API Key）
- [ ] 插件系统（支持第三方模型）
- [ ] 领域术语库（医学、法律、金融等）

详细开发计划请查看：[docs/Development_Tasks.md](docs/Development_Tasks.md)

---

## 🛠️ 技术栈

| 层级 | 技术 |
|------|------|
| 语言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 模型推理 | MLX Swift |
| 音频处理 | AVFoundation |
| 并发模型 | async/await + Actor |
| 最低系统 | macOS 13.0+ |

---

## ❓ 常见问题

### Q: 为什么只支持 Apple Silicon？
A: 本项目使用 MLX 框架进行模型推理，MLX 是 Apple 专为 Apple Silicon 设计的框架，不支持 Intel Mac。

### Q: 应用提示"已损坏"怎么办？
A: 这是由于应用未签名导致的。执行以下命令即可：
```bash
sudo xattr -cr /Applications/ShenMan.app
```

### Q: 如何查看日志？
A: 在终端运行以下命令查看日志：
```bash
log stream --predicate 'process == "ShenMan"' --info
```

---

## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！

### 开发环境配置

```bash
# 1. 克隆仓库
git clone https://github.com/Qingjin123/ShenMan.git
cd ShenMan

# 2. 安装依赖（SPM 自动处理）

# 3. 打开 Xcode
open ShenMan.xcodeproj

# 4. 运行测试
# 在 Xcode 中按下 Cmd + U
```

### 提交代码

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

详细开发指南请查看：[docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)

---

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 📚 文档

| 文档 | 说明 |
|------|------|
| [产品需求](docs/PRD.md) | 产品需求文档 |
| [架构设计](docs/ARCHITECTURE.md) | 系统架构设计 |
| [开发者指南](docs/DEVELOPER_GUIDE.md) | 开发环境配置、构建、测试 |
| [编码规范](docs/CODING_STANDARDS.md) | Swift 代码风格指南 |
| [故障排除](docs/TROUBLESHOOTING.md) | 常见问题解决方案 |
| [文档索引](docs/INDEX.md) | 完整文档导航 |

---

## 🙏 致谢

- [MLX](https://github.com/ml-explore/mlx) - Apple 的机器学习框架
- [MLX Swift](https://github.com/ml-explore/mlx-swift) - MLX 的 Swift 绑定
- [Qwen3-ASR](https://huggingface.co/mlx-community/Qwen3-ASR-0.6B-8bit) - 阿里巴巴开源的 ASR 模型
- [mlx-audio](https://github.com/Blaizzy/mlx-audio) - 基于 MLX 的音频处理库

---

<div align="center">

**声声慢** © 2026 kappa

Made with ❤️ for macOS

</div>
