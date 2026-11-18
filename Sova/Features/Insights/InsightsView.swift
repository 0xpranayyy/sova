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
                VStack(alignment: .leading, spacing: 24) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        StatTile(symbol: "checkmark.circle.fill", value: "\(tasksThisWeek)",
                                 label: String(localized: "Tasks this week"), accent: .iris)
                        StatTile(symbol: "flame.fill", value: "\(bestStreak?.streak ?? 0)",
                                 label: bestStreak.map { String(localized: "Best streak · \($0.title)") } ?? String(localized: "Best streak"),
                                 accent: .coral)
                        StatTile(symbol: "repeat", value: consistency.formatted(.percent.precision(.fractionLength(0))),
                                 label: String(localized: "Routine consistency"), accent: .lagoon)
                        StatTile(symbol: "target", value: goalAverage.formatted(.percent.precision(.fractionLength(0))),
                                 label: String(localized: "Avg. goal progress"), accent: .orchid)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: String(localized: "Last 7 Days"), symbol: "chart.bar.fill")
                        Chart(stats) { stat in
                            BarMark(
                                x: .value("Day", stat.day, unit: .day),
                                y: .value("Completed", stat.count)
                            )
                            .foregroundStyle(by: .value("Kind", stat.kind))
                            .cornerRadius(6)
                        }
                        .chartForegroundStyleScale([
                            tasksLabel: Accent.iris.gradient,
                            routinesLabel: Accent.lagoon.gradient,
                        ])
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))
                                AxisValueLabel()
                            }
                        }
                        .chartLegend(position: .top, alignment: .leading)
                        .frame(height: 220)
                        .card(cornerRadius: 26)
                    }

                    if !routines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: String(localized: "Consistency"), symbol: "waveform.path.ecg",
                                          trailing: String(localized: "30 days"))
                            VStack(spacing: 16) {
                                ForEach(routines.sorted { $0.consistency(days: 30) > $1.consistency(days: 30) }) { routine in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Label(routine.title, systemImage: routine.symbol)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(routine.accent.color)
                                            Spacer()
                                            Text(routine.consistency(days: 30), format: .percent.precision(.fractionLength(0)))
                                                .font(.subheadline.weight(.bold).monospacedDigit())
                                        }
                                        GradientProgressBar(progress: routine.consistency(days: 30), accent: routine.accent, height: 8)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                            .card(cornerRadius: 26)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background { AuroraBackground() }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { ThemeMenu() }
            }
        }
    }
}

private struct StatTile: View {
    let symbol: String
    let value: String
    let label: String
    let accent: Accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(accent.gradient, in: .rect(cornerRadius: 11, style: .continuous))
            Text(value)
                .font(.title.weight(.bold).monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
        .card(tint: accent.color, cornerRadius: 24, padding: 16)
        .accessibilityElement(children: .combine)
    }
}
