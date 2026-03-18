import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 常量定义
enum Constants {
    // MARK: - 应用信息

    /// 应用名称
    static let appName = "声声慢"

    /// 应用版本
    static let appVersion = "0.1.0"

    // MARK: - 支持的格式

    /// 支持的音频格式
    static let supportedAudioFormats = ["mp3", "wav", "m4a", "flac", "aac", "ogg", "wma"]

    /// 支持的视频格式
    static let supportedVideoFormats = ["mp4", "mov", "avi", "mkv", "wmv"]

    // MARK: - 默认模型

    /// 默认 ASR 模型
    static let defaultASRModel = ModelIdentifier.qwen3ASR06B8bit.rawValue

    /// 可用的 ASR 模型列表
    static let availableASRModels: [String] = [
        ModelIdentifier.qwen3ASR06B8bit.rawValue,
        ModelIdentifier.qwen3ASR17B8bit.rawValue,
        ModelIdentifier.glmASRNano4bit.rawValue,
    ]

    // MARK: - UI 常量

    /// 窗口最小宽度
    static let minWindowWidth: CGFloat = 900

    /// 窗口最小高度
    static let minWindowHeight: CGFloat = 600

    /// 默认间距
    enum Spacing: CGFloat {
        case xs = 4
        case s = 8
        case m = 16
        case l = 24
        case xl = 32
    }

    // MARK: - 转录常量

    /// 默认采样率
    static let defaultSampleRate = 16000

    /// 停顿阈值（秒）
    static let pauseThreshold: TimeInterval = 0.5

    /// 最大文件大小（2GB）
    static let maxFileSize: Int64 = 2 * 1024 * 1024 * 1024
}

// MARK: - 模型标识符

/// 模型标识符枚举 - 提供类型安全的模型 ID
enum ModelIdentifier: String, CaseIterable, Sendable {
    // Qwen3-ASR 模型
    case qwen3ASR06B8bit = "mlx-community/Qwen3-ASR-0.6B-8bit"
    case qwen3ASR17B8bit = "mlx-community/Qwen3-ASR-1.7B-8bit"
    
    // GLM-ASR 模型
    case glmASRNano4bit = "mlx-community/GLM-ASR-Nano-2512-4bit"

    /// 模型显示名称
    var displayName: String {
        switch self {
        case .qwen3ASR06B8bit:
            return "Qwen3-ASR 0.6B (8bit)"
        case .qwen3ASR17B8bit:
            return "Qwen3-ASR 1.7B (8bit)"
        case .glmASRNano4bit:
            return "GLM-ASR Nano (4bit)"
        }
    }

    /// 模型描述
    var description: String {
        switch self {
        case .qwen3ASR06B8bit, .qwen3ASR17B8bit:
            return "阿里开源，中文优化，支持 22 种方言"
        case .glmASRNano4bit:
            return "智谱开源，中文优化"
        }
    }

    /// 模型大小（GB）
    var sizeGB: Double {
        switch self {
        case .qwen3ASR06B8bit:
            return 0.6
        case .qwen3ASR17B8bit:
            return 1.7
        case .glmASRNano4bit:
            return 0.8
        }
    }

    /// 支持的语言
    var supportedLanguages: [Language] {
        switch self {
        case .qwen3ASR06B8bit, .qwen3ASR17B8bit:
            return [.auto, .chinese, .chineseCantonese, .chineseSichuan, .english, .japanese, .korean]
        case .glmASRNano4bit:
            return [.auto, .chinese, .english]
        }
    }
    
    /// 是否为 GLM 模型
    var isGLM: Bool {
        return self == .glmASRNano4bit
    }
    
    /// 是否为 Qwen 模型
    var isQwen: Bool {
        return self == .qwen3ASR06B8bit || self == .qwen3ASR17B8bit
    }
}

// MARK: - Notification.Name 扩展

extension Notification.Name {
    static let showFileImporter = Notification.Name("showFileImporter")
    static let showUnsupportedFormatError = Notification.Name("showUnsupportedFormatError")
}