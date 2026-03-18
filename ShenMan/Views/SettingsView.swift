import SwiftUI

/// 设置视图
/// 管理应用设置
struct SettingsView: View {
    // MARK: - 环境

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    /// 设置
    @StateObject private var settings = AppSettings.shared

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // TabView
            TabView {
                // 常规设置
                GeneralSettingsView(settings: settings)
                    .tabItem {
                        Label("常规", systemImage: "gearshape")
                    }

                // 转录设置
                TranscriptionSettingsView(settings: settings)
                    .tabItem {
                        Label("转录", systemImage: "waveform")
                    }

                // 导出设置
                ExportSettingsView(settings: settings)
                    .tabItem {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }

                // 关于
                AboutView()
                    .tabItem {
                        Label("关于", systemImage: "info.circle")
                    }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.shenManBackground)
    }
    
    private var titleBar: some View {
        HStack {
            Text("设置")
                .font(.shenManTitle2())
                .fontWeight(.bold)
            
            Spacer()
            
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
}

// MARK: - 常规设置视图

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("模型") {
                Picker("默认模型", selection: $settings.selectedModel) {
                    ForEach(Constants.availableASRModels, id: \.self) { model in
                        Text(model.components(separatedBy: "/").last ?? model)
                            .tag(model)
                    }
                }
                .help("选择默认使用的 ASR 模型")
            }

            Section("语言") {
                Picker("默认语言", selection: $settings.defaultLanguage) {
                    Text("自动检测").tag(Language.chinese)
                    ForEach(Language.allCases.filter { $0 != .chinese }) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .help("选择音频的默认语言，如果不确定请保持自动检测")
            }

            Section("高级") {
                Toggle("启用日志", isOn: $settings.enableLogging)
                Stepper("最大并发任务数：\(settings.maxConcurrentTasks)", value: $settings.maxConcurrentTasks, in: 1...4)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 转录设置视图

struct TranscriptionSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("时间戳") {
                Toggle("显示时间戳", isOn: $settings.includeTimestamp)

                if settings.includeTimestamp {
                    Picker("时间戳位置", selection: $settings.timestampPosition) {
                        ForEach(AppSettings.TimestampPosition.allCases) { pos in
                            Text(pos.displayName).tag(pos)
                        }
                    }

                    Picker("时间戳精度", selection: $settings.timestampPrecision) {
                        ForEach(AppSettings.TimestampPrecision.allCases) { prec in
                            Text(prec.displayName).tag(prec)
                        }
                    }
                }
            }

            Section("聚合策略") {
                Picker("句子聚合方式", selection: $settings.aggregationStrategy) {
                    ForEach(AppSettings.AggregationStrategy.allCases) { strat in
                        Text(strat.displayName).tag(strat)
                    }
                }
            }

            Section("后处理") {
                Toggle("中文纠错", isOn: $settings.enableChineseCorrection)
                Toggle("标点优化", isOn: $settings.enablePunctuationOptimization)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 导出设置视图

struct ExportSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("默认格式") {
                Picker("导出格式", selection: $settings.defaultExportFormat) {
                    ForEach(AppSettings.ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }

            Section("选项") {
                Toggle("包含时间戳", isOn: $settings.includeTimestamp)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 关于视图

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App 图标和名称
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)

                    Text("声声慢")
                        .font(.shenManLargeTitle())
                        .fontWeight(.bold)

                    Text("ShenMan")
                        .font(.shenManBody())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)

                // 版本信息
                GroupBox("版本信息") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("版本号")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("构建日期")
                            Spacer()
                            Text("2026-03-18")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 简介
                GroupBox("关于") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("声声慢是一款 macOS 语音转文字工具，支持多种 ASR 模型，可离线使用。")
                            .font(.shenManBody())

                        Text("特点：")
                            .font(.shenManBody())
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 支持多种 ASR 模型")
                            Text("• 离线转录，保护隐私")
                            Text("• 支持多种音频格式")
                            Text("• 批量处理")
                            Text("• 多种导出格式")
                        }
                        .font(.shenManBody())
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // 技术栈
                GroupBox("技术栈") {
                    VStack(alignment: .leading, spacing: 8) {
                        TechnologyItem(name: "MLX Swift", description: "Apple 机器学习框架")
                        TechnologyItem(name: "SwiftUI", description: "声明式 UI 框架")
                        TechnologyItem(name: "Qwen3-ASR", description: "阿里开源语音识别模型")
                    }
                    .padding(.vertical, 8)
                }

                // 链接
                HStack(spacing: 24) {
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("GitHub", systemImage: "link")
                    }

                    Link(destination: URL(string: "https://huggingface.co")!) {
                        Label("Hugging Face", systemImage: "cloud")
                    }
                }
                .padding(.vertical)
            }
            .padding()
        }
        .formStyle(.grouped)
    }
}

struct TechnologyItem: View {
    let name: String
    let description: String

    var body: some View {
        HStack {
            Text(name)
                .fontWeight(.medium)
            Spacer()
            Text(description)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 预览

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
#endif
