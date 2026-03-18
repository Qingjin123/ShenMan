import Foundation
import AVFoundation

/// 音频文件模型
/// 封装音频文件的元数据信息
struct AudioFile: Sendable, Identifiable, Hashable {
    // MARK: - 属性
    
    /// 唯一标识符
    let id: UUID
    
    /// 文件 URL
    let url: URL
    
    /// 文件名（包含扩展名）
    let filename: String
    
    /// 音频时长（秒）
    let duration: TimeInterval
    
    /// 文件大小（字节）
    let fileSize: Int64
    
    /// 音频格式
    let format: AudioFormat
    
    /// 采样率（Hz）
    let sampleRate: Int
    
    /// 声道数
    let channels: Int
    
    // MARK: - 嵌套类型
    
    /// 音频格式枚举
    enum AudioFormat: String, Sendable, CaseIterable {
        case mp3, wav, m4a, flac, aac, ogg, wma
        case mp4, mov, avi, mkv, wmv
        case unknown
        
        /// 显示名称
        var displayName: String {
            rawValue.uppercased()
        }
        
        /// 是否为视频格式
        var isVideo: Bool {
            switch self {
            case .mp4, .mov, .avi, .mkv, .wmv:
                return true
            default:
                return false
            }
        }
        
        /// 从文件扩展名初始化
        static func from(extension ext: String) -> AudioFormat {
            AudioFormat(rawValue: ext.lowercased()) ?? .unknown
        }
    }
    
    // MARK: - 计算属性
    
    /// 格式化的时长字符串（HH:MM:SS 或 MM:SS）
    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 格式化的文件大小字符串
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// 格式化的采样率字符串
    var sampleRateFormatted: String {
        if sampleRate >= 1000 {
            return String(format: "%.1f kHz", Double(sampleRate) / 1000.0)
        } else {
            return "\(sampleRate) Hz"
        }
    }
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        url: URL,
        filename: String,
        duration: TimeInterval,
        fileSize: Int64,
        format: AudioFormat,
        sampleRate: Int,
        channels: Int
    ) {
        self.id = id
        self.url = url
        self.filename = filename
        self.duration = duration
        self.fileSize = fileSize
        self.format = format
        self.sampleRate = sampleRate
        self.channels = channels
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AudioFile, rhs: AudioFile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 支持的文件格式

extension AudioFile {
    /// 支持的音频格式扩展名列表
    static let supportedAudioFormats = ["mp3", "wav", "m4a", "flac", "aac", "ogg", "wma"]
    
    /// 支持的视频格式扩展名列表
    static let supportedVideoFormats = ["mp4", "mov", "avi", "mkv", "wmv"]
    
    /// 所有支持的格式扩展名列表
    static let allSupportedFormats = supportedAudioFormats + supportedVideoFormats
    
    /// 检查文件扩展名是否支持
    static func isSupported(extension ext: String) -> Bool {
        allSupportedFormats.contains(ext.lowercased())
    }
}