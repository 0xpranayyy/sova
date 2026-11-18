import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var colors: [Color]

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(colors: colors + [colors.first ?? .accentColor], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (colors.first ?? .accentColor).opacity(0.45), radius: 8)
                .opacity(progress > 0 ? 1 : 0)
        }
        .padding(lineWidth / 2)
        .animation(.spring(duration: 0.8, bounce: 0.25), value: progress)
    }
}

struct GradientProgressBar: View {
    var progress: Double
    var accent: Accent
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(accent.gradient)
                    .frame(width: max(height, geo.size.width * clamped))
                    .shadow(color: accent.color.opacity(0.45), radius: 6, y: 2)
                    .opacity(clamped > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
        .animation(.spring(duration: 0.6), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    VStack(spacing: 30) {
        ProgressRing(progress: 0.66, colors: AuroraTheme.aurora.ringColors).frame(width: 120, height: 120)
        GradientProgressBar(progress: 0.4, accent: .coral)
    }
    .padding()
}
