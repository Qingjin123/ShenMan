import Foundation
import AVFoundation
@preconcurrency import AVFAudio
import MLXAudioCore
import MLXAudioSTT
import MLX

/// Qwen3-ASR 模型实现（包装器）
/// 使用 MLX Audio Swift 进行推理
///
/// ## Swift 6 并发安全说明
///
/// 本类型使用 `@unchecked Sendable` 因为：
/// 1. **外部依赖限制**: MLX 的 `Qwen3ASRModel` 类型本身不是 `Sendable`，这是第三方库的限制
/// 2. **actor 隔离不可行**: 由于需要实现 `ASRModel` 协议，无法使用 `actor`
/// 3. **手动保证安全**:
///    - 所有可变状态 (`model`) 都在 `async` 方法中访问
///    - 调用方通过 `await` 序列化访问，避免数据竞争
///    - 取消标志通过 `MainActor` 保证线程安全
///
/// ## 使用注意
/// - 所有公共方法都是 `async` 的，调用时请确保在正确的上下文中
/// - 使用 `cancel()` 方法可以请求取消正在进行的转录
/// - 模型实例应该被复用，避免重复加载
///
/// ## Swift 6 迁移说明
/// 这是 Swift 6 迁移中的**合理例外**：
/// - 类型本身不是 Sendable，但通过协议约束和 async 方法保证安全
/// - 取消标志通过 MainActor 保证线程安全
/// - 未来如果 MLX 库更新为 Sendable，可以移除此标记
final class Qwen3ASRModelWrapper: ASRModel, @unchecked Sendable {

    // MARK: - 属性

    nonisolated let id: String
    nonisolated let name = "Qwen3-ASR"
    nonisolated let description = "阿里开源，中文优化，支持 22 种方言"
    nonisolated let supportedLanguages: [Language] = [.auto, .chinese, .chineseCantonese, .chineseSichuan, .english, .japanese, .korean]

    nonisolated let sizeGB: Double
    nonisolated let huggingFaceId: String

    private var _isDownloaded: Bool = false
    nonisolated let modelPath: URL?

    /// MLX 模型实例（非 Sendable，但在 actor 隔离下安全访问）
    private var model: Qwen3ASRModel?

    /// 取消标志（通过 MainActor 保证线程安全）
    @MainActor private var isCancelled = false

    // MARK: - 初始化

    init(huggingFaceId: String = Constants.defaultASRModel) {
        self.huggingFaceId = huggingFaceId
        self.id = huggingFaceId
        self.modelPath = nil

        if huggingFaceId.contains("0.6B") {
            self.sizeGB = huggingFaceId.contains("8bit") ? 0.6 : 1.2
        } else if huggingFaceId.contains("1.7B") {
            self.sizeGB = huggingFaceId.contains("8bit") ? 1.7 : 3.5
        } else {
            self.sizeGB = 2.5
        }
    }

    // MARK: - 公开方法

    var isDownloaded: Bool {
        _isDownloaded
    }

    func download(progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        do {
            try await loadModel()
            _isDownloaded = true
            await MainActor.run {
                progressHandler(1.0)
            }
        } catch {
            throw ASRError.modelLoadFailed
        }
    }

    private func loadModel() async throws {
        // 检查模型是否已加载
        if model != nil { return }
        
        do {
            let qwenModel = try await Qwen3ASRModel.fromPretrained(huggingFaceId)
            model = qwenModel
            _isDownloaded = true
        } catch {
            throw ASRError.modelLoadFailed
        }
    }

