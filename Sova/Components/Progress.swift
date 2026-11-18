import SwiftUI

/// A thin, precise progress line, optionally with milestone nodes.
struct ProgressLine: View {
    var progress: Double
    var color: Color
    var height: CGFloat = 4
    /// Completion state of each milestone, drawn as evenly spaced nodes.
    var milestones: [Bool] = []
    var track: Color = Color.well

    var body: some View {
        GeometryReader { geo in
            let value = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(color)
                    .frame(width: value == 0 ? 0 : max(height, geo.size.width * value))
                ForEach(Array(milestones.enumerated()), id: \.offset) { index, done in
                    let x = geo.size.width * Double(index + 1) / Double(milestones.count + 1)
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().strokeBorder(done ? color : Color.night.opacity(0.15), lineWidth: 3))
                        .frame(width: height + 2, height: height + 2)
                        .position(x: x, y: height / 2)
                }
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

/// The day as chunky ticks, one per task or ritual.
struct DaySegments: View {
    var done: Int
    var total: Int
    var color: Color
    var height: CGFloat = 14

    var body: some View {
        Group {
            if total <= 24 {
                HStack(spacing: 4) {
                    ForEach(0..<max(total, 1), id: \.self) { index in
                        Capsule()
                            .fill(index < done ? color : color.opacity(0.14))
                            .frame(height: height)
                            .animation(.spring(response: 0.45, dampingFraction: 0.75).delay(Double(index) * 0.03), value: done)
                    }
                }
            } else {
                ProgressLine(progress: Double(done) / Double(total), color: color, height: height)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Today's progress")
        .accessibilityValue("\(done) of \(total) done")
    }
}

/// A goal's progress: one chunky segment per step, or a single bar.
struct StepBar: View {
    var progress: Double
    var steps: [Bool]
    var color: Color
    var height: CGFloat = 14

    var body: some View {
        Group {
            if steps.isEmpty {
                ProgressLine(progress: progress, color: color, height: height, track: color.opacity(0.2))
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { _, done in
                        Capsule()
                            .fill(done ? color : color.opacity(0.2))
                            .frame(height: height)
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: steps)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
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

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var colors: [Color]

    var body: some View {
        let color = colors.first ?? .accentColor
        ZStack {
            Circle().stroke(Color.well, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
        }
        .padding(lineWidth / 2)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
    }
}
