# MLX Audio Swift 使用指南

## 概述

`mlx-audio-swift` 是 `mlx-audio` (Python) 的 Swift 封装，提供 TTS、STT、STS 功能。

## 模块结构

```
MLXAudioSTT/           # Speech-to-Text
  ├── Models/
  │   ├── Qwen3ASR/           # Qwen3-ASR 模型
  │   ├── GLMASR/             # GLM-ASR 模型
  │   ├── Whisper/            # Whisper 模型
  │   └── ...
  ├── Streaming/              # 流式推理
  └── Generation.swift        # 生成协议

MLXAudioTTS/           # Text-to-Speech
MLXAudioSTS/           # Speech-to-Speech
MLXAudioCore/          # 核心工具
MLXAudioUI/            # UI 组件
```

## STT 使用方式

### 1. 导入模块

```swift
import MLXAudioSTT
import MLXAudioCore
import MLX
```

### 2. 加载模型

```swift
// 使用 Qwen3ASRModel
let model = try await Qwen3ASRModel.fromPretrained("mlx-community/Qwen3-ASR-0.6B-4bit")
```

**注意**：`Qwen3ASRModel` 是 `Module` 的子类，不是协议。

### 3. 准备音频

```swift
// 加载音频为 MLXArray
func loadAudioArray(from url: URL) throws -> (Int, MLXArray) {
    let audioFile = try AVAudioFile(forReading: url)
    let sourceFormat = audioFile.processingFormat
    let sampleRate = Int(sourceFormat.sampleRate)
    let channels = Int(sourceFormat.channelCount)
    
    let frameCount = AVAudioFrameCount(audioFile.length)
    guard let buffer = AVAudioBuffer(format: sourceFormat, frameCapacity: frameCount) else {
        throw NSError(domain: "Audio", code: 1)
    }
    
    try audioFile.read(into: buffer)
    
    // 转换为 Float 数组
    let audioData: [Float]
    if channels == 1 {
        audioData = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(frameCount)))
    } else {
        // 混合为单声道
        audioData = (0..<Int(frameCount)).map { i in
            var sum: Float = 0
            for ch in 0..<channels {
                sum += buffer.floatChannelData![ch][i]
            }
            return sum / Float(channels)
        }
    }
    
    return (sampleRate, MLXArray(audioData))
}
```

### 4. 执行转录

#### 方式 A：一次性生成

```swift
let output = model.generate(audio: audioArray, language: "Chinese")
print(output.text)
```

#### 方式 B：流式生成（推荐）

```swift
// 注意：generateStream 的参数是独立的，不是 STTGenerateParameters
for try await event in model.generateStream(
    audio: audioArray,
    maxTokens: 8192,
    temperature: 0.0,
    language: "Chinese",
    chunkDuration: 1200.0
) {
    switch event {
    case .token(let token):
        print(token, terminator: "")
    case .info(let info):
        // info.generationTokenCount, info.tokensPerSecond, info.peakMemoryUsage
        print("\nSpeed: \(info.tokensPerSecond) tok/s")
    case .result(let result):
        print("\nFinal: \(result.text)")
    }
}
```

### 5. 输出结构

```swift
public struct STTOutput {
    public let text: String
    public let segments: [[String: Any]]?  // 带时间戳的分段
    public let language: String?
    public let promptTokens: Int
    public let generationTokens: Int
    public let totalTokens: Int
    public let promptTps: Double
    public let generationTps: Double
    public let totalTime: Double
    public let peakMemoryUsage: Double
}

public struct STTGenerationInfo {
    public let promptTokenCount: Int
    public let generationTokenCount: Int
    public let prefillTime: TimeInterval
    public let generateTime: TimeInterval
    public let tokensPerSecond: Double
    public let peakMemoryUsage: Double
}
```

### 6. 生成参数

`generateStream` 方法使用独立参数（不是 `STTGenerateParameters` 结构体）：

```swift
func generateStream(
    audio: MLXArray,
    maxTokens: Int = 8192,
    temperature: Float = 0.0,
    language: String = "English",
    chunkDuration: Float = 1200.0,
    minChunkDuration: Float = 1.0
) -> AsyncThrowingStream<STTGeneration, Error>
```

**参数说明**：
- `maxTokens`: 最大生成 token 数（默认 8192）
- `temperature`: 采样温度，0.0 表示贪婪解码（默认 0.0）
- `language`: 语言名称（"English", "Chinese", "Chinese Cantonese" 等）
- `chunkDuration`: 长音频分块大小，单位秒（默认 1200.0 = 20 分钟）
- `minChunkDuration`: 最小分块大小，单位秒（默认 1.0）

### 7. 语言代码

```swift
// Qwen3-ASR 支持的语言
let languages = [
    "English",
    "Chinese",
    "Chinese Cantonese",
    "Chinese Sichuan",
    "Japanese",
    "Korean",
    // ... 更多
]
```

## 完整示例

