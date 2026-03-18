import Foundation

/// 错误恢复建议协议
/// 为错误提供恢复建议和操作指导
protocol ErrorRecoverySuggestion {
    /// 恢复建议
    var recoverySuggestion: String? { get }
    
    /// 是否可自动恢复
    var isRecoverable: Bool { get }
    
    /// 恢复操作（如果支持）
    func attemptRecovery() async -> Bool
}

// MARK: - ASRError 扩展

extension ASRError: ErrorRecoverySuggestion {
    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "请在设置中下载所需的 ASR 模型"
        case .modelLoadFailed:
            return "尝试重新下载模型或重启应用"
        case .audioLoadFailed:
            return "请检查音频文件是否损坏或格式是否正确"
        case .inferenceFailed:
            return "尝试使用更小的模型或减少音频长度"
        case .outOfMemory:
            return "请关闭其他应用释放内存后重试"
        case .cancelled:
            return nil
        case .unsupportedLanguage:
            return "请选择支持的语言或切换到自动语言检测"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .modelNotFound, .modelLoadFailed, .outOfMemory:
            return true
        default:
            return false
        }
    }
    
    func attemptRecovery() async -> Bool {
        switch self {
        case .modelNotFound, .modelLoadFailed:
            // 可以尝试重新下载模型
            return true
        case .outOfMemory:
            // 提示用户释放内存
            return false
        default:
            return false
        }
    }
}

// MARK: - FileError 扩展

extension FileError: ErrorRecoverySuggestion {
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "请检查文件路径是否正确"
        case .fileIsDirectory:
            return "请选择文件而不是目录"
        case .noPermission:
            return "请检查文件权限"
        case .writeFailed:
            return "请检查磁盘空间或目标目录权限"
        case .readFailed:
            return "请检查文件权限或文件是否损坏"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .fileNotFound, .readFailed, .writeFailed, .noPermission:
            return true
        default:
            return false
        }
    }
    
    func attemptRecovery() async -> Bool {
        // 默认不可恢复，需要用户干预
        return false
    }
}

// MARK: - ExportError 扩展

extension ExportError: ErrorRecoverySuggestion {
    var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            return "尝试使用其他编码格式"
        case .fileWriteFailed:
            return "请检查目标路径权限或磁盘空间"
        }
    }
    
    var isRecoverable: Bool {
        return true
    }
    
    func attemptRecovery() async -> Bool {
        // 默认不可自动恢复
        return false
    }
}

// MARK: - BatchProcessingError 扩展

extension BatchProcessingError: ErrorRecoverySuggestion {
    var recoverySuggestion: String? {
        switch self {
        case .emptyBatch:
            return "请添加至少一个文件到批处理队列"
        case .allTasksFailed:
            return "所有任务都失败了，请检查文件和模型状态"
        case .cancelled:
            return "批量处理已取消"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .emptyBatch:
            return true
        default:
            return false
        }
    }
    
    func attemptRecovery() async -> Bool {
        switch self {
        case .emptyBatch:
            // 无法自动恢复，需要用户添加文件
            return false
        default:
            return false
        }
    }
}

// MARK: - 错误恢复助手

/// 错误恢复助手
/// 提供统一的错误处理和恢复建议
struct ErrorRecoveryHelper {
    /// 显示错误详情
    static func showErrorDetails(_ error: Error) -> String {
        var message = "错误：\(error.localizedDescription)"
        
        if let recoverableError = error as? ErrorRecoverySuggestion,
           let suggestion = recoverableError.recoverySuggestion {
            message += "\n\n建议：\(suggestion)"
        }
        
        return message
    }
    
    /// 尝试恢复错误
    static func attemptRecovery(for error: Error) async -> Bool {
        guard let recoverableError = error as? ErrorRecoverySuggestion else {
            return false
        }
        
        if !recoverableError.isRecoverable {
            return false
        }
        
        return await recoverableError.attemptRecovery()
    }
    
    /// 错误日志
    static func logError(_ error: Error, context: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var logMessage = "[\(timestamp)] 错误在 \(context): \(error.localizedDescription)"
        
        if let recoverableError = error as? ErrorRecoverySuggestion,
           let suggestion = recoverableError.recoverySuggestion {
            logMessage += "\n建议：\(suggestion)"
        }
        
        print(logMessage)
    }
}
