import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue

    private static let weeks = 17
    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .ember).accent.color }

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
                    ScreenTitle(title: String(localized: "Insights")) { EmptyView() }
                        .padding(.top, 4)
                        .padding(.bottom, 14)

                    // The headline number, on indigo.
                    VStack(alignment: .leading, spacing: 0) {
                        Text(hasHistory ? String(localized: "Rituals kept · 30 days") : String(localized: "No history yet"))
                            .font(.allo(size: 10.5, weight: .heavy, relativeTo: .caption2))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .opacity(0.7)
                        HStack(alignment: .bottom, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(Int((current * 100).rounded()), format: .number)
                                    .font(.hero(84, weight: .heavy))
                                    .tracking(-4.5)
                                    .contentTransition(.numericText(value: current))
                                Text("%").font(.hero(36, weight: .heavy)).opacity(0.6)
                            }
                            .foregroundStyle(StickerTone.yellow.fill)
                            if hasHistory, routines.contains(where: { $0.createdAt < Date.now.adding(days: -30) }) {
                                Sticker(text: delta >= 0 ? "↑ \(delta)%" : "↓ \(-delta)%",
                                        tone: delta >= 0 ? .mint : .pink, size: 14, tilt: -4)
                                    .padding(.bottom, 14)
                            }
                        }
                        WeekBars(values: weekCounts)
                            .padding(.top, 12)
                    }
                    .foregroundStyle(Color.canvas)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 28, style: .continuous))

                    HStack(alignment: .center, spacing: 12) {
                        Sticker(text: "\(tasksDone)", tone: .pink, caption: String(localized: "Tasks done"), size: 40, tilt: -2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Starburst(value: "\(bestStreak)", caption: String(localized: "Day streak"), tone: .mint, size: 112, tilt: 8)
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 2)

                    heatmap
                        .surface(cornerRadius: 22, padding: 16)
                        .padding(.top, 14)

                    HStack(spacing: 10) {
                        StatTile(value: perDay.formatted(.number.precision(.fractionLength(1))), label: String(localized: "Done per day"))
                        StatTile(value: goalAverage.formatted(.percent.precision(.fractionLength(0))), label: String(localized: "Goal progress"))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
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
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(count == 0 ? Color.well : Color.ember.opacity(0.22 + 0.78 * level))
                .frame(width: 15, height: 15)
                .overlay {
                    if day.isSameDay(as: .now) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.night, lineWidth: 1.5)
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
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.hero(28, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(Color.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.allo(.footnote, .semibold))
                .foregroundStyle(Color.inkSecondary)
        }
        .surface(cornerRadius: 22, padding: 16)
        .accessibilityElement(children: .combine)
    }
}

/// Seven fat capsules, one per day, on the indigo card. Today is yellow.
private struct WeekBars: View {
    let values: [(Date, Int)]

    var body: some View {
        let peak = max(values.map(\.1).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                let day = item.0
                let count = item.1
                let isToday = day.isSameDay(as: .now)
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isToday ? StickerTone.yellow.fill : Color.canvas.opacity(count == 0 ? 0.18 : 0.88))
                        .frame(height: max(14, 92 * Double(count) / Double(peak)))
                        .frame(maxWidth: .infinity)
                    Text(Weekdays.letter(day.weekday))
                        .font(.allo(.caption, .heavy))
                        .opacity(isToday ? 1 : 0.55)
                }
            }
        }
        .frame(height: 116, alignment: .bottom)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: values.map(\.1))
        .accessibilityElement()
        .accessibilityLabel("This week")
        .accessibilityValue(values.map { "\($0.1)" }.joined(separator: ", "))
    }
}
