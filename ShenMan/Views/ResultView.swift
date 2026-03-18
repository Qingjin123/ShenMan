import SwiftUI
import AVFoundation

/// 结果展示视图 - v2 原生风格
/// 显示转录结果并支持编辑和导出
struct ResultView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editedSentences: [SentenceTimestamp] = []
    @State private var showExportSheet = false
    @State private var selectedSentence: SentenceTimestamp?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack(spacing: 0) {
            // 统计信息卡片
            statsCard
            
            Divider()
            
            // 转录内容列表（带编辑和播放功能）
            transcriptionContent
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("导出") {
                    showExportSheet = true
                }
                
                Button(action: { copyToClipboard() }) {
                    Label("复制", systemImage: "doc.on.doc")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(
                result: currentResult,
                onExport: { url in
                    appState.lastExportPath = url
                    showExportSheet = false
                }
            )
        }
        .onAppear {
            if let result = appState.currentResult {
                editedSentences = result.sentences
                setupPlayer()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    // MARK: - 计算属性
    
    private var currentResult: TranscriptionResult {
        appState.currentResult ?? TranscriptionResult(
            audioFile: AudioFile(
                url: URL(fileURLWithPath: ""),
                filename: "",
                duration: 0,
                fileSize: 0,
                format: .unknown,
                sampleRate: 0,
                channels: 0
            ),
            modelName: "",
            language: "",
            sentences: [],
            processingTime: 0,
            metadata: TranscriptionMetadata(
                modelVersion: "",
                audioDuration: 0,
                realTimeFactor: 0
            )
        )
    }
    
    // MARK: - 子视图
    
    private var statsCard: some View {
        HStack(spacing: .spacingXL) {
            StatItem(
                label: "总时长",
                value: currentResult.audioFile.durationFormatted
            )
            
            StatItem(
                label: "总句数",
                value: currentResult.sentences.count.formatted()
            )
            
            StatItem(
                label: "处理时间",
                value: String(format: "%.1f 秒", currentResult.processingTime)
            )
            
            StatItem(
                label: "RTF",
                value: String(format: "%.2fx", currentResult.metadata.realTimeFactor)
            )
            
            Spacer()
        }
        .padding(.spacingMD)
        .background(Color.shenManBackgroundSecondary)
        .cornerRadius(.cornerRadiusLG)
        .padding(.spacingMD)
    }
    
    private var transcriptionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingSM) {
                ForEach(Array(editedSentences.enumerated()), id: \.element.id) { index, sentence in
                    TranscriptionRow(
                        sentence: sentence,
                        index: index,
                        isSelected: selectedSentence?.id == sentence.id,
                        isPlaying: isPlaying && currentTime >= sentence.startTime && currentTime < sentence.endTime,
                        onPlay: { playFromTime(sentence.startTime) }
                    )
                    .onTapGesture {
                        selectedSentence = sentence
                    }
                    .contextMenu {
                        ContextMenuItems(
                            sentence: sentence,
                            onEdit: { editSentence(sentence) },
                            onPlay: { playFromTime(sentence.startTime) }
                        )
                    }
                }
            }
            .padding(.spacingMD)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer() {
        guard let audioFile = appState.currentResult?.audioFile.url else { return }
        player = AVPlayer(url: audioFile)
        
        // 监听播放状态 - 使用 MainActor 包裹
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemTimeJumped,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let player = self.player {
                    self.currentTime = player.currentTime().seconds
                }
            }
        }
        
        // 监听播放结束
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.isPlaying = false
            }
        }
        
        // 定期检查播放位置
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if let player = self.player, player.rate > 0 {
                    self.currentTime = player.currentTime().seconds
                }
            }
        }
    }
    
    private func playFromTime(_ time: TimeInterval) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
        player.play()
        isPlaying = true
    }
    
    private func editSentence(_ sentence: SentenceTimestamp) {
        // 未来可实现行内编辑
    }
    
    private func copyToClipboard() {
        let text = editedSentences.map { $0.text }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - 统计项

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text(label)
                .font(.shenManCaption())
                .foregroundColor(.secondary)

            Text(value)
                .font(.shenManTitle3())
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

// MARK: - 转录行

struct TranscriptionRow: View {
    let sentence: SentenceTimestamp
    let index: Int
    let isSelected: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            // 时间戳 - 可点击播放
            Button(action: onPlay) {
                Text(formatTime(sentence.startTime))
                    .font(.shenManCaption())
                    .foregroundColor(isPlaying ? .accentColor : .secondary)
                    .monospacedDigit()
                    .frame(width: 90, alignment: .trailing)
            }
            .buttonStyle(.plain)
            
            // 播放指示器
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.accentColor)
                    .font(.caption)
            }
            
            // 文本
            Text(sentence.text)
                .font(.shenManBody())
                .lineSpacing(4)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusMD)
                .fill(isPlaying ?
                      Color.accentColor.opacity(0.05) :
                      isSelected ?
                      Color.accentColor.opacity(0.1) :
                      isHovering ?
                      Color.shenManBackgroundSecondary :
                      Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusMD)
                .stroke(
                    isPlaying ?
                        Color.accentColor.opacity(0.5) :
                        isSelected ?
                        Color.accentColor.opacity(0.3) :
                        Color.clear,
                    lineWidth: 1.5
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contentShape(Rectangle())
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
}

// MARK: - 上下文菜单

struct ContextMenuItems: View {
    let sentence: SentenceTimestamp
    let onEdit: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        Button {
            copyToClipboard(sentence.text)
        } label: {
            Label("复制", systemImage: "doc.on.doc")
        }
        
        Button {
            onEdit()
        } label: {
            Label("编辑", systemImage: "pencil")
        }
        
        Divider()
        
        Button {
            onPlay()
        } label: {
            Label("从此处播放", systemImage: "play.fill")
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
