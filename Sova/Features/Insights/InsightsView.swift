import SwiftUI
import SwiftData
import Charts

private struct DayStat: Identifiable {
    let day: Date
    let kind: String
    let count: Int
    var id: String { "\(day.timeIntervalSince1970)-\(kind)" }
}

struct InsightsView: View {
    @Query private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }
    private let tasksLabel = String(localized: "Tasks")
    private let routinesLabel = String(localized: "Routines")

    private var weekDays: [Date] {
        let today = Date.now.startOfDay
        return (0..<7).map { today.adding(days: $0 - 6) }
    }

    private var stats: [DayStat] {
        weekDays.flatMap { day in
            [
                DayStat(day: day, kind: tasksLabel,
                        count: tasks.filter { $0.completedAt?.isSameDay(as: day) == true }.count),
                DayStat(day: day, kind: routinesLabel,
                        count: routines.filter { $0.isDone(on: day) }.count),
            ]
        }
    }

    private var weekTotal: Int { stats.map(\.count).reduce(0, +) }

    private var tasksThisWeek: Int {
        let start = weekDays.first ?? .now
        return tasks.filter { ($0.completedAt ?? .distantPast) >= start }.count
    }

    private var bestStreak: Routine? { routines.max { $0.streak < $1.streak } }

    private var consistency: Double {
        guard !routines.isEmpty else { return 0 }
        return routines.map { $0.consistency(days: 30) }.reduce(0, +) / Double(routines.count)
    }

    private var goalAverage: Double {
        guard !goals.isEmpty else { return 0 }
        return goals.map(\.progress).reduce(0, +) / Double(goals.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 6) {
                        Group {
                            if weekTotal == 0 {
                                Text("Your week starts here.")
                            } else {
                                Text("\(Text("\(weekTotal)").foregroundStyle(theme.accent.color)) things done this week.")
                            }
                        }
                        .font(.display(.title))
                        .foregroundStyle(Color.ink)
                        Text(weekTotal == 0 ? "Finish a task or check in on a routine, and your progress shows up here."
                                            : "Tasks and routines, the last seven days.")
                            .font(.subheadline)
                            .foregroundStyle(Color.inkSecondary)
                    }
                    .padding(.horizontal, 4)

                    chart

                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            StatTile(value: "\(tasksThisWeek)", label: String(localized: "Tasks finished"))
                            StatTile(value: "\(bestStreak?.streak ?? 0)",
                                     label: bestStreak.map { String(localized: "Day streak, \($0.title.lowercased())") }
                                         ?? String(localized: "Day streak"))
                        }
                        GridRow {
                            StatTile(value: consistency.formatted(.percent.precision(.fractionLength(0))),
                                     label: String(localized: "Routine consistency"))
                            StatTile(value: goalAverage.formatted(.percent.precision(.fractionLength(0))),
                                     label: String(localized: "Average goal progress"))
                        }
                    }

                    if !routines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(String(localized: "Consistency"), trailing: String(localized: "30 days"))
                            VStack(spacing: 18) {
                                ForEach(routines.sorted { $0.consistency(days: 30) > $1.consistency(days: 30) }) { routine in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(routine.title)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.ink)
                                            Spacer()
                                            Text(routine.consistency(days: 30), format: .percent.precision(.fractionLength(0)))
                                                .font(.subheadline.monospacedDigit())
                                                .foregroundStyle(Color.inkSecondary)
                                        }
                                        ProgressLine(progress: routine.consistency(days: 30), color: routine.accent.color)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                            .surface(cornerRadius: 22, padding: 18)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .navigationTitle("Insights")
        }
    }

    private var chart: some View {
        Chart(stats) { stat in
            BarMark(
                x: .value("Day", stat.day, unit: .day),
                y: .value("Completed", stat.count),
                width: .ratio(0.5)
            )
            .foregroundStyle(by: .value("Kind", stat.kind))
            .cornerRadius(3)
        }
        .chartForegroundStyleScale([
            tasksLabel: theme.accent.color,
            routinesLabel: theme.companion.color,
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine().foregroundStyle(Color.hairline)
                AxisValueLabel().foregroundStyle(Color.inkTertiary)
            }
        }
        .chartLegend(position: .top, alignment: .leading, spacing: 14)
        .frame(height: 200)
        .surface(cornerRadius: 22, padding: 18)
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.display(.largeTitle))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .lineLimit(2, reservesSpace: true)
        }
        .surface(cornerRadius: 22, padding: 16)
        .accessibilityElement(children: .combine)
    }
}
