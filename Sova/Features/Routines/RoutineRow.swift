import SwiftUI

/// A ritual as a list row: icon, name, the last seven days, and a check.
struct RoutineRow: View {
    let routine: Routine
    var onOpen: () -> Void

    var body: some View {
        let done = routine.isDone(on: .now)
        HStack(spacing: 14) {
            IconTile(symbol: routine.symbol, size: 36, active: done)

            VStack(alignment: .leading, spacing: 7) {
                Text(routine.title)
                    .font(.allo(.body, .medium))
                    .foregroundStyle(Color.ink)
                HStack(spacing: 10) {
                    WeekTrack(routine: routine)
                    Text(routine.streak > 1 ? String(localized: "\(routine.streak)-day streak")
                                            : Weekdays.summary(for: routine.weekdays))
                        .font(.allo(.footnote))
                        .foregroundStyle(Color.inkTertiary)
                        .contentTransition(.numericText())
                }
            }

            Spacer(minLength: 0)

            if routine.isScheduled(on: .now) {
                CheckButton(isOn: done, round: true, size: 26, label: routine.title) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { routine.toggle(on: .now) }
                }
            } else {
                MonoCaps(String(localized: "Rest"), size: 10)
                    .frame(width: 44)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
    }
}

/// The last seven days as tiny cells; today is outlined.
struct WeekTrack: View {
    let routine: Routine

    var body: some View {
        let accent = Color.black
        HStack(spacing: 3) {
            ForEach(-6...0, id: \.self) { offset in
                let day = Date.now.adding(days: offset)
                let done = routine.isDone(on: day)
                let scheduled = routine.isScheduled(on: day)
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(done ? accent : (scheduled ? Color.well : Color.clear))
                    .overlay {
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .strokeBorder(offset == 0 ? Color.inkSecondary : Color.hairline, lineWidth: 1)
                            .opacity(offset == 0 || !scheduled ? 1 : 0)
                    }
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Last 7 days")
        .accessibilityValue("\((-6...0).filter { routine.isDone(on: Date.now.adding(days: $0)) }.count) of 7 done")
    }
}
