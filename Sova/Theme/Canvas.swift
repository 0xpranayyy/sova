import SwiftUI

/// Warm cream paper.
struct CanvasBackground: View {
    var glow: Double = 0

    var body: some View {
        Color.canvas
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// Sova's signature: the day as a sky. A sun crosses a dotted arc as you
/// finish things, over a horizon where the owl sits. The sky's color
/// follows the actual time of day.
struct SkyCard<Content: View>: View {
    var progress: Double
    var sky: Color = .sky()
    var owlHappy = false
    var height: CGFloat = 250
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let horizon = height - 54
            let radius = min(w * 0.37, horizon - 46)
            let center = CGPoint(x: w / 2, y: horizon)
            let p = min(max(progress, 0), 1)
            let angle = Double.pi * (1 - p)
            let sun = CGPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))

            ZStack(alignment: .topLeading) {
                sky

                // Ground below the horizon.
                Rectangle()
                    .fill(Color.night.opacity(0.07))
                    .frame(height: height - horizon)
                    .offset(y: horizon)
                Rectangle()
                    .fill(Color.night.opacity(0.25))
                    .frame(height: 1.5)
                    .offset(y: horizon)

                // The full path of the day, then the part already travelled.
                SkyArc(center: center, radius: radius, progress: 1)
                    .stroke(Color.night.opacity(0.18), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 8]))
                SkyArc(center: center, radius: radius, progress: p)
                    .stroke(Color.night, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                Circle()
                    .fill(Color.ember)
                    .frame(width: 34, height: 34)
                    .position(sun)

                OwlMark(size: 46, happy: owlHappy)
                    .position(x: p > 0.6 ? 20 + 23 : w - 20 - 23, y: horizon - 21)

                content
                    .frame(width: w, height: height, alignment: .top)
            }
            .animation(reduceMotion ? nil : .spring(response: 0.9, dampingFraction: 0.8), value: p)
        }
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 30, style: .continuous))
    }
}

/// The upper half of a circle, drawn from the left up to `progress`.
struct SkyArc: Shape {
    var center: CGPoint
    var radius: CGFloat
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(180 + 180 * progress), clockwise: false)
        return path
    }
}
