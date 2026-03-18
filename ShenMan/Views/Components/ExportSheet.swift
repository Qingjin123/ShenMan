import SwiftUI

/// 导出对话框 - v2 原生风格
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = AppSettings.shared

    let result: TranscriptionResult
    var onExport: (URL) -> Void

    @State private var selectedFormat: AppSettings.ExportFormat = .txt
    @State private var includeTimestamp: Bool = true
    @State private var includeMetadata: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: .spacingLG) {
            // 标题
            Text("导出转录结果")
                .font(.shenManHeadline())
                .fontWeight(.semibold)

            // 格式选择
            formatSelection

            // 选项
            optionsSection

            Divider()

            // 按钮
            buttonSection
        }
        .padding(.spacingLG)
        .frame(width: 400)
        .alert("导出失败", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) { }
        } message: {
            if let message = errorMessage {
                Text(message)
            }
        }
        .onAppear {
            selectedFormat = settings.defaultExportFormat
            includeTimestamp = settings.includeTimestamp
        }
    }

    // MARK: - 子视图

    private var formatSelection: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            Text("导出格式")
                .font(.shenManBody())
                .fontWeight(.semibold)

            HStack(spacing: .spacingMD) {
                ForEach(AppSettings.ExportFormat.allCases) { format in
                    formatButton(format)
                }
            }
        }
    }

    private func formatButton(_ format: AppSettings.ExportFormat) -> some View {
        Button {
            selectedFormat = format
        } label: {
            VStack(spacing: .spacingSM) {
                Image(systemName: iconForFormat(format))
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)

                Text(format.displayName)
                    .font(.shenManCaption())
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingMD)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusMD)
                    .fill(selectedFormat == format ? Color.accentColor.opacity(0.1) : Color.shenManBackgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusMD)
                    .stroke(selectedFormat == format ? Color.accentColor : Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            Text("选项")
                .font(.shenManBody())
                .fontWeight(.semibold)

            Toggle("包含时间戳", isOn: $includeTimestamp)
                .disabled(selectedFormat == .srt)

            Toggle("包含元数据", isOn: $includeMetadata)
        }
    }

    private var buttonSection: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("导出") {
                performExport()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 私有方法

    private func iconForFormat(_ format: AppSettings.ExportFormat) -> String {
        switch format {
        case .txt: return "doc.text"
        case .srt: return "captions.bubble"
        case .markdown: return "doc.richtext"
        }
    }

    private func performExport() {
        let savePanel = NSSavePanel()
        savePanel.title = "导出转录结果"
        savePanel.nameFieldStringValue = result.audioFile.filename
            .replacingOccurrences(of: "\\.[^.]+$", with: "", options: .regularExpression)
            + "." + selectedFormat.fileExtension
        savePanel.allowedContentTypes = [.init(filenameExtension: selectedFormat.fileExtension)!]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                let options = ExportOptions(
                    includeTimestamp: includeTimestamp,
                    timestampPosition: settings.timestampPosition,
                    timestampPrecision: settings.timestampPrecision,
                    includeMetadata: includeMetadata
                )

                let data: Data
                switch selectedFormat {
                case .txt:
                    data = try TXTExporter().export(result: result, options: options)
                case .srt:
                    data = try SRTExporter().export(result: result, options: options)
                case .markdown:
                    data = try MarkdownExporter().export(result: result, options: options)
                }

                try data.write(to: url)

                DispatchQueue.main.async {
                    onExport(url)
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
