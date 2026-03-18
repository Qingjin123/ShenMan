import Foundation
import AVFoundation

/// 音频元数据读取器
/// 使用 AVFoundation 读取音频文件的元数据
actor AudioMetadataReader {
    
    // MARK: - 错误类型
    
    enum AudioError: LocalizedError {
        case fileNotFound
        case noAudioTrack
        case unreadable
        case unsupportedFormat
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "文件不存在"
            case .noAudioTrack:
                return "文件中没有音频轨道"
            case .unreadable:
                return "无法读取文件"
            case .unsupportedFormat:
                return "不支持的文件格式"
            }
        }
    }
    
    // MARK: - 公开方法
    
    /// 读取音频文件元数据
    /// - Parameter url: 音频文件 URL
    /// - Returns: AudioFile 对象
    static func readMetadata(from url: URL) async throws -> AudioFile {
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioError.fileNotFound
        }
        
        // 获取文件扩展名
        let ext = url.pathExtension.lowercased()
        guard AudioFile.isSupported(extension: ext) else {
            throw AudioError.unsupportedFormat
        }
        
        // 使用 AVAsset 加载音频
        let asset = AVAsset(url: url)
        
        // 异步加载时长
        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
        } catch {
            throw AudioError.unreadable
        }
        
        // 加载轨道
        let tracks: [AVAssetTrack]
        do {
            tracks = try await asset.load(.tracks)
        } catch {
            throw AudioError.unreadable
        }
        
        // 查找音频轨道
        guard let audioTrack = tracks.first(where: { $0.mediaType == .audio }) else {
            throw AudioError.noAudioTrack
        }
        
        // 获取音频格式描述
        var sampleRate: Int = 44100
        var channels: Int = 2
        
        do {
            let formatDescriptions = try await audioTrack.load(.formatDescriptions)
            if let formatDescription = formatDescriptions.first {
                let asbd = formatDescription.audioStreamBasicDescription
                sampleRate = Int(asbd?.mSampleRate ?? 44100)
                channels = Int(asbd?.mChannelsPerFrame ?? 2)
            }
        } catch {
            // 使用默认值
        }
        
        // 获取文件大小
        let fileSize: Int64
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            fileSize = (attributes[.size] as? Int64) ?? 0
        } catch {
            fileSize = 0
        }
        
        // 创建 AudioFile 对象
        return AudioFile(
            url: url,
            filename: url.lastPathComponent,
            duration: CMTimeGetSeconds(duration),
            fileSize: fileSize,
            format: AudioFile.AudioFormat.from(extension: ext),
            sampleRate: sampleRate,
            channels: channels
        )
    }
    
    /// 验证文件格式
    /// - Parameter url: 文件 URL
    /// - Returns: 是否支持该格式
    static func validateFormat(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return AudioFile.isSupported(extension: ext)
    }
}