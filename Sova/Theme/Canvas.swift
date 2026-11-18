import SwiftUI

/// The page behind every screen: one calm, flat tint of the theme color.
/// No blends, no glows. Color comes from solid accents on top of it.
struct CanvasBackground: View {
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    var theme: SovaTheme? = nil

    var body: some View {
        MeshBackdrop(colors: theme ?? SovaTheme(rawValue: themeRaw) ?? .ember)
    }
}

/// Kept under its old name so every screen picks up the flat canvas.
struct MeshBackdrop: View {
    var colors: SovaTheme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Rectangle()
            .fill(colors.canvas(dark: scheme == .dark))
            .ignoresSafeArea()
            .animation(.smooth(duration: 0.6), value: colors)
            .accessibilityHidden(true)
    }
}
