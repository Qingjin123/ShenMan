import SwiftUI

/// 历史记录列表视图 - 改进版
/// 显示和管理转录历史记录
struct HistoryListView: View {
    // MARK: - 环境

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - 状态

    @State private var historyRecords: [TranscriptionHistoryRecord] = []
    @State private var selectedRecord: TranscriptionHistoryRecord?
    @State private var isDeleting = false
    @State private var searchText = ""
    @State private var isLoading = true

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
                } else if historyRecords.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color.shenManBackground)
        .cornerRadius(12)
        .sheet(item: $selectedRecord) { record in
            HistoryDetailView(record: record)
                .environmentObject(appState)
        }
        .task {
            await loadHistory()
        }
        .confirmationDialog("确定要删除所有历史记录吗？", isPresented: $isDeleting) {
            Button("删除", role: .destructive) {
                Task {
                    await deleteAllHistory()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作无法撤销。")
        }
    }

    // MARK: - 子视图

    private var titleBar: some View {
        HStack {
            Text("历史记录")
                .font(.shenManTitle2())
                .fontWeight(.bold)
            
            Spacer()
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                TextField("搜索历史记录", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 180)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.shenManBackgroundSecondary)
            .cornerRadius(8)
            
            Divider()
                .frame(height: 24)
            
            // 操作菜单
            Menu {
                Button("批量导出", action: exportSelected)
                Divider()
                Button("删除全部", role: .destructive) {
                    isDeleting = true
                }
                Divider()
                Button("刷新") {
                    Task {
                        await loadHistory()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .padding(8)
            }
            
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

    private var loadingView: some View {
        VStack(spacing: .spacingLG) {
            ProgressView()
                .scaleEffect(1.5)

            Text("加载历史记录...")
                .font(.shenManBody())
                .foregroundColor(.shenManTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: .spacingLG) {
            // 大图标
            ZStack {
                Circle()
                    .fill(Color.shenManBackgroundSecondary)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 36))
                    .foregroundColor(.shenManTextTertiary)
            }
            
            VStack(spacing: .spacingSM) {
                Text("暂无历史记录")
                    .font(.shenManTitle3())
                    .fontWeight(.medium)
                
                Text("转录的文件会显示在这里")
                    .font(.shenManBody())
                    .foregroundColor(.shenManTextSecondary)
            }
            
            Button(action: {
                dismiss()
            }) {
                Label("去转录", systemImage: "arrow.right")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, .spacingMD)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        VStack(spacing: 0) {
            // 列表头部
            HStack {
                Text("共 \(historyRecords.count) 条记录")
                    .font(.shenManCaption())
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Label("清除搜索", systemImage: "xmark.circle.fill")
                            .font(.shenManCaption())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, .spacingSM)
            
            Divider()
            
            // 历史记录列表
            List(filteredRecords) { record in
                HistoryRecordRow(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecord = record
                    }
                    .contextMenu {
                        Button("打开") {
                            selectedRecord = record
                        }
                        Button(record.isFavorite ? "取消收藏" : "收藏") {
                            Task {
                                await toggleFavorite(record)
                            }
                        }
                        Divider()
                        Button("删除", role: .destructive) {
                            Task {
                                await deleteRecord(record)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteRecord(record)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }

                        Button {
                            Task {
                                await toggleFavorite(record)
                            }
                        } label: {
                            Label(
                                record.isFavorite ? "取消收藏" : "收藏",
                                systemImage: record.isFavorite ? "star.slash" : "star"
                            )
                        }
                        .tint(record.isFavorite ? .orange : .yellow)
                    }
            }
            .listStyle(.inset)
        }
    }

    // MARK: - 计算属性

    private var filteredRecords: [TranscriptionHistoryRecord] {
        if searchText.isEmpty {
            return historyRecords.sorted { $0.createdAt > $1.createdAt }
        } else {
            return historyRecords.filter { record in
                record.filename.localizedCaseInsensitiveContains(searchText) ||
                record.transcript.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - 方法

    private func loadHistory() async {
        isLoading = true
        defer {
            isLoading = false
        }

        let records = await HistoryRepository.shared.getAllHistory()
        await MainActor.run {
            historyRecords = records
        }
    }

    private func toggleFavorite(_ record: TranscriptionHistoryRecord) async {
        await HistoryRepository.shared.toggleFavorite(id: record.id)
        await loadHistory()
    }

    private func deleteRecord(_ record: TranscriptionHistoryRecord) async {
        await HistoryRepository.shared.deleteHistoryRecord(id: record.id)
        await loadHistory()
    }

    private func deleteAllHistory() async {
        await HistoryRepository.shared.deleteAllHistory()
        await loadHistory()
    }

    private func exportSelected() {
        appState.batchExportResults = historyRecords.compactMap { record in
            createTranscriptionResult(from: record)
        }
        appState.showBatchExport = true
    }

    private func createTranscriptionResult(from record: TranscriptionHistoryRecord) -> TranscriptionResult? {
        guard let audioFile = record.audioFile else { return nil }

        let sentences = record.transcript
            .components(separatedBy: "\n")
            .map { text in
                SentenceTimestamp(text: text, startTime: 0, endTime: record.duration)
            }

        return TranscriptionResult(
            audioFile: audioFile,
            modelName: record.modelId,
            language: record.language,
            sentences: sentences,
            processingTime: record.processingTime,
            metadata: TranscriptionMetadata(
                modelVersion: record.modelId,
                audioDuration: record.duration,
                realTimeFactor: record.realTimeFactor
            )
        )
    }
}

// MARK: - 历史记录行

struct HistoryRecordRow: View {
    let record: TranscriptionHistoryRecord

    var body: some View {
        HStack(spacing: .spacingMD) {
            // 文件类型图标
            fileIcon

            // 文件信息
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack(spacing: .spacingSM) {
                    Text(record.filename)
                        .font(.shenManBody())
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if record.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }

                HStack(spacing: .spacingSM) {
                    Label(record.durationFormatted, systemImage: "clock")
                    Text("•")
                    Label(record.format.uppercased(), systemImage: "music.note")
                    Text("•")
                    Label(record.createdAt.formatted(.relative(presentation: .named)), systemImage: "calendar")
                }
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
            }

            Spacer()
        }
        .padding(.vertical, .spacingSM)
    }

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerRadiusMD)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 44, height: 44)

            Image(systemName: "doc.text.fill")
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - 预览

#if DEBUG
struct HistoryListView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryListView()
            .environmentObject(AppState())
    }
}
#endif
