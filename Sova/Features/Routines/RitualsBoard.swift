import SwiftUI

/// This week at a glance: one dot per day, filled by how much of that
/// day's rituals you kept. Today has a yellow ring.
struct WeekDots: View {
    let routines: [Routine]

    private var days: [Date] {
        let cal = Calendar.current
        let today = Date.now.startOfDay
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).map { start.adding(days: $0) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                dot(for: day)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "This week's rituals"))
    }

    private func share(on day: Date) -> Double? {
        guard day <= Date.now.startOfDay else { return nil }
        let due = routines.filter { $0.isScheduled(on: day) && $0.createdAt.startOfDay <= day }
        guard !due.isEmpty else { return nil }
        return Double(due.filter { $0.isDone(on: day) }.count) / Double(due.count)
    }

    private func dot(for day: Date) -> some View {
        let value: Double? = share(on: day)
        let isToday: Bool = Calendar.current.isDateInToday(day)
        let fill: Color = {
            guard let value else { return Color.ink.opacity(0.05) }
            if value >= 1 { return StickerTone.indigo.fill }
            if value >= 0.5 { return StickerTone.lilac.lip }
            return value > 0 ? StickerTone.lilac.fill : Color.ink.opacity(0.07)
        }()
        return VStack(spacing: 6) {
            ZStack {
                Circle().fill(fill)
                if (value ?? 0) >= 1 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(StickerTone.yellow.fill)
                }
            }
            .frame(width: 38, height: 38)
            .overlay {
                if isToday { Circle().strokeBorder(StickerTone.yellow.fill, lineWidth: 3).padding(-3) }
            }
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.allo(size: 12, weight: .heavy, relativeTo: .caption2))
                .foregroundStyle(isToday ? Color.ink : Color.inkSecondary)
        }
    }
}

/// One part of the day as a soft band of its color, with that part's
/// rituals as tiles inside.
struct PeriodBand: View {
    let period: DayPeriod
    let items: [Routine]
    var isNow = false
    let onOpen: (Routine) -> Void

    private var tone: StickerTone {
        switch period {
        case .morning: .yellow
        case .afternoon: .cyan
        case .evening: .lilac
        case .anytime: .mint
        }
    }

    var body: some View {
        let done: Int = items.filter { $0.isDone(on: .now) }.count
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: period.symbol).font(.system(size: 11, weight: .heavy))
                MonoCaps(period.name, color: tone.deep)
                if isNow {
                    Text(String(localized: "now"))
                        .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(tone.fill, in: .capsule)
                }
                Spacer()
                Text("\(done)/\(items.count)")
                    .font(.mono(11))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(tone.deep)
            .padding(.horizontal, 4)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, routine in
                    RitualCard(routine: routine, tilt: index.isMultiple(of: 2) ? -1.5 : 1.5, width: nil) {
                        onOpen(routine)
                    }
                }
            }
        }
        .padding(14)
        .background(tone.fill.opacity(0.28), in: .rect(cornerRadius: Radius.card + 2, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(period.name)
    }
}
