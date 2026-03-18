import Foundation

/// 语言枚举
/// 支持的识别语言
enum Language: String, CaseIterable, Identifiable, Sendable, Codable {
    case auto = "auto"               // 自动检测
    case chinese = "zh"              // 中文普通话
    case chineseCantonese = "zh-yue" // 粤语
    case chineseSichuan = "zh-sichuan" // 川渝话
    case english = "en"              // 英语
    case japanese = "ja"             // 日语
    case korean = "ko"               // 韩语

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .auto: return "自动检测"
        case .chinese: return "中文普通话"
        case .chineseCantonese: return "粤语"
        case .chineseSichuan: return "川渝话"
        case .english: return "英语"
        case .japanese: return "日语"
        case .korean: return "韩语"
        }
    }

    /// Qwen3-ASR 语言代码
    var qwenLanguageCode: String {
        switch self {
        case .auto: return "auto"
        case .chinese: return "Chinese"
        case .chineseCantonese: return "Chinese Cantonese"
        case .chineseSichuan: return "Chinese Sichuan"
        case .english: return "English"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        }
    }
}