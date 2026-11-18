import SwiftUI

/// A routine on Today: a round button that fills with its color when done.
struct RoutineDial: View {
    let routine: Routine

    var body: some View {
        let done = routine.isDone(on: .now)
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { routine.toggle(on: .now) }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: done ? "checkmark" : routine.symbol)
                    .font(.system(size: 22, weight: done ? .bold : .semibold))
                    .foregroundStyle(done ? Color.white : routine.accent.color)
                    .contentTransition(.symbolEffect(.replace.downUp))
                    .frame(width: 64, height: 64)
                    .background {
                        Circle().fill(routine.accent.gradient).opacity(done ? 1 : 0)
                    }
                    .glassEffect(Glass.card(tint: done ? routine.accent.color : nil, interactive: true), in: .circle)

                Text(routine.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(done ? Color.inkSecondary : Color.ink)
                    .lineLimit(1)
                    .frame(width: 76)
            }
        }
        .buttonStyle(.pressable)
        .sensoryFeedback(trigger: done) { _, isDone in isDone ? .success : .impact(weight: .light) }
        .accessibilityLabel(routine.title)
        .accessibilityValue(done ? "Done" : "Not done")
    }
}
