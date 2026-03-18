import SwiftUI

/// 批量处理进度视图
/// 显示批量转录的实时进度
struct ProcessingProgressView: View {
    // MARK: - 环境
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BatchProcessingViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: .spacingXL) {
            // 标题
            Text("批量转录中")
                .font(.shenManTitle())
                .fontWeight(.bold)
                .foregroundColor(.shenManTextPrimary)
            
            // 进度条
            VStack(spacing: .spacingMD) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 2)
                
                HStack {
                    Text(viewModel.progressText)
                        .font(.shenManBody())
                        .fontWeight(.medium)
                        .foregroundColor(.shenManPrimary)
                    
                    Spacer()
                    
                    Text("\(viewModel.completedCount) / \(viewModel.totalCount)")
                        .font(.shenManBody())
                        .foregroundColor(.shenManTextSecondary)
                }
            }
            .padding(.horizontal, .spacingXL)
            
            // 状态描述
            Text(viewModel.statusDescription)
                .font(.shenManBody())
                .foregroundColor(.shenManTextSecondary)
                .multilineTextAlignment(.center)
            
            // 当前文件
            if viewModel.isProcessing && !viewModel.currentProcessingFile.isEmpty {
                VStack(spacing: .spacingSM) {
                    Divider()
                    
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.shenManAccent)
                            .symbolEffect(.variableColor.iterative)
                        
                        Text(viewModel.currentProcessingFile)
                            .font(.shenManCaption())
                            .foregroundColor(.shenManTextTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            
            // 统计信息
            HStack(spacing: .spacingLG) {
                StatView(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.completedCount)",
                    label: "已完成",
                    color: .green
                )
                
                StatView(
                    icon: "xmark.circle.fill",
                    value: "\(viewModel.failedCount)",
                    label: "失败",
                    color: .red
                )
                
                StatView(
                    icon: "clock.fill",
                    value: "\(viewModel.totalCount - viewModel.completedCount - viewModel.failedCount)",
                    label: "剩余",
                    color: .shenManPrimary
                )
            }
            .padding(.top, .spacingMD)
            
            // 操作按钮
            HStack(spacing: .spacingLG) {
                Button(action: {
                    viewModel.cancel()
                }) {
                    Label("取消", systemImage: "xmark.circle")
                        .frame(minWidth: 100)
                }
                .disabled(viewModel.isCompleted || viewModel.processingState == .cancelled)
                
                if viewModel.isCompleted {
                    Button(action: {
                        dismiss()
                    }) {
                        Label("完成", systemImage: "checkmark.circle")
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, .spacingLG)
        }
        .padding(.spacingXL)
        .frame(minWidth: 450, minHeight: 350)
    }
}

// MARK: - 统计视图

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.shenManHeadline())
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
        }
        .frame(minWidth: 80)
    }
}

// MARK: - 预览

#if DEBUG
struct ProcessingProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingProgressView(viewModel: BatchProcessingViewModel())
    }
}
#endif
