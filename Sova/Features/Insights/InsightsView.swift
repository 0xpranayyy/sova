import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = SovaTheme.lime.rawValue

    private static let weeks = 17
    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .lime).accent.color }

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
                    MonoCaps(String(localized: "Last \(Self.weeks) weeks"))

                    if hasHistory {
                        HStack(alignment: .bottom, spacing: 12) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(Int((current * 100).rounded()), format: .number)
                                    .font(.hero(96))
                                    .tracking(-4.5)
                                    .contentTransition(.numericText(value: current))
                                Text("%").font(.hero(42)).foregroundStyle(Color.inkTertiary)
                            }
                            .foregroundStyle(Color.ink)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("consistency").font(.subheadline.weight(.semibold)).foregroundStyle(Color.ink)
                                if routines.contains(where: { $0.createdAt < Date.now.adding(days: -30) }) {
                                    Text(delta >= 0 ? "↑ \(delta)% vs last month" : "↓ \(-delta)% vs last month")
                                        .font(.footnote)
                                        .foregroundStyle(delta >= 0 ? accent : Color.danger)
                                } else {
                                    Text("Rituals, last 30 days").font(.footnote).foregroundStyle(Color.inkTertiary)
                                }
                            }
                            .padding(.bottom, 14)
                        }
                        .padding(.top, 20)
                    } else {
                        Text("Your story starts here.")
                            .font(.hero(34, weight: .bold))
                            .tracking(-1.2)
                            .foregroundStyle(Color.ink)
                            .padding(.top, 20)
                        Text("Every task you finish and ritual you keep fills in a square below.")
                            .font(.subheadline)
                            .foregroundStyle(Color.inkSecondary)
                            .padding(.top, 8)
                    }

                    heatmap
                        .padding(.top, 26)

                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            StatTile(value: "\(tasksDone)", label: String(localized: "Tasks done"))
                            StatTile(value: String(localized: "\(bestStreak)d"), label: String(localized: "Best streak"))
                        }
                        GridRow {
                            StatTile(value: perDay.formatted(.number.precision(.fractionLength(1))),
                                     label: String(localized: "Per day"))
                            StatTile(value: goalAverage.formatted(.percent.precision(.fractionLength(0))),
                                     label: String(localized: "Goal progress"))
                        }
                    }
                    .padding(.top, 28)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .toolbarTitleDisplayMode(.inline)
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
                                    .font(.mono(10))
                                    .textCase(.uppercase)
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

    @ViewBuilder
    private func cell(for day: Date?, peak: Int) -> some View {
        if let day {
            let count = activity(on: day)
            let level = count == 0 ? 0 : Double(count) / Double(peak)
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(count == 0 ? Color.well : accent.opacity(0.25 + 0.75 * level))
                .frame(width: 15, height: 15)
                .overlay {
                    if day.isSameDay(as: .now) {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(Color.ink.opacity(0.7), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.hero(32))
                .tracking(-1.2)
                .foregroundStyle(Color.ink)
                .contentTransition(.numericText())
            MonoCaps(label, size: 10)
        }
        .surface(cornerRadius: 20, padding: 16)
        .accessibilityElement(children: .combine)
    }
}
