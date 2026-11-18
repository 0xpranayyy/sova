import SwiftUI

/// A routine as a list row: icon, name, schedule and streak, the last
/// seven days, and a round check.
struct RoutineRow: View {
    let routine: Routine
    var onOpen: () -> Void

    var body: some View {
        let done = routine.isDone(on: .now)
        HStack(spacing: 14) {
            IconTile(symbol: routine.symbol, accent: routine.accent, size: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.body)
                    .foregroundStyle(Color.ink)
                HStack(spacing: 10) {
                    WeekTrack(routine: routine)
                    if routine.streak > 1 {
                        Text("\(routine.streak) days")
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(routine.accent.color)
                            .contentTransition(.numericText())
                    }
                }
            }

            Spacer(minLength: 0)

            if routine.isScheduled(on: .now) {
                CheckButton(isOn: done, color: routine.accent.color, round: true, size: 28, label: routine.title) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { routine.toggle(on: .now) }
                }
            } else {
                Text("Rest")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.inkTertiary)
                    .frame(width: 44)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
    }
}

/// The last seven days as tiny bars; today is outlined.
struct WeekTrack: View {
    let routine: Routine

    var body: some View {
        HStack(spacing: 3) {
            ForEach(-6...0, id: \.self) { offset in
                let day = Date.now.adding(days: offset)
                let done = routine.isDone(on: day)
                let scheduled = routine.isScheduled(on: day)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(done ? routine.accent.color : (scheduled ? Color.well : Color.clear))
                    .overlay {
                        if !scheduled {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .strokeBorder(Color.hairline, lineWidth: 1)
                        }
                    }
                    .frame(width: 8, height: 12)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Last 7 days")
        .accessibilityValue("\((-6...0).filter { routine.isDone(on: Date.now.adding(days: $0)) }.count) of 7 done")
    }
}