```swift
import Foundation
import MLXAudioSTT
import MLXAudioCore
import MLX
import AVFoundation

@main
struct STTExample {
    static func main() async throws {
        // 1. 加载模型
        print("Loading model...")
        let model = try await Qwen3ASRModel.fromPretrained(
            "mlx-community/Qwen3-ASR-0.6B-8bit"
        )
        print("Model loaded: \(model.config.modelType)")
        
        // 2. 加载音频
        let audioURL = URL(fileURLWithPath: "test.wav")
        let (sampleRate, audio) = try loadAudioArray(from: audioURL)
        print("Audio loaded: \(sampleRate)Hz, \(audio.dim(0)) samples")
        
        // 3. 重采样（如果需要）
        let targetRate = model.sampleRate  // 16000
        let resampledAudio: MLXArray
        if sampleRate != targetRate {
            print("Resampling \(sampleRate)Hz → \(targetRate)Hz...")
            resampledAudio = try resampleAudio(audio, from: sampleRate, to: targetRate)
        } else {
            resampledAudio = audio
        }
        
        // 4. 执行转录（流式）
        print("Transcribing...")
        var fullText = ""
        
        for try await event in model.generateStream(
            audio: resampledAudio,
            maxTokens: 8192,
            temperature: 0.0,
            language: "Chinese",
            chunkDuration: Float(60.0)  // 60 秒音频
        ) {
            switch event {
            case .token(let token):
                fullText += token
                print(token, terminator: "")
            case .info(let info):
                print("\nSpeed: \(String(format: "%.1f", info.tokensPerSecond)) tok/s, Memory: \(String(format: "%.2f", info.peakMemoryUsage)) GB")
            case .result(let result):
                print("\n\n=== Final Result ===")
                print(result.text)
                print("Tokens: \(result.totalTokens), Time: \(String(format: "%.2f", result.totalTime))s")
            }
        }
    }
    
    static func loadAudioArray(from url: URL) throws -> (Int, MLXArray) {
        let audioFile = try AVAudioFile(forReading: url)
        let sourceFormat = audioFile.processingFormat
        let sampleRate = Int(sourceFormat.sampleRate)
        let channels = Int(sourceFormat.channelCount)
        
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard let buffer = AVAudioBuffer(format: sourceFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "Audio", code: 1)
        }
        
        try audioFile.read(into: buffer)
        
        let audioData: [Float]
        if channels == 1 {
            audioData = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(frameCount)))
        } else {
            audioData = (0..<Int(frameCount)).map { i in
                var sum: Float = 0
                for ch in 0..<channels {
                    sum += buffer.floatChannelData![ch][i]
                }
                return sum / Float(channels)
            }
        }
        
        return (sampleRate, MLXArray(audioData.map { Float32($0) }))
    }
    
    static func resampleAudio(_ audio: MLXArray, from sourceSR: Int, to targetSR: Int) throws -> MLXArray {
        // 使用 AVAudioConverter 重采样
        // 实现参考 Qwen3ASRModelWrapper.resampleAudio
    }
}
```

## VoicesApp 示例分析

### STTViewModel 结构

```swift
@MainActor
@Observable
class STTViewModel {
    // 模型
    var modelId: String = "mlx-community/Qwen3-ASR-0.6B-4bit"
    private var model: Qwen3ASRModel?
    
    // 状态
    var isLoading = false
    var isGenerating = false
    var transcriptionText: String = ""
    var errorMessage: String?
    
    // 加载模型
    func loadModel() async {
        model = try await Qwen3ASRModel.fromPretrained(modelId)
    }
    
    // 转录
    func transcribe(audioURL: URL) async {
        guard let model = model else { return }
        
        let (sampleRate, audio) = try loadAudioArray(from: audioURL)
        let resampled = try resampleAudio(audio, from: sampleRate, to: model.sampleRate)
        
        for try await event in model.generateStream(...) {
            switch event {
            case .token(let token):
                transcriptionText += token
            case .info(let info):
                tokensPerSecond = info.tokensPerSecond
            }
        }
    }
}
```

## 关键要点

1. **Qwen3ASRModel 是具体类型**，不是协议
   - 位于 `MLXAudioSTT` 模块
   - 继承自 `Module`
   - 有 `static func fromPretrained(_ modelPath: String)` 方法

2. **音频格式要求**
   - 单声道
   - 16kHz 采样率（模型会自动检查并重采样）
   - `MLXArray` 类型

3. **流式 API**
   - `generateStream(audio:language:)` 返回 `AsyncThrowingStream<STTGeneration, Error>`
   - 事件类型：`.token`, `.info`, `.result`

4. **语言参数**
   - 使用英文语言名称：`"English"`, `"Chinese"`, `"Chinese Cantonese"` 等
   - 不是语言代码（如 `"en"`, `"zh"`）

5. **模型路径**
   - HuggingFace 模型 ID：`mlx-community/Qwen3-ASR-0.6B-4bit`
   - 首次使用会自动下载

## 项目集成

### Package.swift

```swift
dependencies: [
    .package(
        url: "https://github.com/Blaizzy/mlx-audio-swift.git",
        branch: "main"
    )
]
```

### 目标配置

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "MLXAudioSTT", package: "mlx-audio-swift"),
        .product(name: "MLXAudioCore", package: "mlx-audio-swift")
    ]
)
```

## 错误处理

```swift
do {
    let model = try await Qwen3ASRModel.fromPretrained(modelId)
} catch {
    // 可能是网络错误、模型不存在等
    print("Failed to load model: \(error)")
}

do {
    for try await event in model.generateStream(...) {
        // 处理事件
    }
} catch is CancellationError {
    // 用户取消
    Memory.clearCache()
} catch {
    // 转录错误
    print("Transcription failed: \(error)")
}
```

## 性能优化

1. **模型量化**：使用 4bit 或 8bit 版本减小内存占用
2. **流式处理**：避免长时间等待，实时显示结果
3. **内存管理**：使用 `Memory.clearCache()` 清理缓存
4. **长音频分块**：`chunkDuration` 参数控制分块大小（默认 20 分钟）

---

**最后更新**：2026-03-17
**参考版本**：mlx-audio-swift main branch
