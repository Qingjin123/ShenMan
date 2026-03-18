# 声声慢 (ShenMan) 测试指南

## 快速开始

### 1. 剪辑测试音频

将 10 分钟的测试音频剪辑为 30 秒：

```bash
# 安装 ffmpeg (如果未安装)
brew install ffmpeg

# 剪辑音频
cd /Users/qingjin/Documents/ShenMan
ffmpeg -i test.mp3 -t 30 -c copy test_30s.mp3
```

### 2. 下载模型

**方法 A: 使用下载脚本**

```bash
cd /Users/qingjin/Documents/ShenMan
./scripts/download_model.sh
```

**方法 B: 使用 huggingface-cli**

```bash
# 安装 huggingface_hub
pip install huggingface_hub

# 下载模型
huggingface-cli download mlx-community/Qwen3-ASR-0.6B-8bit \
  --local-dir ~/Library/Caches/MLX-Audio/mlx-community_Qwen3-ASR-0.6B-8bit
```

**方法 C: 使用应用内下载**

1. 打开应用
2. 点击设置按钮（齿轮图标）
3. 选择"模型"标签页
4. 点击"下载"按钮

### 3. 运行测试

**运行完整测试脚本：**

```bash
cd /Users/qingjin/Documents/ShenMan
./scripts/test_transcription.sh
```

**运行单元测试：**

```bash
cd /Users/qingjin/Documents/ShenMan
xcodebuild test \
  -project ShenMan.xcodeproj \
  -scheme ShenMan \
  -destination 'platform=macOS'
```

**在 Xcode 中运行测试：**

1. 打开 `ShenMan.xcodeproj`
2. 按 `Cmd + U` 或选择 **Product → Test**

### 4. 测试应用功能

**手动测试流程：**

1. **启动应用**
   - 在 Xcode 中按 `Cmd + R` 运行

2. **检查模型状态**
   - 点击设置按钮（右上角齿轮图标）
   - 选择"模型"标签页
   - 确认 Qwen3-ASR-0.6B-8bit 显示"已下载"

3. **导入音频**
   - 拖放 `test_30s.mp3` 到应用窗口
   - 或点击文件选择器

4. **开始转录**
   - 点击"开始转录"按钮
   - 观察进度条
   - 等待转录完成

5. **检查结果**
   - 查看转录文本
   - 检查时间戳是否正确

6. **导出结果**
   - 点击"导出"按钮
   - 选择 TXT/SRT/Markdown 格式
   - 保存文件

## 测试用例说明

### 单元测试

| 测试类 | 测试内容 |
|--------|----------|
| `AudioFileTests` | 音频文件加载、格式支持、时长格式化 |
| `TimestampAggregatorTests` | 时间戳聚合、短句合并 |
| `ExporterTests` | TXT/SRT导出格式 |
| `TimeFormatterTests` | 时间格式化 |
| `AppSettingsTests` | 设置初始化和持久化 |
| `TranscriptionServiceIntegrationTests` | 服务初始化和模型创建 |

### 集成测试

运行完整转录流程测试：

```bash
./scripts/test_transcription.sh
```

测试步骤：
1. 检查测试音频文件
2. 剪辑音频为 30 秒
3. 检查模型缓存
4. 运行 Xcode 测试
5. 生成测试报告

## 常见问题

### 模型下载卡住

**问题**：模型下载很快卡住，不是网络问题

**可能原因**：
1. 缓存目录权限问题
2. MLX 库初始化问题
3. 模型文件损坏

**解决方案**：

```bash
# 1. 清理缓存
rm -rf ~/Library/Caches/MLX-Audio

# 2. 重新下载
./scripts/download_model.sh

# 3. 检查权限
ls -la ~/Library/Caches/MLX-Audio
```

### 设置按钮无响应

**问题**：点击设置按钮没有反应

**解决方案**：
1. 检查 `ContentView.swift` 是否有 `.sheet` 修饰符
2. 重启应用
3. 清理构建缓存：`Cmd + Shift + K`

### UI 元素相互覆盖

**问题**：UI 元素重叠或覆盖

**解决方案**：
1. 检查 `VStack`/`HStack` 的 `spacing` 参数
2. 确保使用明确的 `frame` 尺寸
3. 避免嵌套的 `.frame(maxWidth:maxHeight:)`

### 转录失败

**问题**：点击开始转录后失败

**检查步骤**：

```bash
# 1. 确认模型已下载
ls -la ~/Library/Caches/MLX-Audio/mlx-community_Qwen3-ASR-0.6B-8bit

# 2. 检查音频文件
file test_30s.mp3
mdls -name kMDItemDurationSeconds test_30s.mp3

# 3. 查看日志
cat test_output.log
```

## 文件结构

```
ShenMan/
├── scripts/
│   ├── download_model.sh      # 模型下载脚本
│   └── test_transcription.sh  # 测试脚本
├── ShenManTests/
│   └── ShenManTests.swift     # 单元测试
├── test.mp3                   # 原始测试音频（10 分钟）
└── test_30s.mp3              # 剪辑后的测试音频（30 秒）
```

## 性能指标

**预期性能**（M1/M2 芯片）：

| 指标 | 目标值 |
|------|--------|
| 30 秒音频转录时间 | < 10 秒 |
| 实时因子 (RTF) | < 0.3 |
| 内存占用 | < 4GB |
| 启动时间 | < 3 秒 |

## 联系支持

如有问题，请查看：
- [GitHub Issues](https://github.com)
- [项目文档](../PRD.md)

---

**最后更新**: 2026-03-18
