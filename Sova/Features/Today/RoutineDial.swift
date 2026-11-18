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
                ZStack {
                    Circle()
                        .fill(done ? routine.accent.color : Color.surface)
                    Circle()
                        .strokeBorder(Color.hairline, lineWidth: 1)
                        .opacity(done ? 0 : 1)
                    Image(systemName: done ? "checkmark" : routine.symbol)
                        .font(.system(size: 20, weight: done ? .bold : .medium))
                        .foregroundStyle(done ? Color.white : routine.accent.color)
                        .contentTransition(.symbolEffect(.replace.downUp))
                }
                .frame(width: 60, height: 60)
                .shadow(color: done ? routine.accent.color.opacity(0.35) : .black.opacity(0.05),
                        radius: done ? 10 : 6, y: done ? 6 : 3)

                Text(routine.title)
                    .font(.caption)
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
