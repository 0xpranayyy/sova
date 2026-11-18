import SwiftUI

/// The vivid, slowly drifting color blend behind every screen. It's what
/// gives Liquid Glass something beautiful to refract.
struct CanvasBackground: View {
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    var theme: SovaTheme? = nil

    var body: some View {
        MeshBackdrop(colors: (theme ?? SovaTheme(rawValue: themeRaw) ?? .ember))
    }
}

struct MeshBackdrop: View {
    var colors: SovaTheme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 3, points: Self.points(at: t),
                         colors: colors.meshColors(dark: scheme == .dark))
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.9), value: colors)
        .accessibilityHidden(true)
    }

    static func points(at t: Double) -> [SIMD2<Float>] {
        let a = Float(sin(t * 0.31)) * 0.14
        let b = Float(cos(t * 0.23)) * 0.14
        let c = Float(sin(t * 0.17 + 1.3)) * 0.10
        return [
            [0, 0], [0.5 + a * 0.6, 0], [1, 0],
            [0, 0.45 + b], [0.5 + b, 0.5 + a], [1, 0.55 + c],
            [0, 1], [0.5 + c * 0.8, 1], [1, 1],
        ]
    }
}
