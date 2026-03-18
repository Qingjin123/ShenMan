import Foundation
import SwiftUI
import MLXAudioCore
import MLXAudioSTT

/// 模型下载状态
enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(String)

    static func == (lhs: ModelDownloadState, rhs: ModelDownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded),
             (.downloaded, .downloaded):
            return true
        case (.downloading(let l), .downloading(let r)):
            return abs(l - r) < 0.01
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

/// 模型管理器
@MainActor
class ModelManagerViewModel: ObservableObject {
    // MARK: - 属性

    /// 模型下载状态
    @Published var downloadStates: [String: ModelDownloadState] = [:]

    /// 当前正在下载的模型
    @Published var currentDownloadingModel: String?

    /// 模型信息列表（使用 ModelIdentifier 确保类型安全）
    let models: [ModelInfo]

    // MARK: - 初始化

    init() {
        self.models = Constants.availableASRModels.map { modelId in
            ModelInfo.from(huggingFaceId: modelId)
        }
        checkDownloadStatus()
    }

    // MARK: - 公开方法

    /// 检查模型下载状态
    func checkDownloadStatus() {
        for model in models {
            let isDownloaded = isModelDownloaded(model.huggingFaceId)
            downloadStates[model.huggingFaceId] = isDownloaded ? .downloaded : .notDownloaded
        }
    }

    /// 检查模型是否已下载
    func isModelDownloaded(_ modelId: String) -> Bool {
        // 检查模型缓存目录
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let cacheDir = cacheDir else { return false }

        let modelDir = cacheDir
            .appendingPathComponent("MLX-Audio", isDirectory: true)
            .appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "_"), isDirectory: true)

        return FileManager.default.fileExists(atPath: modelDir.path)
    }

    /// 下载模型
    func downloadModel(_ modelId: String) async {
        guard downloadStates[modelId] != .downloading(progress: 0) else { return }

        currentDownloadingModel = modelId
        downloadStates[modelId] = .downloading(progress: 0)

        do {
            // 创建模型并下载
            let model: ASRModel = Qwen3ASRModelWrapper(huggingFaceId: modelId)
            try await model.download { progress in
                Task { @MainActor in
                    self.downloadStates[modelId] = .downloading(progress: progress)
                }
            }

            downloadStates[modelId] = .downloaded
        } catch {
            downloadStates[modelId] = .failed(error.localizedDescription)
        }

        currentDownloadingModel = nil
    }

    /// 取消下载
    func cancelDownload(_ modelId: String) {
        // 目前由模型内部处理取消
        downloadStates[modelId] = .notDownloaded
        currentDownloadingModel = nil
    }

    /// 删除模型
    func deleteModel(_ modelId: String) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let cacheDir = cacheDir else { return }

        let modelDir = cacheDir
            .appendingPathComponent("MLX-Audio", isDirectory: true)
            .appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "_"), isDirectory: true)

        do {
            try FileManager.default.removeItem(at: modelDir)
            downloadStates[modelId] = .notDownloaded
        } catch {
            print("Failed to delete model: \(error)")
        }
    }

    /// 获取模型下载状态
    func downloadState(for modelId: String) -> ModelDownloadState {
        downloadStates[modelId] ?? .notDownloaded
    }
}
