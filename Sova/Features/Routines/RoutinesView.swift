import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    if routines.isEmpty {
                        EmptyState(title: String(localized: "Build a rhythm"),
                                   message: String(localized: "Small things, repeated, become who you are."),
                                   actionTitle: String(localized: "Add a routine")) { router.sheet = .newRoutine }
                    } else {
                        WeekStrip(routines: routines,
                                  color: (SovaTheme(rawValue: themeRaw) ?? .ember).accent.color)
                        ForEach(DayPeriod.allCases) { period in
                            let items = routines.filter { $0.period == period }
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionLabel(
                                        period.name,
                                        trailing: "\(items.filter { $0.isDone(on: .now) }.count) of \(items.filter { $0.isScheduled(on: .now) }.count)"
                                    )
                                    GroupedList(items: items, inset: 68) { routine in
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
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Routine", systemImage: "plus") { router.sheet = .newRoutine }
                }
            }
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
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isToday ? Color.ink : Color.inkTertiary)
                    ZStack {
                        MiniRing(progress: isFuture ? 0 : fraction(for: day), color: color, lineWidth: 3)
                        Text(day, format: .dateTime.day())
                            .font(.footnote.weight(isToday ? .semibold : .regular).monospacedDigit())
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
        .surface(cornerRadius: 22, padding: 14)
    }
}
