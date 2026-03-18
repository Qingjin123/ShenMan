import SwiftUI

// MARK: - 声声慢色彩系统 (v2 - 原生优先)

extension Color {
    // MARK: - 品牌色 (适度使用)

    /// 黛蓝 - 主色（仅用于强调和状态）
    static let shenManPrimary = Color(red: 0.25, green: 0.35, blue: 0.65)

    /// 青瓷 - 辅助色（少量点缀）
    static let shenManAccent = Color(red: 0.30, green: 0.55, blue: 0.55)

    // MARK: - 语义色 (使用系统色)

    static let shenManSuccess = Color.green
    static let shenManWarning = Color.orange
    static let shenManError = Color.red

    // MARK: - 中性色 (使用系统颜色，自动适配亮色/暗色模式)

    static let shenManBackground = Color.black.opacity(0.02)
    static let shenManBackgroundSecondary = Color.black.opacity(0.05)
    static let shenManBackgroundTertiary = Color.black.opacity(0.08)

    static let shenManCard = Color.white.opacity(0.8)
    static let shenManCardElevated = Color.white.opacity(0.9)

    static let shenManTextPrimary = Color.primary
    static let shenManTextSecondary = Color.secondary
    static let shenManTextTertiary = Color.secondary.opacity(0.6)

    static let shenManBorder = Color.black.opacity(0.1)
    static let shenManBorderStrong = Color.black.opacity(0.2)
}

// MARK: - 间距系统 (基于 8pt)

extension CGFloat {
    static let spacingXX: CGFloat = 2
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48
}

// MARK: - 圆角系统

extension CGFloat {
    static let cornerRadiusSM: CGFloat = 6
    static let cornerRadiusMD: CGFloat = 10
    static let cornerRadiusLG: CGFloat = 14
    static let cornerRadiusXL: CGFloat = 18
}

// MARK: - 阴影系统 (轻量级)

extension View {
    func shenManShadow(elevation: Int = 1) -> some View {
        switch elevation {
        case 0:
            return self.shadow(color: .clear, radius: 0, x: 0, y: 0)
        case 1:
            return self.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        case 2:
            return self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        case 3:
            return self.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        default:
            return self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - 字体 (使用系统字体，自动适配用户设置)

extension Font {
    static func shenManLargeTitle() -> Font { .largeTitle }
    static func shenManTitle() -> Font { .title }
    static func shenManTitle2() -> Font { .title2 }
    static func shenManTitle3() -> Font { .title3 }
    static func shenManHeadline() -> Font { .headline }
    static func shenManBody() -> Font { .body }
    static func shenManCallout() -> Font { .callout }
    static func shenManSubheadline() -> Font { .subheadline }
    static func shenManFootnote() -> Font { .footnote }
    static func shenManCaption() -> Font { .caption }
    static func shenManCaption2() -> Font { .caption2 }
    static func shenManMono() -> Font { .system(.body, design: .monospaced) }
}

// MARK: - 玻璃材质 (适度使用)

extension View {
    /// 侧边栏玻璃材质
    var sidebarGlassMaterial: some View {
        self.background(.ultraThinMaterial)
    }

    /// 工具栏玻璃材质
    var toolbarGlassMaterial: some View {
        self.background(.ultraThinMaterial)
    }

    /// 弹窗玻璃材质
    var popoverGlassMaterial: some View {
        self.background(.thickMaterial)
    }
}
