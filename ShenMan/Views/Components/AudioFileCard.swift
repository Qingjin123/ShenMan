import SwiftUI

/// 音频文件卡片视图 - v2 原生风格
struct AudioFileCard: View {
    let audioFile: AudioFile
    var showActions: Bool = true
    var onStartTranscription: (() -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: .spacingMD) {
            // 文件图标
            Image(systemName: audioFile.format.isVideo ? "video.fill" : "doc.fill")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(.cornerRadiusMD)

            // 文件信息
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(audioFile.filename)
                    .font(.shenManBody())
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: .spacingSM) {
                    Label(audioFile.format.displayName, systemImage: "doc.text")
                    Label(audioFile.durationFormatted, systemImage: "clock")
                    Label(audioFile.fileSizeFormatted, systemImage: "externaldrive")
                }
                .font(.shenManCaption())
                .foregroundColor(.secondary)
            }

            Spacer()

            // 操作按钮
            if showActions {
                HStack(spacing: .spacingSM) {
                    Button {
                        onStartTranscription?()
                    } label: {
                        Label("开始转录", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    if let onRemove = onRemove {
                        Button {
                            onRemove()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.spacingMD)
        .background(Color.shenManBackgroundSecondary)
        .cornerRadius(.cornerRadiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusLG)
                .stroke(Color.shenManBorder, lineWidth: 1)
        )
        .shenManShadow(elevation: 1)
    }
}
