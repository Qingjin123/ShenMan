import Foundation

/// 依赖注入容器
/// 管理应用的生命周期和依赖关系
///
/// ## 使用示例
/// ```swift
/// // 配置容器
/// let container = DependencyContainer()
/// container.register(TranscriptionServiceProtocol.self) { _ in
///     TranscriptionService()
/// }
///
/// // 解析依赖
/// let service: TranscriptionServiceProtocol = container.resolve()
/// ```
final class DependencyContainer: @unchecked Sendable {

    // MARK: - 属性

    /// 共享容器
    static let shared = DependencyContainer()

    /// 服务注册表
    private var services: [String: Any] = [:]

    /// 单例注册表
    private var singletons: [String: Any] = [:]

    /// 锁保护并发访问
    private let lock = NSLock()

    // MARK: - 注册

    /// 注册服务
    /// - Parameters:
    ///   - protocolType: 协议类型
    ///   - factory: 工厂闭包
    func register<Service>(_ protocolType: Service.Type, factory: @escaping (DependencyContainer) -> Service) {
        let key = String(describing: protocolType)
        lock.lock()
        defer { lock.unlock() }
        services[key] = factory
    }

    /// 注册单例
    /// - Parameters:
    ///   - protocolType: 协议类型
    ///   - factory: 工厂闭包
    func registerSingleton<Service>(_ protocolType: Service.Type, factory: @escaping (DependencyContainer) -> Service) {
        let key = String(describing: protocolType)
        lock.lock()
        defer { lock.unlock() }
        
        // 立即创建并存储单例
        let instance = factory(self)
        singletons[key] = instance
    }

    // MARK: - 解析

    /// 解析服务
    /// - Parameter protocolType: 协议类型
    /// - Returns: 服务实例
    func resolve<Service>(_ protocolType: Service.Type) -> Service {
        let key = String(describing: protocolType)
        
        // 先检查单例
        lock.lock()
        if let instance = singletons[key] as? Service {
            lock.unlock()
            return instance
        }
        lock.unlock()
        
        // 从工厂创建
        guard let factory = services[key] as? (DependencyContainer) -> Service else {
            fatalError("Service \(key) not registered")
        }
        
        return factory(self)
    }

    /// 解析可选服务
    /// - Parameter protocolType: 协议类型
    /// - Returns: 服务实例（如果已注册）
    func resolve<Service>(_ protocolType: Service.Type) -> Service? {
        let key = String(describing: protocolType)
        
        // 先检查单例
        lock.lock()
        if let instance = singletons[key] as? Service {
            lock.unlock()
            return instance
        }
        lock.unlock()
        
        // 从工厂创建
        guard let factory = services[key] as? (DependencyContainer) -> Service else {
            return nil
        }
        
        return factory(self)
    }

    // MARK: - 重置

    /// 重置容器（用于测试）
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        services.removeAll()
        singletons.removeAll()
    }
}

// MARK: - 服务协议

/// 转录服务协议
protocol TranscriptionServiceProtocol: Sendable {
    func transcribe(
        audioFile: AudioFile,
        model: ASRModel,
        language: Language?,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> TranscriptionResult
    
    func cancel()
    func updateSettings(from settings: AppSettings)
}

// MARK: - 历史记录仓库协议

/// 历史记录仓库协议
protocol HistoryRepositoryProtocol: Sendable {
    func getAllHistory() async -> [TranscriptionHistoryRecord]
    func getRecentHistory(limit: Int) async -> [TranscriptionHistoryRecord]
    func getFavorites() async -> [TranscriptionHistoryRecord]
    func getHistoryRecord(id: UUID) async -> TranscriptionHistoryRecord?
    func addHistoryRecord(_ record: TranscriptionHistoryRecord) async
    func addHistoryRecord(from result: TranscriptionResult, transcript: String) async -> TranscriptionHistoryRecord
    func updateHistoryRecord(_ record: TranscriptionHistoryRecord) async
    func deleteHistoryRecord(id: UUID) async
    func deleteAllHistory() async
    func toggleFavorite(id: UUID) async
    func addTag(id: UUID, tag: String) async
    func removeTag(id: UUID, tag: String) async
    func searchHistory(query: String) async -> [TranscriptionHistoryRecord]
}

// MARK: - 文件仓库协议

protocol FileRepositoryProtocol: Sendable {
    func fileExists(at url: URL) -> Bool
    func readFile(at url: URL) throws -> Data
    func writeFile(_ data: Data, to url: URL) throws
    func deleteFile(at url: URL) throws
    func createDirectory(at url: URL) throws
}

// MARK: - 容器配置

extension DependencyContainer {
    /// 配置默认服务
    func configureDefaultServices() {
        // 注册文件仓库
        register(FileRepository.self) { _ in
            FileRepository()
        }
        
        // 注册历史记录仓库
        register(HistoryRepository.self) { _ in
            HistoryRepository()
        }
        
        // 注册转录服务
        register(TranscriptionService.self) { _ in
            TranscriptionService()
        }
    }
}

// MARK: - 协议一致性扩展

// TranscriptionService 符合 TranscriptionServiceProtocol
extension TranscriptionService: TranscriptionServiceProtocol {}

// HistoryRepository 符合 HistoryRepositoryProtocol
extension HistoryRepository: HistoryRepositoryProtocol {}

// FileRepository 已在原文件中声明为 @unchecked Sendable
