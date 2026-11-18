import SwiftUI

/// Near-black page with one faint wash of the accent at the top: the
/// single signature glow per screen.
struct CanvasBackground: View {
    @AppStorage("theme") private var themeRaw = SovaTheme.lime.rawValue
    var glow: Double = 0.08

    var body: some View {
        let accent = (SovaTheme(rawValue: themeRaw) ?? .lime).accent.color
        ZStack(alignment: .top) {
            Color.canvas
            GeometryReader { geo in
                RadialGradient(colors: [accent.opacity(glow), .clear],
                               center: UnitPoint(x: 0.15, y: 0),
                               startRadius: 0, endRadius: geo.size.width * 1.1)
                    .frame(height: geo.size.width * 0.95)
            }
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.6), value: themeRaw)
        .accessibilityHidden(true)
    }
}
