import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

/// 历史记录详情视图
/// 显示单条转录记录的详细信息
struct HistoryDetailView: View {
    // MARK: - 环境
    
    @Environment(\.dismiss) private var dismiss
    let record: TranscriptionHistoryRecord
    
    // MARK: - 状态
    
    @State private var transcript: String
    @State private var isEditing = false
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    
    // MARK: - 初始化
    
    init(record: TranscriptionHistoryRecord) {
        self.record = record
        _transcript = State(initialValue: record.transcript)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 文件信息卡片
                fileInfoCard
                
                Divider()
                
                // 转录文本
                transcriptEditor
            }
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { isEditing.toggle() }) {
                            Label(isEditing ? "完成编辑" : "编辑", systemImage: isEditing ? "checkmark" : "pencil")
                        }
                        
                        Button(action: { showShareSheet = true }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showDeleteConfirm = true }) {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("确定要删除这条记录吗？", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) {
                    // TODO: 删除记录
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [transcript])
            }
        }
        .frame(minWidth: 700, minHeight: 550)
    }
    
    // MARK: - 子视图
    
    private var fileInfoCard: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // 文件名
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.shenManPrimary)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(record.filename)
                        .font(.shenManHeadline())
                        .foregroundColor(.shenManTextPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: .spacingSM) {
                        Label(formatDuration(record.duration), systemImage: "clock")
                            .font(.shenManCaption())
                            .foregroundColor(.shenManTextTertiary)
                        
                        Text("•")
                            .font(.shenManCaption())
                            .foregroundColor(.shenManTextTertiary)
                        
                        Label(record.format.uppercased(), systemImage: "waveform")
                            .font(.shenManCaption())
                            .foregroundColor(.shenManTextTertiary)
                        
                        Text("•")
                            .font(.shenManCaption())
                            .foregroundColor(.shenManTextTertiary)
                        
                        Label(FileSizeFormatter.format(record.fileSize), systemImage: "internaldrive")
                            .font(.shenManCaption())
                            .foregroundColor(.shenManTextTertiary)
                    }
                }
                
                Spacer()
                
                // 收藏按钮
                Button(action: {
                    // TODO: 切换收藏
                }) {
                    Image(systemName: record.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(record.isFavorite ? .yellow : .shenManTextTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // 元数据
            HStack(spacing: .spacingMD) {
                MetaTag(icon: "cpu", text: record.modelId.components(separatedBy: "/").last ?? record.modelId)
                MetaTag(icon: "globe", text: Language(rawValue: record.language)?.displayName ?? record.language)
                MetaTag(icon: "calendar", text: formatDate(record.createdAt))
                MetaTag(icon: "timer", text: String(format: "%.1fx", record.realTimeFactor))
            }
        }
        .padding(.spacingMD)
        .background(Color.shenManCard)
        .cornerRadius(.cornerRadiusLG)
        .padding(.spacingMD)
    }
    
    private var transcriptEditor: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Text("转录文本")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.shenManTextPrimary)
                
                Spacer()
                
                Text("\(transcript.count) 字符")
                    .font(.shenManCaption())
                    .foregroundColor(.shenManTextTertiary)
            }
            .padding(.horizontal, .spacingMD)
            
            if isEditing {
                TextEditor(text: $transcript)
                    .font(.shenManBody())
                    .foregroundColor(.shenManTextPrimary)
                    .padding(.spacingSM)
                    .background(Color.shenManBackground)
                    .cornerRadius(.cornerRadiusMD)
                    .padding(.horizontal, .spacingMD)
            } else {
                ScrollView {
                    Text(transcript)
                        .font(.shenManBody())
                        .foregroundColor(.shenManTextPrimary)
                        .lineSpacing(4)
                        .padding(.spacingSM)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 元数据标签

struct MetaTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.shenManTextTertiary)
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.shenManTextSecondary)
        }
        .padding(.horizontal, .spacingSM)
        .padding(.vertical, .spacingXS)
        .background(Color.shenManBackgroundSecondary)
        .cornerRadius(4)
    }
}

// MARK: - 分享视图

#if os(macOS)
struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#else
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - 预览

#if DEBUG
struct HistoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryDetailView(
            record: TranscriptionHistoryRecord(
                filename: "测试录音.m4a",
                fileURL: URL(fileURLWithPath: "/test"),
                duration: 125.5,
                fileSize: 2048576,
                format: "m4a",
                modelId: "Qwen3-ASR-0.6B",
                language: "zh",
                transcript: "这是一段测试转录文本。声声慢是一款优秀的语音转文字工具。",
                processingTime: 25.0,
                realTimeFactor: 0.2
            )
        )
    }
}
#endif
