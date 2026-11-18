import SwiftUI

/// Tappable routine on Today. Glass because it's a control.
struct RoutineBubble: View {
    let routine: Routine
    @State private var taps = 0

    var body: some View {
        let done = routine.isDone(on: .now)
        Button {
            withAnimation(.bouncy) { routine.toggle(on: .now) }
            taps += 1
        } label: {
            VStack(spacing: 8) {
                Image(systemName: done ? "checkmark" : routine.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(done ? Color.white : routine.accent.color)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 66, height: 66)
                    .background {
                        Circle().fill(routine.accent.gradient).opacity(done ? 1 : 0)
                    }
                    .glassEffect(.control(tint: done ? routine.accent.color.opacity(0.5) : nil), in: .circle)
                Text(routine.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(done ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(done ? .success : .selection, trigger: taps)
        .accessibilityLabel(routine.title)
        .accessibilityValue(done ? "Done" : "Not done")
        .accessibilityHint("Double-tap to toggle")
    }
}
