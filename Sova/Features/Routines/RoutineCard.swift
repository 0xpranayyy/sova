import SwiftUI

struct RoutineCard: View {
    let routine: Routine
    var onOpen: () -> Void
    @State private var taps = 0

    var body: some View {
        let done = routine.isDone(on: .now)
        let scheduledToday = routine.isScheduled(on: .now)

        HStack(spacing: 14) {
            Image(systemName: routine.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(routine.accent.gradient, in: .rect(cornerRadius: 16, style: .continuous))
                .shadow(color: routine.accent.color.opacity(0.4), radius: 8, y: 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label("\(routine.streak)", systemImage: "flame.fill")
                        .foregroundStyle(routine.streak > 0 ? Accent.coral.color : Color.secondary)
                        .contentTransition(.numericText())
                    Text(Weekdays.summary(for: routine.weekdays))
                        .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.semibold))
                WeekDots(routine: routine)
            }

            Spacer(minLength: 0)

            if scheduledToday {
                Button {
                    withAnimation(.bouncy) { routine.toggle(on: .now) }
                    taps += 1
                } label: {
                    Image(systemName: done ? "checkmark" : "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(done ? Color.white : routine.accent.color)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                        .background { Circle().fill(routine.accent.gradient).opacity(done ? 1 : 0) }
                        .glassEffect(.control(tint: done ? routine.accent.color.opacity(0.5) : nil), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(done ? "Mark \(routine.title) as not done" : "Mark \(routine.title) as done")
            } else {
                Text("Rest day")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .card(tint: done ? routine.accent.color : nil, cornerRadius: 26, padding: 14)
        .contentShape(.rect(cornerRadius: 26))
        .onTapGesture(perform: onOpen)
        .sensoryFeedback(done ? .success : .selection, trigger: taps)
    }
}

/// The last seven days at a glance.
struct WeekDots: View {
    let routine: Routine

    var body: some View {
        HStack(spacing: 5) {
            ForEach(-6...0, id: \.self) { offset in
                let day = Date.now.adding(days: offset)
                let done = routine.isDone(on: day)
                let scheduled = routine.isScheduled(on: day)
                Circle()
                    .fill(done ? AnyShapeStyle(routine.accent.gradient)
                               : AnyShapeStyle(Color.primary.opacity(scheduled ? 0.14 : 0.05)))
                    .frame(width: 9, height: 9)
                    .overlay {
                        if offset == 0 {
                            Circle().strokeBorder(routine.accent.color, lineWidth: 1.5).padding(-2.5)
                        }
                    }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Last 7 days")
        .accessibilityValue("\((-6...0).filter { routine.isDone(on: Date.now.adding(days: $0)) }.count) of 7 completed")
    }
}
