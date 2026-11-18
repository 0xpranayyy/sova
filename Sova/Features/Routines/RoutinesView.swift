import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("theme") private var themeRaw = SovaTheme.ink.rawValue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rituals")
                            .font(.hero(40, weight: .medium))
                            .tracking(-1.8)
                            .foregroundStyle(Color.ink)
                        Text(String(localized: "\(routines.filter { $0.isDone(on: .now) }.count) of \(routines.filter { $0.isScheduled(on: .now) }.count) done today."))
                            .font(.allo(.subheadline))
                            .foregroundStyle(Color.inkSecondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 12)

                    if routines.isEmpty {
                        EmptyState(title: String(localized: "No rituals yet"),
                                   message: String(localized: "Rituals are things you do on a schedule, like reading or a morning walk."),
                                   actionTitle: String(localized: "Add a routine")) { router.sheet = .newRoutine }
                    } else {
                        WeekStrip(routines: routines, color: .black)
                            .padding(.bottom, 4)
                        ForEach(DayPeriod.allCases) { period in
                            let items = routines.filter { $0.period == period }
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    SectionLabel(
                                        period.name,
                                        trailing: "\(items.filter { $0.isDone(on: .now) }.count) of \(items.filter { $0.isScheduled(on: .now) }.count)"
                                    )
                                    GroupedList(items: items, inset: 64) { routine in
                                        RoutineRow(routine: routine) { router.sheet = .routine(routine) }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .safeAreaInset(edge: .top, spacing: 0) {
                SovaNavPill {
                    Button { router.sheet = .newRoutine } label: {
                        Image(systemName: "plus").font(.system(size: 18)).frame(width: 36, height: 36)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("New ritual")
                }
                .padding(.top, 4)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

/// This week, one column per day, each with a small completion ring.
struct WeekStrip: View {
    let routines: [Routine]
    var color: Color

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

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                let isToday = day.isSameDay(as: .now)
                let isFuture = day > Date.now
                VStack(spacing: 8) {
                    Text(Weekdays.letter(day.weekday))
                        .font(.allo(.caption, .medium))
                        .foregroundStyle(isToday ? Color.ink : Color.inkTertiary)
                    ZStack {
                        MiniRing(progress: isFuture ? 0 : fraction(for: day), color: color, lineWidth: 3)
                        Text(day, format: .dateTime.day())
                            .font(.mono(12, weight: isToday ? .semibold : .regular))
                            .foregroundStyle(isFuture ? Color.inkTertiary : Color.ink)
                    }
                    .frame(width: 36, height: 36)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day()))
                .accessibilityValue(isFuture ? "Upcoming" : fraction(for: day).formatted(.percent.precision(.fractionLength(0))))
            }
        }
        .surface(cornerRadius: 20, padding: 14)
    }
}
