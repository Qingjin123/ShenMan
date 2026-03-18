import SwiftUI

/// 模型选择器视图
/// 允许用户选择和管理 ASR 模型
struct ModelPickerView: View {
    // MARK: - 环境

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - 状态

    @StateObject private var modelManager = ModelManagerViewModel()
    @State private var selectedModelId: String
    @State private var isLoading = true

    // MARK: - 初始化

    init() {
        _selectedModelId = State(initialValue: Constants.defaultASRModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // 内容区
            Group {
                if isLoading {
                    loadingView
                } else {
                    listView
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.shenManBackground)
        .cornerRadius(12)
        .task {
            modelManager.checkDownloadStatus()
            isLoading = false
        }
    }
    
    private var titleBar: some View {
        HStack {
            Text("模型管理")
                .font(.shenManTitle2())
                .fontWeight(.bold)
            
            Spacer()
            
            // 关闭按钮
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("关闭")
        }
        .padding(.horizontal)
        .padding(.vertical)
    }
    
    // MARK: - 子视图
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: .spacingLG) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载模型列表...")
                .font(.shenManBody())
                .foregroundColor(.shenManTextSecondary)
        }
    }
    
    private var listView: some View {
        List {
            // 模型列表部分
            ForEach(groupedModels.keys.sorted(), id: \.self) { group in
                Section(header: sectionHeader(for: group)) {
                    ForEach(groupedModels[group] ?? []) { model in
                        ModelRow(
                            model: model,
                            isSelected: model.huggingFaceId == selectedModelId,
                            downloadState: modelManager.downloadState(for: model.huggingFaceId)
                        ) {
                            selectModel(model)
                        } downloadAction: {
                            await downloadModel(model.huggingFaceId)
                        }
                    }
                }
            }

            // 模型信息部分
            Section("模型说明") {
                VStack(alignment: .leading, spacing: .spacingSM) {
                    InfoRow(
                        icon: "cpu",
                        title: "Qwen3-ASR",
                        description: "阿里开源模型，中文优化，支持 22 种方言识别"
                    )

                    InfoRow(
                        icon: "cpu.fill",
                        title: "GLM-ASR",
                        description: "智谱开源模型，中文场景表现优秀"
                    )

                    InfoRow(
                        icon: "arrow.down.circle",
                        title: "下载管理",
                        description: "点击模型右侧的下载按钮即可下载模型到本地"
                    )

                    InfoRow(
                        icon: "sparkles",
                        title: "智能推荐",
                        description: "普通话推荐 Qwen3-ASR 0.6B，需要更高精度可选择 1.7B"
                    )
                }
                .padding(.vertical, .spacingSM)
            }
        }
    }
    
    // MARK: - 计算属性
    
    private var groupedModels: [String: [ModelInfo]] {
        var groups: [String: [ModelInfo]] = [:]
        
        for model in modelManager.models {
            let group = modelGroupName(for: model.huggingFaceId)
            if groups[group] == nil {
                groups[group] = []
            }
            groups[group]?.append(model)
        }
        
        return groups
    }
    
    // MARK: - 子视图
    
    private func sectionHeader(for group: String) -> some View {
        HStack {
            Image(systemName: groupIcon(for: group))
                .foregroundColor(.shenManPrimary)
                .frame(width: 24)
            
            Text(group)
                .font(.shenManBody())
                .foregroundColor(.shenManTextPrimary)
        }
    }
    
    // MARK: - 方法
    
    private func modelGroupName(for modelId: String) -> String {
        if modelId.contains("Qwen3") {
            return "Qwen3-ASR 系列"
        } else if modelId.contains("GLM") {
            return "GLM-ASR 系列"
        } else {
            return "其他模型"
        }
    }
    
    private func groupIcon(for group: String) -> String {
        switch group {
        case "Qwen3-ASR 系列":
            return "cpu"
        case "GLM-ASR 系列":
            return "cpu.fill"
        default:
            return "circle.grid.2x2"
        }
    }
    
    private func selectModel(_ model: ModelInfo) {
        selectedModelId = model.huggingFaceId
        appState.settings.selectedModel = model.huggingFaceId
        appState.settings.saveToUserDefaults()
    }
    
    private func downloadModel(_ modelId: String) async {
        await modelManager.downloadModel(modelId)
    }
}

// MARK: - 模型行

struct ModelRow: View {
    let model: ModelInfo
    let isSelected: Bool
    let downloadState: ModelDownloadState
    let selectAction: () -> Void
    let downloadAction: () async -> Void
    
    @State private var isDownloading = false
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // 选择指示器
            selectionIndicator
            
            // 模型信息
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack(spacing: .spacingSM) {
                    Text(model.name)
                        .font(.shenManBody())
                        .foregroundColor(.shenManTextPrimary)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.shenManPrimary)
                    }
                }
                
                Text(model.description)
                    .font(.shenManCaption())
                    .foregroundColor(.shenManTextTertiary)
                    .lineLimit(2)
                
                // 模型元数据
                HStack(spacing: .spacingSM) {
                    Label(
                        String(format: "%.1f GB", model.sizeGB),
                        systemImage: "internaldrive"
                    )
                    .font(.system(size: 11))
                    .foregroundColor(.shenManTextTertiary)
                    
                    ForEach(model.supportedLanguages.prefix(3), id: \.self) { lang in
                        Text(lang.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.shenManTextTertiary)
                    }
                }
            }
            
            Spacer()
            
            // 下载按钮/状态
            downloadButton
        }
        .padding(.vertical, .spacingSM)
    }
    
    private var selectionIndicator: some View {
        Circle()
            .strokeBorder(
                isSelected ? Color.shenManPrimary : Color.shenManBorder,
                lineWidth: 2
            )
            .background(
                Circle().fill(isSelected ? Color.shenManPrimary.opacity(0.1) : Color.clear)
            )
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? Color.shenManPrimary : Color.clear)
            )
    }
    
    @ViewBuilder
    private var downloadButton: some View {
        switch downloadState {
        case .notDownloaded:
            Button(action: {
                Task {
                    isDownloading = true
                    await downloadAction()
                    isDownloading = false
                }
            }) {
                Label("下载", systemImage: "arrow.down.circle")
                    .font(.shenManCaption())
            }
            .disabled(isDownloading)
            
        case .downloading(let progress):
            VStack(spacing: .spacingXS) {
                ProgressView(value: progress)
                    .frame(width: 60)
                
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 10))
                    .foregroundColor(.shenManTextTertiary)
            }
            
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)
            
        case .failed(let error):
            VStack(spacing: .spacingXS) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.system(size: 9))
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - 信息行

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.shenManPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(title)
                    .font(.shenManBody())
                    .foregroundColor(.shenManTextPrimary)
                
                Text(description)
                    .font(.shenManCaption())
                    .foregroundColor(.shenManTextTertiary)
            }
        }
    }
}

// MARK: - 预览

#if DEBUG
struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView()
            .environmentObject(AppState())
    }
}
#endif
