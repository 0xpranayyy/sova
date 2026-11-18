import SwiftUI

/// The page every screen sits on: warm paper, a soft wash of the theme's
/// light at the top, and a whisper of film grain.
struct CanvasBackground: View {
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = SovaTheme(rawValue: themeRaw) ?? .ember
        let dark = scheme == .dark
        ZStack {
            Color.canvas
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    Circle()
                        .fill(theme.accent.color)
                        .frame(width: w * 1.2, height: w * 1.2)
                        .offset(x: -w * 0.5, y: -w * 0.85)
                        .opacity(dark ? 0.26 : 0.16)
                    Circle()
                        .fill(theme.companion.color)
                        .frame(width: w, height: w)
                        .offset(x: w * 0.55, y: -w * 0.7)
                        .opacity(dark ? 0.16 : 0.14)
                }
                .blur(radius: 90)
                .frame(width: w, height: geo.size.height, alignment: .top)
            }
            GrainOverlay()
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.8), value: themeRaw)
        .accessibilityHidden(true)
    }
}

struct GrainOverlay: View {
    @Environment(\.colorScheme) private var scheme
    var intensity: Double = 1

    var body: some View {
        Image("Grain")
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity((scheme == .dark ? 0.07 : 0.09) * intensity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}
