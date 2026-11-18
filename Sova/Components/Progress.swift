import SwiftUI

/// A thin, precise progress line.
struct ProgressLine: View {
    var progress: Double
    var color: Color
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let value = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.well)
                Capsule()
                    .fill(color)
                    .frame(width: value == 0 ? 0 : max(height, geo.size.width * value))
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

/// The day as a row of segments, one per task or routine.
struct DaySegments: View {
    var done: Int
    var total: Int
    var color: Color

    var body: some View {
        Group {
            if total == 0 {
                Capsule().fill(Color.well).frame(height: 6)
            } else if total <= 24 {
                HStack(spacing: 3) {
                    ForEach(0..<total, id: \.self) { index in
                        Capsule()
                            .fill(index < done ? color : Color.well)
                            .frame(height: 6)
                            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.02), value: done)
                    }
                }
            } else {
                ProgressLine(progress: Double(done) / Double(total), color: color, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Today's progress")
        .accessibilityValue("\(done) of \(total) done")
    }
}

/// A small ring for compact places (the week strip).
struct MiniRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle().stroke(Color.well, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
    }
}

/// The day's progress as a solid ring, Fitness-style: the track is a
/// faint version of the same color.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var colors: [Color]

    var body: some View {
        ZStack {
            let color = colors.first ?? .accentColor
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
        }
        .padding(lineWidth / 2)
        .animation(.spring(response: 0.8, dampingFraction: 0.75), value: progress)
    }
}
