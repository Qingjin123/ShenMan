import SwiftUI

/// 侧边栏视图 - 使用玻璃材质
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // 应用标题
            appTitle

            Divider()

            // 主导航
            mainNavigation

            Divider()

            // 最近分类（合并历史记录）
            recentCategories

            Spacer()

            // 底部操作
            bottomActions
        }
        .padding(.spacingSM)
        .sidebarGlassMaterial
        .onAppear {
            print("[SidebarView] 侧边栏已加载")
        }
    }

    // MARK: - 子视图

    private var appTitle: some View {
        VStack(spacing: .spacingXS) {
            Text("声声慢")
                .font(.shenManTitle2())
                .fontWeight(.bold)

            Text("ShenMan")
                .font(.shenManCaption2())
                .foregroundColor(.secondary)
        }
        .padding(.vertical, .spacingMD)
    }

    private var mainNavigation: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            SidebarNavItem(
                icon: "house.fill",
                title: "主页",
                isSelected: appState.currentView == .home
            ) {
                appState.currentView = .home
            }

            SidebarNavItem(
                icon: "list.bullet",
                title: "历史记录",
                isSelected: false
            ) {
                appState.showHistory = true
            }

            SidebarNavItem(
                icon: "gearshape",
                title: "设置",
                isSelected: false
            ) {
                appState.showSettings = true
            }
        }
        .padding(.vertical, .spacingSM)
    }

    private var recentCategories: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text("最近")
                .font(.shenManCaption())
                .foregroundColor(.secondary)
                .padding(.horizontal, .spacingSM)

            SidebarCategoryItem(title: "全部", count: appState.transcriptionHistory.count)
        }
        .padding(.top, .spacingSM)
    }

    private var bottomActions: some View {
        VStack(spacing: .spacingSM) {
            Button(action: {
                appState.showBatchImport = true
            }) {
                Label("批量导入", systemImage: "square.on.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - 侧边栏导航项

struct SidebarNavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingSM) {
                Image(systemName: icon)
                    .frame(width: 16)

                Text(title)
                    .font(.shenManSubheadline())

                Spacer()
            }
            .padding(.horizontal, .spacingSM)
            .padding(.vertical, .spacingXS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusSM)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 侧边栏分类项

struct SidebarCategoryItem: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Circle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 6, height: 6)

            Text(title)
                .font(.shenManFootnote())

            Spacer()

            Text("(\(count))")
                .font(.shenManCaption())
                .foregroundColor(.shenManTextTertiary)
        }
        .padding(.horizontal, .spacingSM)
        .padding(.vertical, .spacingXS)
    }
}
