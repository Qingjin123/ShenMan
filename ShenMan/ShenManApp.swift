import SwiftUI

/// 声声慢 App 入口
/// 一款面向中文用户的 macOS 语音转文字工具
@main
struct ShenManApp: App {
    // MARK: - 属性

    /// 全局应用状态
    @StateObject private var appState = AppState()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 650)
        .commands {
            // 添加菜单命令
            CommandGroup(replacing: .newItem) {
                Button("打开文件...") {
                    appState.showFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .appSettings) {
                Button("设置") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        // 设置窗口
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - 根导航视图

/// 使用 ZStack 实现简单的侧边栏 + 内容布局
struct RootNavigationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // 侧边栏 - 固定宽度
            SidebarView()
                .frame(width: 220)
            
            Divider()
            
            // 主内容区 - 自适应宽度
            ContentView()
                .frame(minWidth: 600)
        }
        .frame(minWidth: 820, minHeight: 550)
    }
}
