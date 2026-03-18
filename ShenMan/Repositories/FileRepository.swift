import Foundation

/// 文件仓库
/// 负责文件的读取和写入操作
///
/// ## Swift 6 并发安全说明
///
/// 本类型使用 `@unchecked Sendable` 因为：
/// 1. **FileManager 限制**: `FileManager` 类型本身不是 `Sendable`，这是 Foundation 框架的限制
/// 2. **实际安全性**: `FileManager` 是线程安全的，所有方法都是线程安全的
/// 3. **使用模式**: 本类型的方法都是简单的委托调用，没有可变状态
final class FileRepository: @unchecked Sendable {

    // MARK: - 属性

    private let fileManager: FileManager

    // MARK: - 初始化

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - 公开方法

    /// 读取文件内容
    /// - Parameter url: 文件 URL
    /// - Returns: 文件数据
    func readFile(at url: URL) throws -> Data {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileError.fileNotFound
        }
        return try Data(contentsOf: url)
    }

    /// 写入文件
    /// - Parameters:
    ///   - data: 文件数据
    ///   - url: 目标 URL
    ///   - createIntermediateDirectories: 是否创建中间目录
    func writeFile(_ data: Data, to url: URL, createIntermediateDirectories: Bool = true) throws {
        if createIntermediateDirectories {
            let directory = url.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try data.write(to: url)
    }

    /// 删除文件
    /// - Parameter url: 文件 URL
    func deleteFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileError.fileNotFound
        }
        try fileManager.removeItem(at: url)
    }

    /// 检查文件是否存在
    /// - Parameter url: 文件 URL
    /// - Returns: 是否存在
    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    /// 获取文件大小
    /// - Parameter url: 文件 URL
    /// - Returns: 文件大小（字节）
    func fileSize(at url: URL) throws -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileError.fileNotFound
        }
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? Int64) ?? 0
    }

    /// 复制文件
    /// - Parameters:
    ///   - sourceURL: 源文件 URL
    ///   - destinationURL: 目标文件 URL
    func copyFile(from sourceURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileError.fileNotFound
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    /// 移动文件
    /// - Parameters:
    ///   - sourceURL: 源文件 URL
    ///   - destinationURL: 目标文件 URL
    func moveFile(from sourceURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileError.fileNotFound
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }

    /// 获取临时目录 URL
    /// - Returns: 临时目录 URL
    func temporaryDirectory() -> URL {
        fileManager.temporaryDirectory
    }

    /// 创建临时文件 URL
    /// - Parameters:
    ///   - directory: 目录 URL
    ///   - extension: 文件扩展名
    /// - Returns: 临时文件 URL
    func makeTemporaryFileURL(in directory: URL? = nil, extension ext: String = "tmp") -> URL {
        let directory = directory ?? temporaryDirectory()
        return directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
    }
}

// MARK: - 文件错误

enum FileError: LocalizedError {
    case fileNotFound
    case fileIsDirectory
    case noPermission
    case writeFailed(String)
    case readFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件不存在"
        case .fileIsDirectory:
            return "路径是一个目录，不是文件"
        case .noPermission:
            return "没有文件访问权限"
        case .writeFailed(let reason):
            return "写入失败：\(reason)"
        case .readFailed(let reason):
            return "读取失败：\(reason)"
        }
    }
}