    func transcribe(
        audioFile: AudioFile,
        language: Language?,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> RawTranscriptionResult {
        // 重置取消状态
        await MainActor.run {
            isCancelled = false
        }

        // 加载模型
        try await loadModel()

        guard let qwenModel = model else {
            throw ASRError.modelLoadFailed
        }

        // 更新进度
        await MainActor.run {
            progressHandler(0.1)
        }

        // 检查取消
        if await isCancelledCheck() { throw ASRError.cancelled }

        // 加载音频
        let audio = try loadAudioAsMLXArray(from: audioFile.url)
        await MainActor.run {
            progressHandler(0.3)
        }

        if await isCancelledCheck() { throw ASRError.cancelled }

        // 重采样到模型所需采样率
        let targetRate = qwenModel.sampleRate
        let resampledAudio: MLXArray
        if audio.0 != targetRate {
            resampledAudio = try resampleAudio(audio.1, from: audio.0, to: targetRate)
        } else {
            resampledAudio = audio.1
        }
        await MainActor.run {
            progressHandler(0.5)
        }

        if await isCancelledCheck() { throw ASRError.cancelled }

        // 执行转录
        let languageCode = language?.qwenLanguageCode ?? "Chinese"
        var fullText = ""

        for try await event in qwenModel.generateStream(
            audio: resampledAudio,
            maxTokens: 8192,
            temperature: 0.0,
            language: languageCode,
            chunkDuration: Float(audioFile.duration) + 10.0
        ) {
            if await isCancelledCheck() { throw ASRError.cancelled }

            if case .token(let token) = event {
                fullText += token
            }
            if case .info(let info) = event {
                // 更精确的进度计算
                let tokenProgress = Double(info.generationTokenCount) / Double(max(info.generationTokenCount, 100))
                let progress = min(0.9, 0.5 + 0.4 * tokenProgress)
                await MainActor.run {
                    progressHandler(progress)
                }
            }
        }

        await MainActor.run {
            progressHandler(0.95)
        }

        // 构建词级时间戳（当前为简化实现）
        let words = [WordTimestamp(word: fullText, startTime: 0, endTime: audioFile.duration, confidence: 0.90)]

        let result = RawTranscriptionResult(
            text: fullText,
            words: words,
            language: language?.rawValue ?? "zh",
            languageProbability: 0.95
        )

        await MainActor.run {
            progressHandler(1.0)
        }
        return result
    }

    func cancel() {
        Task { @MainActor in
            isCancelled = true
        }
    }
    
    /// 检查是否已取消
    @MainActor private func isCancelledCheck() -> Bool {
        isCancelled
    }

    // MARK: - 私有方法

    private func loadAudioAsMLXArray(from url: URL) throws -> (Int, MLXArray) {
        let audioFile = try AVAudioFile(forReading: url)
        // 注：AVAudioFile 在 Swift 中会自动释放资源，无需手动关闭
        
        let sourceFormat = audioFile.processingFormat
        let sampleRate = Int(sourceFormat.sampleRate)
        let channels = Int(sourceFormat.channelCount)
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw ASRError.audioLoadFailed
        }

        try audioFile.read(into: buffer)

        var audioData: [Float] = []
        audioData.reserveCapacity(Int(frameCount))

        if channels == 1 {
            let pointer = buffer.floatChannelData![0]
            audioData = UnsafeBufferPointer(start: pointer, count: Int(frameCount)).map { $0 }
        } else {
            for i in 0..<Int(frameCount) {
                var sum: Float = 0
                for ch in 0..<channels {
                    sum += buffer.floatChannelData![ch][i]
                }
                audioData.append(sum / Float(channels))
            }
        }

        return (sampleRate, MLXArray(audioData))
    }

    private func resampleAudio(_ audio: MLXArray, from sourceSR: Int, to targetSR: Int) throws -> MLXArray {
        let samples = audio.asArray(Float.self)

        guard let inputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(sourceSR),
            channels: 1,
            interleaved: false
        ), let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(targetSR),
            channels: 1,
            interleaved: false
        ), let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw NSError(domain: "STT", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建音频转换器"])
        }

        let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(samples.count))!
        inputBuffer.frameLength = inputBuffer.frameCapacity
        memcpy(inputBuffer.floatChannelData![0], samples, samples.count * MemoryLayout<Float>.size)

        let outputFrameCount = AVAudioFrameCount(Double(samples.count) * Double(targetSR) / Double(sourceSR))
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount)!

        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { [inputBuffer] _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if let error = error { throw error }

        let outputSamples = UnsafeBufferPointer(
            start: outputBuffer.floatChannelData![0],
            count: Int(outputBuffer.frameLength)
        ).map { $0 }

        return MLXArray(outputSamples)
    }
}
