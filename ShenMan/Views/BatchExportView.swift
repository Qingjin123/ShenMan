import SwiftUI
import UniformTypeIdentifiers

/// 批量导出视图
/// 允许用户选择导出格式和目录，批量导出转录结果
struct BatchExportView: View {
    // MARK: - 环境
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // MARK: - 参数
    
    let results: [TranscriptionResult]
    
    // MARK: - 状态
    
    @State private var selectedFormat: AppSettings.ExportFormat = .txt
    @State private var exportDirectory: URL?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportStatus: String = "准备导出"
    @State private var showDirectoryPicker = false
    @State private var exportComplete = false
    @State private var exportedCount: Int = 0
    @State private var failedCount: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: .spacingXL) {
                if isExporting {
                    exportingView
                } else if exportComplete {
                    completeView
                } else {
                    configView
                }
            }
            .padding(.spacingXL)
            .navigationTitle("批量导出")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showDirectoryPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleDirectorySelection(result)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - 子视图
    
    /// 配置视图
    private var configView: some View {
        VStack(spacing: .spacingXL) {
            // 文件数量提示
            VStack(spacing: .spacingSM) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.shenManPrimary)
                
                Text("导出 \(results.count) 个文件")
                    .font(.shenManHeadline())
                    .foregroundColor(.shenManTextPrimary)
                
                Text("选择导出格式和目标目录")
                    .font(.shenManBody())
                    .foregroundColor(.shenManTextSecondary)
            }
            
            Divider()
            
            // 格式选择
            VStack(alignment: .leading, spacing: .spacingMD) {
                Text("导出格式")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.shenManTextPrimary)
                
                Picker("格式", selection: $selectedFormat) {
                    ForEach(AppSettings.ExportFormat.allCases) { format in
                        HStack {
                            Text(format.displayName)
                            
                            Spacer()
                            
                            if format == appState.settings.defaultExportFormat {
                                Text("默认")
                                    .font(.shenManCaption())
                                    .foregroundColor(.shenManTextTertiary)
                            }
                        }
                        .tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            // 目录选择
            VStack(alignment: .leading, spacing: .spacingMD) {
                Text("导出到")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.shenManTextPrimary)
                
                Button(action: {
                    showDirectoryPicker = true
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.shenManPrimary)
                        
                        if let directory = exportDirectory {
                            Text(directory.path)
                                .foregroundColor(.shenManTextSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("选择目录")
                                .foregroundColor(.shenManTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.shenManTextTertiary)
                    }
                    .padding(.spacingSM)
                    .background(Color.shenManBackgroundSecondary)
                    .cornerRadius(.cornerRadiusMD)
                }
            }
            
            Spacer()
            
            // 导出按钮
            Button(action: startExport) {
                Label("开始导出", systemImage: "square.and.arrow.up")
                    .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .disabled(exportDirectory == nil)
        }
    }
    
    /// 导出中视图
    private var exportingView: some View {
        VStack(spacing: .spacingXL) {
            // 进度条
            VStack(spacing: .spacingMD) {
                ProgressView(value: exportProgress)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 2)
                
                Text("\(Int(exportProgress * 100))%")
                    .font(.shenManTitle())
                    .fontWeight(.bold)
                    .foregroundColor(.shenManPrimary)
            }
            
            // 状态文本
            Text(exportStatus)
                .font(.shenManBody())
                .foregroundColor(.shenManTextSecondary)
            
            // 统计
            HStack(spacing: .spacingLG) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    value: exportedCount,
                    label: "成功",
                    color: .green
                )
                
                StatBadge(
                    icon: "xmark.circle.fill",
                    value: failedCount,
                    label: "失败",
                    color: .red
                )
                
                StatBadge(
                    icon: "doc.fill",
                    value: results.count,
                    label: "总计",
                    color: .shenManPrimary
                )
            }
            .padding(.top, .spacingMD)
            
            Spacer()
            
            // 取消按钮
            Button("取消") {
                // TODO: 取消导出
            }
            .disabled(exportComplete)
        }
    }
    
    /// 完成视图
    private var completeView: some View {
        VStack(spacing: .spacingXL) {
            // 完成图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            // 完成提示
            VStack(spacing: .spacingSM) {
                Text("导出完成")
                    .font(.shenManTitle())
                    .fontWeight(.bold)
                    .foregroundColor(.shenManTextPrimary)
                
                Text("成功导出 \(exportedCount) 个文件")
                    .font(.shenManBody())
                    .foregroundColor(.shenManTextSecondary)
                
                if failedCount > 0 {
                    Text("失败 \(failedCount) 个文件")
                        .font(.shenManCaption())
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            // 操作按钮
            HStack(spacing: .spacingLG) {
                Button(action: {
                    // 打开导出目录
                    if let directory = exportDirectory {
                        NSWorkspace.shared.open(directory)
                    }
                }) {
                    Label("打开目录", systemImage: "folder")
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Label("完成", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - 方法
    
    private func handleDirectorySelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                exportDirectory = url
            }
        case .failure(let error):
            appState.showError(error.localizedDescription)
        }
    }
    
    private func startExport() {
        guard let directory = exportDirectory else { return }
        
        isExporting = true
        
        Task {
            let exportService = BatchExportService()
            
            do {
                let _ = try await exportService.exportBatch(
                    results: results,
                    format: selectedFormat,
                    directory: directory
                ) { progress, status in
                    Task { @MainActor in
                        exportProgress = progress
                        exportStatus = status
                    }
                }
                
                await MainActor.run {
                    exportedCount = results.count
                    exportComplete = true
                }
            } catch {
                await MainActor.run {
                    appState.showError(error.localizedDescription)
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - 统计徽章

struct StatBadge: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.shenManHeadline())
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - 预览

#if DEBUG
struct BatchExportView_Previews: PreviewProvider {
    static var previews: some View {
        BatchExportView(results: [])
            .environmentObject(AppState())
    }
}
#endif
