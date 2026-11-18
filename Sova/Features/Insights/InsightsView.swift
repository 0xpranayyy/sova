import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = SovaTheme.ink.rawValue

    private static let weeks = 17
    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .ink).accent.color }

    // MARK: Data

    /// Things finished on a given day: tasks plus ritual check-ins.
    private func activity(on day: Date) -> Int {
        tasks.filter { $0.completedAt?.isSameDay(as: day) == true }.count
            + routines.filter { $0.isDone(on: day) }.count
    }

    /// Columns of seven days (one per week), oldest first, ending this week.
    private var grid: [[Date?]] {
        let cal = Calendar.current
        let today = Date.now.startOfDay
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<Self.weeks).map { column in
            let start = weekStart.adding(days: (column - (Self.weeks - 1)) * 7)
            return (0..<7).map { row in
                let day = start.adding(days: row)
                return day > today ? nil : day
            }
        }
    }

    private func consistency(days: Int, endingDaysAgo offset: Int = 0) -> Double {
        let today = Date.now.startOfDay
        var scheduled = 0, done = 0
        for routine in routines {
            for i in offset..<(offset + days) {
                let day = today.adding(days: -i)
                guard day >= routine.createdAt.startOfDay, routine.isScheduled(on: day) else { continue }
                scheduled += 1
                if routine.isDone(on: day) { done += 1 }
            }
        }
        return scheduled == 0 ? 0 : Double(done) / Double(scheduled)
    }

    private var tasksDone: Int { tasks.filter(\.isDone).count }
    private var bestStreak: Int { routines.map(\.streak).max() ?? 0 }
    private var perDay: Double {
        let today = Date.now.startOfDay
        let total = (0..<30).map { activity(on: today.adding(days: -$0)) }.reduce(0, +)
        return Double(total) / 30
    }
    private var goalAverage: Double {
        goals.isEmpty ? 0 : goals.map(\.progress).reduce(0, +) / Double(goals.count)
    }

    // MARK: Body

    var body: some View {
        let current = consistency(days: 30)
        let previous = consistency(days: 30, endingDaysAgo: 30)
        let delta = Int(((current - previous) * 100).rounded())
        let hasHistory = !routines.isEmpty || tasksDone > 0

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(hasHistory ? String(localized: "Last 30 days") : String(localized: "Insights"))
                        .font(.allo(.subheadline, .medium))
                        .foregroundStyle(Color.inkSecondary)

                    if hasHistory {
                        HStack(alignment: .bottom, spacing: 12) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(Int((current * 100).rounded()), format: .number)
                                    .font(.hero(96, weight: .bold))
                                    .tracking(-5)
                                    .contentTransition(.numericText(value: current))
                                Text("%").font(.hero(40, weight: .medium)).foregroundStyle(Color.inkTertiary)
                            }
                            .foregroundStyle(Color.ink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("of rituals kept").font(.allo(.body, .medium)).foregroundStyle(Color.ink)
                                if routines.contains(where: { $0.createdAt < Date.now.adding(days: -30) }) {
                                    Text(delta >= 0 ? String(localized: "up \(delta)% from last month")
                                                    : String(localized: "down \(-delta)% from last month"))
                                        .font(.allo(.subheadline))
                                        .foregroundStyle(Color.inkSecondary)
                                }
                            }
                            .padding(.bottom, 14)
                        }
                    } else {
                        Text("No history yet.")
                            .font(.hero(34, weight: .medium))
                            .tracking(-1.2)
                            .foregroundStyle(Color.ink)
                            .padding(.top, 6)
                        Text("Finish tasks and check off rituals, and your activity shows up here.")
                            .font(.allo(.subheadline))
                            .foregroundStyle(Color.inkSecondary)
                            .padding(.top, 6)
                    }

                    WeekBars(values: weekCounts)
                        .surface(cornerRadius: 16, padding: 18)
                        .padding(.top, 22)

                    heatmap
                        .surface(cornerRadius: 16, padding: 16)
                        .padding(.top, 10)

                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            StatTile(value: "\(tasksDone)", label: String(localized: "Tasks done"))
                            StatTile(value: String(localized: "\(bestStreak) days"), label: String(localized: "Best streak"))
                        }
                        GridRow {
                            StatTile(value: perDay.formatted(.number.precision(.fractionLength(1))),
                                     label: String(localized: "Per day"))
                            StatTile(value: goalAverage.formatted(.percent.precision(.fractionLength(0))),
                                     label: String(localized: "Goal progress"))
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .safeAreaInset(edge: .top, spacing: 0) {
                SovaNavPill { EmptyView() }
                    .padding(.top, 4)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }

    /// Things finished on each of the last seven days, oldest first.
    private var weekCounts: [(Date, Int)] {
        let today = Date.now.startOfDay
        return (0..<7).map { offset in
            let day = today.adding(days: offset - 6)
            return (day, activity(on: day))
        }
    }

    private var heatmap: some View {
        let columns = grid
        let counts = columns.flatMap { $0 }.compactMap { $0 }.map(activity(on:))
        let peak = max(counts.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { row in
                            cell(for: week[row], peak: peak)
                        }
                    }
                }
            }
            HStack(spacing: 4) {
                ForEach(Array(columns.enumerated()), id: \.offset) { index, week in
                    let first = week.compactMap { $0 }.first
                    let showsMonth = first.map { day in
                        index == 0 || Calendar.current.component(.month, from: day)
                            != Calendar.current.component(.month, from: day.adding(days: -7))
                    } ?? false
                    Color.clear
                        .frame(width: 15, height: 12)
                        .overlay(alignment: .leading) {
                            if showsMonth, let first {
                                Text(first, format: .dateTime.month(.abbreviated))
                                    .font(.allo(.caption2))
                                    .foregroundStyle(Color.inkTertiary)
                                    .fixedSize()
                            }
                        }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Activity over the last \(Self.weeks) weeks")
    }

    /// Four steps of sunlight, from pale to deep gold.
    static func sunScale(_ level: Double) -> Color {
        switch level {
        case ..<0.3: Color(hex: 0xFBE7A6)
        case ..<0.55: Color(hex: 0xF6D261)
        case ..<0.8: Color(hex: 0xEDB821)
        default: Color(hex: 0xC9940A)
        }
    }

    @ViewBuilder
    private func cell(for day: Date?, peak: Int) -> some View {
        if let day {
            let count = activity(on: day)
            let level = count == 0 ? 0 : Double(count) / Double(peak)
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(count == 0 ? Color.well : Self.sunScale(level))
                .frame(width: 15, height: 15)
                .overlay {
                    if day.isSameDay(as: .now) {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(Color.black, lineWidth: 1.2)
                    }
                }
        } else {
            Color.clear.frame(width: 15, height: 15)
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoCaps(label)
            Text(value)
                .font(.hero(30, weight: .medium))
                .tracking(-1.2)
                .foregroundStyle(Color.ink)
                .contentTransition(.numericText())
        }
        .surface(cornerRadius: 16, padding: 16)
        .accessibilityElement(children: .combine)
    }
}

/// Seven fat capsules, one per day. Today is drawn in sunlight.
private struct WeekBars: View {
    let values: [(Date, Int)]

    var body: some View {
        let peak = max(values.map(\.1).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MonoCaps(String(localized: "This week"))
                Spacer()
                MonoCaps(String(localized: "\(values.map(\.1).reduce(0, +)) done"))
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                    let day = item.0
                    let count = item.1
                    let isToday = day.isSameDay(as: .now)
                    VStack(spacing: 8) {
                        Capsule()
                            .fill(isToday ? Color.sun : (count == 0 ? Color.well : Color.black))
                            .frame(height: max(14, 120 * Double(count) / Double(peak)))
                            .frame(maxWidth: .infinity)
                        Text(Weekdays.letter(day.weekday))
                            .font(.allo(.caption, isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.ink : Color.inkTertiary)
                    }
                }
            }
            .frame(height: 146, alignment: .bottom)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: values.map(\.1))
        }
        .accessibilityElement()
        .accessibilityLabel("This week")
        .accessibilityValue(values.map { "\($0.1)" }.joined(separator: ", "))
    }
}
