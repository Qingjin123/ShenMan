import SwiftUI

/// 转录中视图 - v2 原生风格
struct TranscribingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: .spacingXL) {
            // 文件信息卡片
            fileInfoCard

            Spacer()

            // 进度显示
            progressSection

            Spacer()

            // 取消按钮
            cancelButton
        }
        .padding(.spacingXL)
        .frame(maxWidth: 500)
    }

    // MARK: - 子视图

    private var fileInfoCard: some View {
        Group {
            if let audioFile = appState.currentAudioFile {
                VStack(alignment: .leading, spacing: .spacingSM) {
                    HStack {
                        Image(systemName: audioFile.format.isVideo ? "video.fill" : "doc.fill")
                            .foregroundColor(.accentColor)
                        Text(audioFile.filename)
                            .font(.shenManTitle3())
                            .fontWeight(.medium)
                    }

                    HStack(spacing: .spacingMD) {
                        Label(audioFile.format.displayName, systemImage: "music.note")
                        Label(audioFile.durationFormatted, systemImage: "clock")
                        Label(audioFile.fileSizeFormatted, systemImage: "doc.badge.gearshape")
                    }
                    .font(.shenManCaption())
                    .foregroundColor(.secondary)
                }
                .padding(.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.shenManBackgroundSecondary)
                .cornerRadius(.cornerRadiusLG)
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: .spacingMD) {
            // 百分比
            Text("\(Int(appState.transcriptionProgress * 100))%")
                .font(.shenManTitle())
                .fontWeight(.bold)
                .monospacedDigit()

            // 进度条 - 使用系统 ProgressView
            ProgressView(value: appState.transcriptionProgress)
                .scaleEffect(y: 1.5)
                .frame(maxWidth: .infinity)
                .progressViewStyle(.linear)
                .tint(.accentColor)

            // 详细信息
            VStack(spacing: .spacingXS) {
                let processedTime = TimeFormatter.formatTime(appState.transcriptionProgress * (appState.currentAudioFile?.duration ?? 0))
                let totalTime = appState.currentAudioFile?.durationFormatted ?? "-"
                Text("已处理 \(processedTime) / 共 \(totalTime)")
                    .font(.shenManSubheadline())
                    .foregroundColor(.secondary)

                Text("预计剩余：\(TimeFormatter.formatRemainingTime(appState.estimatedTimeRemaining))")
                    .font(.shenManSubheadline())
                    .foregroundColor(.secondary)
            }

            // 状态消息
            Text(appState.transcriptionStatusMessage)
                .font(.shenManCaption())
                .foregroundColor(.accentColor)
                .padding(.top, .spacingSM)
        }
    }

    private var cancelButton: some View {
        Button("取消转录") {
            appState.cancelTranscription()
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
    }
}
