import SwiftUI
import UniformTypeIdentifiers

/// 主页视图 - v2 原生风格
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isDraggingOver = false

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                // 标题区域
                titleSection

                // 拖放区域
                dropZoneSection

                // 最近文件（合并历史记录）
                recentFilesSection
            }
            .padding(.spacingXL)
            .frame(maxWidth: 700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.shenManBackground)
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            Task { @MainActor in
                await handleDrop(providers: providers)
            }
            return true
        }
    }

    // MARK: - 子视图

    private var titleSection: some View {
        VStack(spacing: .spacingSM) {
            Text("声声慢")
                .font(.shenManLargeTitle())
                .fontWeight(.bold)

            Text("让声音慢下来，沉淀为文字")
                .font(.shenManSubheadline())
                .foregroundColor(.secondary)
        }
        .padding(.top, .spacingXXL)
    }

    private var dropZoneSection: some View {
        Button(action: {
            // 使用 AppState 的文件导入器
            appState.showFileImporter = true
        }) {
            VStack(spacing: .spacingMD) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("拖放音频文件到此处")
                    .font(.shenManTitle3())
                    .fontWeight(.medium)

                Text("或点击选择")
                    .font(.shenManSubheadline())
                    .foregroundColor(.secondary)

                Text("MP3 · WAV · M4A · FLAC · MP4 · MOV")
                    .font(.shenManCaption())
                    .foregroundColor(.shenManTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusLG)
                    .fill(isDraggingOver ?
                          Color.accentColor.opacity(0.1) :
                          Color.shenManBackgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusLG)
                    .stroke(
                        isDraggingOver ?
                            Color.accentColor.opacity(0.5) :
                            Color.shenManBorder,
                        lineWidth: isDraggingOver ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
    }

    private var recentFilesSection: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                Text("最近文件")
                    .font(.shenManTitle3())
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    appState.showHistory = true
                }) {
                    Label("查看全部", systemImage: "chevron.right")
                        .font(.shenManCaption())
                }
                .buttonStyle(.plain)
            }

            if appState.transcriptionHistory.isEmpty {
                VStack(spacing: .spacingSM) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.shenManTextTertiary)

                    Text("暂无历史记录")
                        .font(.shenManBody())
                        .foregroundColor(.shenManTextTertiary)
                    
                    Text("转录的文件会显示在这里")
                        .font(.shenManCaption())
                        .foregroundColor(.shenManTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingXL)
            } else {
                VStack(spacing: .spacingXS) {
                    ForEach(appState.transcriptionHistory.prefix(5)) { result in
                        RecentFileRow(result: result)
                    }
                }
            }
        }
    }

    // MARK: - 方法

    private func handleDrop(providers: [NSItemProvider]) async -> Bool {
        guard let provider = providers.first else { return false }

        do {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil)
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                await MainActor.run {
                    appState.showError("无法获取文件路径")
                }
                return false
            }

            let ext = url.pathExtension.lowercased()
            if !AudioFile.isSupported(extension: ext) {
                await MainActor.run {
                    appState.showError("不支持的文件格式：\(ext)")
                }
                return false
            }

            // 加载音频文件并开始转录
            await appState.loadAndTranscribeAudioFile(url: url)

            return true
        } catch {
            await MainActor.run {
                appState.showError("文件加载失败：\(error.localizedDescription)")
            }
            return false
        }
    }
}

// MARK: - 最近文件行

struct RecentFileRow: View {
    let result: TranscriptionResult
    
    @EnvironmentObject private var appState: AppState
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            // 点击时打开结果页面
            appState.currentResult = result
            appState.currentView = .result
        }) {
            HStack(spacing: .spacingSM) {
                Image(systemName: result.audioFile.format.isVideo ? "video.fill" : "doc.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                Text(result.audioFile.filename)
                    .font(.shenManBody())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(result.audioFile.durationFormatted)
                    .font(.shenManCaption())
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Text(result.modelName)
                    .font(.shenManCaption())
                    .foregroundColor(.shenManTextTertiary)
                    .frame(width: 100, alignment: .trailing)
            }
            .padding(.spacingSM)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusMD)
                    .fill(isHovering ? Color.shenManBackgroundSecondary : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
