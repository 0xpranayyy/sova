import SwiftUI

/// A ritual as a block in its color: icon, name, schedule, the last seven
/// days, and a big check.
struct RoutineRow: View {
    let routine: Routine
    var onOpen: () -> Void

    var body: some View {
        let tone = StickerTone(routine.accent)
        let ink = tone == .indigo ? Color.white : tone.deep
        let done = routine.isDone(on: .now)
        HStack(spacing: 12) {
            Image(systemName: routine.symbol)
                .font(.system(size: 21, weight: .semibold))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                HStack(spacing: 8) {
                    WeekTrack(routine: routine, color: ink)
                    Text(routine.streak > 1 ? String(localized: "\(routine.streak) days") : Weekdays.summary(for: routine.weekdays))
                        .font(.allo(size: 10.5, weight: .heavy, relativeTo: .caption2))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .opacity(0.75)
                }
            }
            Spacer(minLength: 0)
            if routine.isScheduled(on: .now) {
                CheckButton(isOn: done, color: tone.deep, round: true, size: 32, checkColor: tone.fill, label: routine.title) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { routine.toggle(on: .now) }
                }
            } else {
                MonoCaps(String(localized: "Rest"), color: ink.opacity(0.6))
                    .frame(width: 44)
            }
        }
        .foregroundStyle(ink)
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
        .background(tone.fill, in: .rect(cornerRadius: 24, style: .continuous))
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
    }
}

/// The last seven days as tiny cells; today is outlined.
struct WeekTrack: View {
    let routine: Routine
    var color: Color = .ink

    var body: some View {
        HStack(spacing: 3) {
            ForEach(-6...0, id: \.self) { offset in
                let day = Date.now.adding(days: offset)
                let done = routine.isDone(on: day)
                let scheduled = routine.isScheduled(on: day)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(done ? color : color.opacity(scheduled ? 0.18 : 0.06))
                    .overlay {
                        if offset == 0 {
                            RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(color, lineWidth: 1.5)
                        }
                    }
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Last 7 days")
        .accessibilityValue("\((-6...0).filter { routine.isDone(on: Date.now.adding(days: $0)) }.count) of 7 done")
    }
}
