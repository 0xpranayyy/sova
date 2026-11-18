import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Routine.order) private var routines: [Routine]

    private var dueToday: [Routine] { routines.filter { $0.isScheduled(on: .now) } }
    private var doneToday: Int { dueToday.filter { $0.isDone(on: .now) }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenTitle(title: String(localized: "Rituals"),
                                subtitle: routines.isEmpty ? String(localized: "Little things, every day")
                                    : String(localized: "\(doneToday) of \(dueToday.count) today")) {
                        CircleAction(symbol: "plus", label: String(localized: "New ritual")) { router.sheet = .newRoutine }
                    }
                    .padding(.top, 4)

                    if routines.isEmpty {
                        EmptyState(title: String(localized: "No rituals yet"),
                                   message: String(localized: "Rituals are things you do on a schedule, like reading or a morning walk."),
                                   actionTitle: String(localized: "Add a ritual")) { router.sheet = .newRoutine }
                    } else {
                        WeekStage(routines: routines, done: doneToday, total: dueToday.count)

                        ForEach(DayPeriod.allCases) { period in
                            let items = routines.filter { $0.period == period }
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    PeriodHeader(period: period,
                                                 done: items.filter { $0.isScheduled(on: .now) && $0.isDone(on: .now) }.count,
                                                 total: items.filter { $0.isScheduled(on: .now) }.count)
                                    VStack(spacing: 10) {
                                        ForEach(items) { routine in
                                            RoutineRow(routine: routine) { router.sheet = .routine(routine) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

/// This week on indigo: one fat column per day that fills with yellow as
/// rituals get done, the owl perched on today, and the best streak as a
/// mint starburst.
struct WeekStage: View {
    let routines: [Routine]
    let done: Int
    let total: Int

    @State private var cheers = 0

    private var days: [Date] {
        let today = Date.now.startOfDay
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).map { start.adding(days: $0) }
    }

    private func fraction(for day: Date) -> Double {
        let scheduled = routines.filter { $0.isScheduled(on: day) }
        guard !scheduled.isEmpty else { return 0 }
        return Double(scheduled.filter { $0.isDone(on: day) }.count) / Double(scheduled.count)
    }

    private var bestStreak: Int { routines.map(\.streak).max() ?? 0 }

    var body: some View {
        let tone = StickerTone.indigo
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    MonoCaps(String(localized: "This week"), color: tone.deep)
                    Text(total == 0 ? String(localized: "A rest day")
                         : done == total ? String(localized: "All done today")
                         : String(localized: "\(total - done) left today"))
                        .font(.allo(size: 24, weight: .heavy, relativeTo: .title2))
                        .tracking(-0.6)
                        .foregroundStyle(Color.white)
                        .contentTransition(.numericText())
                }
                Spacer(minLength: 0)
                if bestStreak > 1 {
                    Starburst(value: "\(bestStreak)", caption: String(localized: "day streak"),
                              tone: .mint, size: 74, tilt: 10)
                        .padding(.top, -8)
                        .padding(.trailing, -6)
                }
            }

            HStack(alignment: .bottom, spacing: 7) {
                ForEach(days, id: \.self) { day in
                    let isToday = day.isSameDay(as: .now)
                    let isFuture = day > Date.now && !isToday
                    let value = isFuture ? 0 : fraction(for: day)
                    VStack(spacing: 6) {
                        if isToday {
                            OwlMark(size: 34, happy: total > 0 && done == total,
                                    bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                                    pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8),
                                    celebrate: cheers)
                                .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 80, height: 60), count: 10) }
                        } else {
                            Color.clear.frame(height: 34)
                        }
                        ZStack(alignment: .bottom) {
                            Capsule().fill(Color.white.opacity(isFuture ? 0.06 : 0.13))
                            Capsule()
                                .fill(StickerTone.yellow.fill)
                                .frame(height: value > 0 ? max(22, 84 * value) : 0)
                                .opacity(value > 0 ? 1 : 0)
                        }
                        .frame(height: 84)
                        .overlay {
                            if isToday {
                                Capsule().strokeBorder(StickerTone.yellow.fill, lineWidth: 2.5)
                            }
                        }
                        Text(Weekdays.letter(day.weekday))
                            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption2))
                            .foregroundStyle(isToday ? tone.deep : Color.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day()))
                    .accessibilityValue(isFuture ? String(localized: "Upcoming")
                                        : value.formatted(.percent.precision(.fractionLength(0))))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: done)
        }
        .padding(20)
        .background {
            ZStack {
                tone.fill
                SparkleDot(color: StickerTone.pink.fill, size: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 150).padding(.top, 18)
                SparkleDot(color: StickerTone.cyan.fill, size: 11)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 98).padding(.top, 54)
            }
        }
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .onChange(of: done) { old, new in
            if total > 0, new == total, old < total {
                cheers += 1
                Haptics.celebrate()
            }
        }
    }
}

/// A small tilted pill naming a part of the day, with its count.
private struct PeriodHeader: View {
    let period: DayPeriod
    let done: Int
    let total: Int

    private var tone: StickerTone {
        switch period {
        case .morning: .orange
        case .afternoon: .yellow
        case .evening: .lilac
        case .anytime: .cyan
        }
    }

    private var symbol: String {
        switch period {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        case .anytime: "sparkles"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Label(period.name, systemImage: symbol)
                .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                .foregroundStyle(tone.deep)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(tone.fill, in: .capsule)
                .rotationEffect(.degrees(-3))
            Spacer()
            if total > 0 {
                Text("\(done) of \(total)")
                    .font(.mono(13))
                    .foregroundStyle(Color.inkSecondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.top, 6)
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
