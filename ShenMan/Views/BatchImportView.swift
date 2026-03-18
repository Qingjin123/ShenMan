import SwiftUI
import UniformTypeIdentifiers

/// 批量导入视图
/// 支持一次导入多个音频文件进行批量转录
struct BatchImportView: View {
    // MARK: - 环境

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - 状态

    @StateObject private var viewModel = BatchProcessingViewModel()
    @State private var files: [AudioFile] = []
    @State private var isShowingFilePicker = false
    @State private var selectedModelId: ModelIdentifier = .qwen3ASR06B8bit
    @State private var isShowingProgressSheet = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // 内容区
            Group {
                if files.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color.shenManBackground)
        .cornerRadius(12)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.audio, .movie],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $isShowingProgressSheet) {
            ProcessingProgressView(viewModel: viewModel)
        }
    }
    
    private var titleBar: some View {
        HStack {
            Text("批量导入")
                .font(.shenManTitle2())
                .fontWeight(.bold)
            
            Spacer()
            
            if !files.isEmpty && !viewModel.isProcessing {
                Button("开始转录") {
                    startBatchTranscription()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
                .frame(height: 24)
            
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
    private var emptyStateView: some View {
        VStack(spacing: .spacingLG) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 64))
                .foregroundColor(.shenManTextTertiary)
            
            Text("拖放文件到此处")
                .font(.shenManHeadline())
                .foregroundColor(.shenManTextPrimary)
            
            Text("或点击选择多个音频文件")
                .font(.shenManBody())
                .foregroundColor(.shenManTextSecondary)
            
            Button("选择文件") {
                isShowingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, .spacingMD)
            
            // 支持的格式
            supportedFormatsView
        }
    }
    
    private var listView: some View {
        VStack(spacing: .spacingMD) {
            // 工具栏
            toolbarView
            
            // 文件列表
            List {
                ForEach(files) { file in
                    BatchFileRow(file: file)
                }
                .onDelete { indexSet in
                    files.remove(atOffsets: indexSet)
                }
            }
            .listStyle(.inset)
            
            // 底部信息
            footerView
        }
    }
    
    private var toolbarView: some View {
        HStack {
            Button(action: {
                isShowingFilePicker = true
            }) {
                Label("添加文件", systemImage: "plus")
            }
            
            Spacer()
            
            Picker("模型", selection: $selectedModelId) {
                ForEach(ModelIdentifier.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .labelsHidden()
            .frame(width: 200)
            
            Button(action: clearAll) {
                Label("清空", systemImage: "trash")
            }
        }
        .padding(.horizontal)
    }
    
    private var footerView: some View {
        HStack {
            Text("共 \(files.count) 个文件")
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
            
            Spacer()
            
            Text("总时长：\(formatTotalDuration())")
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
            
            Text("总大小：\(formatTotalSize())")
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, .spacingSM)
    }
    
    private var supportedFormatsView: some View {
        VStack(spacing: .spacingSM) {
            Text("支持的格式")
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
            
            HStack(spacing: .spacingXS) {
                ForEach(["MP3", "WAV", "M4A", "FLAC", "MP4", "MOV"], id: \.self) { format in
                    Text(format)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, .spacingSM)
                        .padding(.vertical, .spacingXS)
                        .background(Color.shenManBackgroundSecondary.opacity(0.5))
                        .cornerRadius(4)
                        .foregroundColor(.shenManTextSecondary)
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let ext = url.pathExtension.lowercased()
                guard AudioFile.isSupported(extension: ext) else {
                    continue
                }
                
                Task {
                    if let file = try? await AudioMetadataReader.readMetadata(from: url) {
                        await MainActor.run {
                            files.append(file)
                        }
                    }
                }
            }
        case .failure(let error):
            appState.showError(error.localizedDescription)
        }
    }
    
    private func startBatchTranscription() {
        // 设置文件到 viewModel
        viewModel.addFiles(files)
        
        // 显示进度视图
        isShowingProgressSheet = true
        
        // 开始批量转录
        Task {
            await viewModel.startBatchTranscription(modelId: selectedModelId)
        }
    }
    
    private func clearAll() {
        files.removeAll()
    }
    
    private func formatTotalDuration() -> String {
        let totalSeconds = files.reduce(0) { $0 + $1.duration }
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatTotalSize() -> String {
        let totalBytes = files.reduce(0) { $0 + $1.fileSize }
        return FileSizeFormatter.format(totalBytes)
    }
}

// MARK: - 批量文件行

struct BatchFileRow: View {
    let file: AudioFile
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // 文件图标
            ZStack {
                RoundedRectangle(cornerRadius: .cornerRadiusMD)
                    .fill(Color.shenManPrimary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.shenManPrimary)
            }
            
            // 文件信息
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(file.filename)
                    .font(.shenManBody())
                    .foregroundColor(.shenManTextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: .spacingSM) {
                    Text(formatDuration(file.duration))
                        .font(.shenManCaption())
                        .foregroundColor(.shenManTextTertiary)
                    
                    Text("•")
                        .font(.shenManCaption())
                        .foregroundColor(.shenManTextTertiary)
                    
                    Text(file.format.rawValue.uppercased())
                        .font(.shenManCaption())
                        .foregroundColor(.shenManTextTertiary)
                    
                    Text("•")
                        .font(.shenManCaption())
                        .foregroundColor(.shenManTextTertiary)
                    
                    Text(FileSizeFormatter.format(file.fileSize))
                        .font(.shenManCaption())
                        .foregroundColor(.shenManTextTertiary)
                }
            }
            
            Spacer()
            
            // 状态指示
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)
        }
        .padding(.vertical, .spacingSM)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - 预览

#if DEBUG
struct BatchImportView_Previews: PreviewProvider {
    static var previews: some View {
        BatchImportView()
            .environmentObject(AppState())
    }
}
#endif
