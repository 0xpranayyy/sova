import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Routine.order) private var routines: [Routine]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    if routines.isEmpty {
                        EmptyCard(symbol: "repeat",
                                  title: String(localized: "Build a rhythm"),
                                  message: String(localized: "Small things, repeated, become who you are."),
                                  actionTitle: String(localized: "Create a Routine")) { router.sheet = .newRoutine }
                    } else {
                        WeekStrip(routines: routines)
                        ForEach(DayPeriod.allCases) { period in
                            let items = routines.filter { $0.period == period }
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(
                                        title: period.name,
                                        symbol: period.symbol,
                                        trailing: "\(items.filter { $0.isDone(on: .now) }.count)/\(items.filter { $0.isScheduled(on: .now) }.count)"
                                    )
                                    GlassEffectContainer(spacing: 20) {
                                        VStack(spacing: 10) {
                                            ForEach(items) { routine in
                                                RoutineCard(routine: routine) { router.sheet = .routine(routine) }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background { AuroraBackground() }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Routine", systemImage: "plus") { router.sheet = .newRoutine }
                }
            }
        }
    }
}

/// This week, one column per day, each with a tiny completion ring.
struct WeekStrip: View {
    let routines: [Routine]

    private var days: [Date] {
        let today = Date.now.startOfDay
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
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
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isToday ? Color.accentColor : Color.secondary)
                    ZStack {
                        ProgressRing(progress: isFuture ? 0 : fraction(for: day), lineWidth: 4,
                                     colors: [Accent.lagoon.color, Accent.iris.color])
                        Text(day, format: .dateTime.day())
                            .font(.footnote.weight(isToday ? .bold : .medium).monospacedDigit())
                            .foregroundStyle(isFuture ? Color.secondary : Color.primary)
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if isToday {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day()))
                .accessibilityValue(isFuture ? "Upcoming" : fraction(for: day).formatted(.percent.precision(.fractionLength(0))))
            }
        }
        .card(cornerRadius: 26, padding: 10)
    }
}
