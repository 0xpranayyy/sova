import SwiftUI
import SwiftData

/// How you've been doing: rituals kept on an indigo stage, the numbers as
/// tilted stickers, your power day and best time of day, the most
/// consistent rituals, a heatmap you can tap, and badges to collect.
///
/// Everything is read from one index built per render, so the screen scans
/// your history once instead of once per heatmap square.
struct InsightsView: View {
    @Environment(AppRouter.self) private var router
    @Query private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query private var goals: [Goal]

    @State private var range: InsightRange = .month
    @State private var picked: Date?
    @State private var owlTaps = 0
    @State private var secret = 0
    @AppStorage("weeklyReviewHidden") private var reviewHiddenWeek = 0

    static let weeks = 17
    static let mintInk = Color.positive
    static let mintWash = Color(light: 0xC9FAE6, dark: 0x10332B)

    var body: some View {
        let index = ActivityIndex(tasks: tasks, routines: routines, days: max(Self.weeks * 7, 180))
        let current = consistency(days: range.days)
        let previous = consistency(days: range.days, endingDaysAgo: range.days)
        let delta = Int(((current - previous) * 100).rounded())
        let canCompare = routines.contains { $0.createdAt < Date.now.adding(days: -range.days) }
        let hasHistory = !routines.isEmpty || index.tasksDone > 0
        let badges = Badge.all(index: index, routines: routines, goals: goals, weekKept: consistency(days: 7))

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenTitle(title: String(localized: "Insights"), subtitle: range.subtitle) { EmptyView() }
                        .padding(.top, 4)

                    if WeeklyReview.isReviewTime, reviewHiddenWeek != WeeklyReview.weekKey {
                        let review = WeeklyReview(tasks: tasks, routines: routines, goals: goals.filter { !$0.isArchived })
                        if review.hasAnything {
                            WeeklyReviewCard(review: review) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    reviewHiddenWeek = WeeklyReview.weekKey
                                }
                            }
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                        }
                    }

                    RangePicker(selection: $range)

                    KeptHero(current: current, delta: delta, canCompare: canCompare, hasHistory: hasHistory,
                             rangeName: range.short, owlHappy: current >= 0.5 || owlTaps > 0, secret: secret,
                             onOwl: pokeOwl)

                    HStack(spacing: 8) {
                        StatSticker(label: String(localized: "Tasks"), value: "\(index.tasks(inLast: range.days))", tone: .pink)
                        StatSticker(label: String(localized: "Streak"), value: "\(routines.map(\.streak).max() ?? 0)d", tone: .orange)
                        StatSticker(label: String(localized: "Goals"), value: "\(Int((goalAverage * 100).rounded()))%", tone: .lime)
                    }

                    WeekColumns(values: index.lastSeven)

                    if hasHistory {
                        FlowLayout(spacing: 8) {
                            if let day = index.powerWeekday {
                                FactChip(text: "⚡ " + String(localized: "Power day · \(Calendar.current.shortWeekdaySymbols[day - 1])"))
                            }
                            if let period = index.bestPeriod {
                                FactChip(text: "🌅 " + String(localized: "Best time · \(period.name)"))
                            }
                        }
                    }

                    if !routines.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            MonoCaps(String(localized: "Most consistent · \(range.short)"))
                            let ranked = routines.map { ($0, $0.consistency(days: range.days)) }
                                .sorted { $0.1 > $1.1 }
                                .prefix(5)
                            ForEach(Array(ranked.enumerated()), id: \.offset) { place, item in
                                ConsistencyRow(routine: item.0, value: item.1, place: place)
                            }
                        }
                        .surface(cornerRadius: 30, padding: 18)
                    }

                    heatmap(index)

                    BadgeShelf(badges: badges) { badge in
                        Haptics.pop(0.5, sound: badge.earned)
                        router.show(Toast(message: badge.earned ? "\(badge.emoji) \(badge.title): \(badge.howTo)"
                                                                : String(localized: "🔒 \(badge.title): \(badge.howTo)")))
                    }
                }
                .readableColumn()
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: range)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .refreshable {
                // Pull down and the owl reads you a fun stat.
                await MainActor.run { Haptics.owl() }
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run { router.show(Toast(message: funLine(index))) }
            }
        }
    }

    // MARK: Numbers

    private var goalAverage: Double {
        let live = goals.filter { !$0.isArchived }
        return live.isEmpty ? 0 : live.map(\.progress).reduce(0, +) / Double(live.count)
    }

    /// The share of scheduled ritual days that got done.
    private func consistency(days: Int, endingDaysAgo offset: Int = 0) -> Double {
        let today = Date.now.startOfDay
        var scheduled = 0, done = 0
        for routine in routines {
            let start = routine.createdAt.startOfDay
            for i in offset..<(offset + days) {
                let day = today.adding(days: -i)
                guard day >= start, routine.isScheduled(on: day) else { continue }
                scheduled += 1
                if routine.isDone(on: day) { done += 1 }
            }
        }
        return scheduled == 0 ? 0 : Double(done) / Double(scheduled)
    }

    private func funLine(_ index: ActivityIndex) -> String {
        let total = index.tasksDone + index.checkIns
        let options = [
            String(localized: "🦉 You've finished \(index.tasksDone) tasks and kept \(index.checkIns) rituals here. Hoo!"),
            total > 0 ? String(localized: "🦉 That's \(total) little wins. The owl counted every one.")
                      : String(localized: "🦉 Every big streak starts with one tick."),
            String(localized: "🦉 Your busiest day had \(index.peak) things done."),
        ]
        return options.randomElement() ?? options[0]
    }

    // MARK: Stage

    private func stage(current: Double, delta: Int, canCompare: Bool, hasHistory: Bool, index: ActivityIndex) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                MonoCaps(hasHistory ? String(localized: "Rituals kept · \(range.short)") : String(localized: "No history yet"),
                         color: StickerTone.indigo.deep)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Int((current * 100).rounded()), format: .number)
                        .font(.hero(86, weight: .heavy))
                        .tracking(-4)
                        .contentTransition(.numericText(value: current))
                    Text("%").font(.hero(38, weight: .heavy)).opacity(0.6)
                }
                .foregroundStyle(StickerTone.indigo.deep)
                .padding(.top, 4)
                WeekBars(values: index.lastSeven)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 0) {
                if hasHistory, canCompare {
                    TiltPill(text: delta >= 0 ? "↑ \(delta)%" : "↓ \(-delta)%",
                             tone: delta >= 0 ? .mint : .pink, tilt: -8, size: 14)
                        .padding(.top, 50)
                        .padding(.trailing, -2)
                        .zIndex(1)
                        .transition(.scale.combined(with: .opacity))
                }
                OwlMark(size: 62, happy: current >= 0.5 || owlTaps > 0, bodyColor: StickerTone.yellow.fill,
                        eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, celebrate: secret, reactsToTap: false)
                    .rotationEffect(.degrees(8))
                    .onTapGesture(perform: pokeOwl)
                    .overlay { SparkleBurst(trigger: secret, radius: CGSize(width: 110, height: 90), count: 14) }
            }
        }
        .padding(20)
        .background(StickerTone.indigo.fill.shadow(.drop(color: StickerTone.indigo.shadow, radius: 18, y: 10)),
                    in: .rect(cornerRadius: Radius.hero, style: .continuous))
        .overlay(alignment: .topLeading) {
            SparkleDot(color: StickerTone.pink.fill, size: 14)
                .padding(.leading, 236)
                .padding(.top, 22)
                .allowsHitTesting(false)
        }
    }

    /// A small secret: poke the owl five times.
    private func pokeOwl() {
        owlTaps += 1
        Haptics.owl()
        if owlTaps == 5 {
            owlTaps = 0
            secret += 1
            Haptics.celebrate()
            router.show(Toast(message: String(localized: "Hoo! The owl's own stats: 100% naps kept. 🦉")))
        }
    }

    // MARK: Heatmap

    /// Columns of seven days (one per week), oldest first, ending this week.
    private var grid: [[Date?]] {
        let today = Date.now.startOfDay
        let weekStart = Calendar.sova.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<Self.weeks).map { column in
            let start = weekStart.adding(days: (column - (Self.weeks - 1)) * 7)
            return (0..<7).map { row in
                let day = start.adding(days: row)
                return day > today ? nil : day
            }
        }
    }

    private func heatmap(_ index: ActivityIndex) -> some View {
        let columns = grid
        let peak = max(index.peak, 1)
        let caption: String = {
            guard let picked else { return String(localized: "Tap a square to see that day") }
            let n = index.count(picked)
            return picked.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) + " · "
                + (n == 1 ? String(localized: "1 thing done") : String(localized: "\(n) things done"))
        }()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                MonoCaps(String(localized: "Every day, \(Self.weeks) weeks"), color: Self.mintInk)
                Spacer()
                HStack(spacing: 3) {
                    Text(String(localized: "Less")).font(.allo(.caption2, .bold))
                    ForEach([0.0, 0.3, 0.6, 1.0], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(level == 0 ? Color.well : Self.greenScale(level))
                            .frame(width: 10, height: 10)
                    }
                    Text(String(localized: "More")).font(.allo(.caption2, .bold))
                }
                .foregroundStyle(Self.mintInk.opacity(0.7))
            }

            Text(caption)
                .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                .foregroundStyle(picked == nil ? Self.mintInk.opacity(0.6) : Self.mintInk)
                .contentTransition(.opacity)
                .animation(.smooth(duration: 0.2), value: picked)

            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { row in
                                    cell(week[row], index: index, peak: peak)
                                }
                            }
                        }
                    }
                    HStack(spacing: 4) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { position, week in
                            let first = week.compactMap { $0 }.first
                            let showsMonth = first.map { day in
                                position == 0 || Calendar.current.component(.month, from: day)
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
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.trailing)
            .sovaFeedback(.selection, trigger: picked)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.mintWash, in: .rect(cornerRadius: 30, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Activity over the last \(Self.weeks) weeks"))
        .accessibilityValue(caption)
    }

    static func greenScale(_ level: Double) -> Color {
        switch level {
        case ..<0.3: Color(hex: 0xB8F7DC)
        case ..<0.55: Color(hex: 0x7EF0C2)
        case ..<0.8: Color(hex: 0x4DF2B0)
        default: Color(hex: 0x12C985)
        }
    }

    @ViewBuilder
    private func cell(_ day: Date?, index: ActivityIndex, peak: Int) -> some View {
        if let day {
            let count = index.count(day)
            let level = count == 0 ? 0 : Double(count) / Double(peak)
            let on = picked == day
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(count == 0 ? Color.well : Self.greenScale(level))
                .frame(width: 15, height: 15)
                .overlay {
                    if day.isSameDay(as: .now) || on {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(on ? Color.ink : InsightsView.mintInk, lineWidth: on ? 2 : 1.5)
                    }
                }
                .scaleEffect(on ? 1.25 : 1)
                .zIndex(on ? 1 : 0)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { picked = on ? nil : day }
                }
        } else {
            Color.clear.frame(width: 15, height: 15)
        }
    }
}

// MARK: - The index

/// Everything finished, by day, built in one pass over your history.
struct ActivityIndex {
    private(set) var byDay: [Date: Int] = [:]
    private(set) var tasksByDay: [Date: Int] = [:]
    private(set) var tasksDone = 0
    private(set) var checkIns = 0
    private(set) var nightOwl = false
    private(set) var earlyBird = false
    private var weekdayTotals = [Int](repeating: 0, count: 8)
    private var periodTotals: [DayPeriod: Int] = [:]

    init(tasks: [TaskItem], routines: [Routine], days: Int) {
        let since = Date.now.startOfDay.adding(days: -days)
        let cal = Calendar.current
        for task in tasks where task.isDone {
            tasksDone += 1
            guard let done = task.completedAt else { continue }
            let hour = cal.component(.hour, from: done)
            if hour >= 23 || hour < 4 { nightOwl = true }
            if (4..<7).contains(hour) { earlyBird = true }
            guard done >= since else { continue }
            let day = done.startOfDay
            byDay[day, default: 0] += 1
            tasksByDay[day, default: 0] += 1
            weekdayTotals[day.weekday] += 1
            periodTotals[hour < 12 ? .morning : hour < 17 ? .afternoon : .evening, default: 0] += 1
        }
        for routine in routines {
            for completion in routine.completions {
                checkIns += 1
                guard completion >= since else { continue }
                let day = completion.startOfDay
                byDay[day, default: 0] += 1
                weekdayTotals[day.weekday] += 1
            }
        }
    }

    func count(_ day: Date) -> Int { byDay[day.startOfDay] ?? 0 }
    var peak: Int { byDay.values.max() ?? 0 }

    func tasks(inLast days: Int) -> Int {
        let since = Date.now.startOfDay.adding(days: -(days - 1))
        return tasksByDay.filter { $0.key >= since }.values.reduce(0, +)
    }

    func perDay(inLast days: Int) -> Double {
        let since = Date.now.startOfDay.adding(days: -(days - 1))
        return Double(byDay.filter { $0.key >= since }.values.reduce(0, +)) / Double(days)
    }

    var lastSeven: [(Date, Int)] {
        let today = Date.now.startOfDay
        return (0..<7).map { offset in
            let day = today.adding(days: offset - 6)
            return (day, count(day))
        }
    }

    /// The weekday (1 = Sunday) with the most done, once there's enough to say.
    var powerWeekday: Int? {
        guard weekdayTotals.reduce(0, +) >= 5, let top = weekdayTotals.max(), top > 0 else { return nil }
        return weekdayTotals.firstIndex(of: top)
    }

    /// The part of the day you finish most tasks in.
    var bestPeriod: DayPeriod? {
        guard periodTotals.values.reduce(0, +) >= 3 else { return nil }
        return periodTotals.max { $0.value < $1.value }?.key
    }
}

// MARK: - Range

enum InsightRange: Hashable, CaseIterable {
    case week, month, quarter

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        }
    }

    var short: String {
        switch self {
        case .week: String(localized: "7 days")
        case .month: String(localized: "30 days")
        case .quarter: String(localized: "90 days")
        }
    }

    var subtitle: String {
        switch self {
        case .week: String(localized: "Last 7 days")
        case .month: String(localized: "Last 30 days")
        case .quarter: String(localized: "Last 90 days")
        }
    }
}

/// Week, month or quarter, as three sticker buttons that slide.
private struct RangePicker: View {
    @Binding var selection: InsightRange
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(InsightRange.allCases, id: \.self) { range in
                let on = selection == range
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { selection = range }
                } label: {
                    Text(range.short)
                        .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                        .foregroundStyle(on ? StickerTone.indigo.deep : Color.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background {
                            if on {
                                Capsule().fill(StickerTone.indigo.fill)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.surface, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1.5))
        .sovaFeedback(.selection, trigger: selection)
    }
}

// MARK: - Pieces

/// The headline numbers side by side on one calm card, each in its own
/// color, divided by fine lines.
private struct StatStrip: View {
    struct Item: Identifiable {
        let value: String
        let unit: String?
        let label: String
        let color: Color
        var id: String { label }
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { position, item in
                if position > 0 {
                    Rectangle().fill(Color.hairline).frame(width: 1.5).padding(.vertical, 6)
                }
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(item.value)
                            .font(.hero(30, weight: .heavy))
                            .tracking(-1.2)
                            .contentTransition(.numericText())
                        if let unit = item.unit {
                            Text(unit).font(.hero(15, weight: .heavy)).opacity(0.6)
                        }
                    }
                    .foregroundStyle(item.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    MonoCaps(item.label, size: 10)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .cardBackground()
    }
}

/// One fun fact about how you work, on a white card with a sticker icon.
private struct FunFact: View {
    let symbol: String
    let tone: StickerTone
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tone.deep)
                .frame(width: 36, height: 36)
                .background(tone.fill, in: .rect(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-6))
            MonoCaps(title)
            Text(value)
                .font(.allo(size: 22, weight: .heavy, relativeTo: .title3))
                .tracking(-0.6)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.allo(.footnote, .semibold))
                .foregroundStyle(Color.inkSecondary)
                .lineLimit(2)
        }
        .surface(cornerRadius: 26, padding: 16)
        .accessibilityElement(children: .combine)
    }
}

/// Seven fat capsules, one per day, on the indigo card. Today is yellow.
/// They grow in when the screen appears.
private struct WeekBars: View {
    let values: [(Date, Int)]
    @State private var grown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let peak = max(values.map(\.1).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { position, item in
                let day = item.0
                let count = item.1
                let isToday = day.isSameDay(as: .now)
                VStack(spacing: 6) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2).monospacedDigit())
                            .foregroundStyle(isToday ? StickerTone.yellow.fill : Color.white.opacity(0.7))
                            .opacity(grown ? 1 : 0)
                    }
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isToday ? StickerTone.yellow.fill : Color.white.opacity(count == 0 ? 0.18 : 0.9))
                        .frame(height: grown ? max(14, 80 * Double(count) / Double(peak)) : 14)
                        .frame(maxWidth: .infinity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(Double(position) * 0.04), value: grown)
                    Text(Weekdays.letter(day.weekday))
                        .font(.allo(size: 10.5, weight: .heavy, relativeTo: .caption2))
                        .opacity(isToday ? 1 : 0.55)
                }
            }
        }
        .frame(height: 124, alignment: .bottom)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: values.map(\.1))
        .onAppear {
            if reduceMotion { grown = true } else { withAnimation { grown = true } }
        }
        .accessibilityElement()
        .accessibilityLabel("This week")
        .accessibilityValue(values.map { "\($0.1)" }.joined(separator: ", "))
    }
}

/// A ritual's consistency as a bar in its own color, with a medal for the
/// top three.
private struct ConsistencyRow: View {
    let routine: Routine
    let value: Double
    let place: Int

    var body: some View {
        let tone = StickerTone(routine.accent)
        HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: routine.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                    .frame(width: 34, height: 34)
                    .background(tone.fill, in: .rect(cornerRadius: 11, style: .continuous))
                if place < 3 && value > 0 {
                    Text(["🥇", "🥈", "🥉"][place])
                        .font(.system(size: 14))
                        .offset(x: 6, y: 6)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(routine.title).lineLimit(1)
                    Spacer()
                    Text(value, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: value))
                }
                .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                .foregroundStyle(Color.ink)
                ProgressLine(progress: value, color: tone.fill, height: 10, track: tone.fill.opacity(0.3))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Badges

/// Little achievements to collect. Locked ones show how to earn them.
struct Badge: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let howTo: String
    let tone: StickerTone
    let earned: Bool

    static func all(index: ActivityIndex, routines: [Routine], goals: [Goal], weekKept: Double) -> [Badge] {
        let streak = routines.map(\.streak).max() ?? 0
        return [
            Badge(id: "first", emoji: "✅", title: String(localized: "First tick"),
                  howTo: String(localized: "Finish your first task."), tone: .mint, earned: index.tasksDone >= 1),
            Badge(id: "ten", emoji: "🔟", title: String(localized: "Ten down"),
                  howTo: String(localized: "Finish 10 tasks."), tone: .yellow, earned: index.tasksDone >= 10),
            Badge(id: "hundred", emoji: "💯", title: String(localized: "Centurion"),
                  howTo: String(localized: "Finish 100 tasks."), tone: .pink, earned: index.tasksDone >= 100),
            Badge(id: "week", emoji: "🔥", title: String(localized: "On fire"),
                  howTo: String(localized: "Keep a 7-day streak."), tone: .orange, earned: streak >= 7),
            Badge(id: "month", emoji: "🌙", title: String(localized: "Moon cycle"),
                  howTo: String(localized: "Keep a 30-day streak."), tone: .lilac, earned: streak >= 30),
            Badge(id: "perfect", emoji: "✨", title: String(localized: "Perfect week"),
                  howTo: String(localized: "Keep every ritual for 7 days."), tone: .cyan,
                  earned: !routines.isEmpty && weekKept >= 1),
            Badge(id: "goal", emoji: "🏆", title: String(localized: "Goal getter"),
                  howTo: String(localized: "Reach 100% on a goal."), tone: .lime, earned: goals.contains { $0.progress >= 1 }),
            Badge(id: "night", emoji: "🦉", title: String(localized: "Night owl"),
                  howTo: String(localized: "Finish a task after 11 PM."), tone: .indigo, earned: index.nightOwl),
            Badge(id: "early", emoji: "🌅", title: String(localized: "Early bird"),
                  howTo: String(localized: "Finish a task before 7 AM."), tone: .orange, earned: index.earlyBird),
        ]
    }
}

private struct BadgeShelf: View {
    let badges: [Badge]
    let onTap: (Badge) -> Void

    var body: some View {
        let earned = badges.filter(\.earned).count
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MonoCaps(String(localized: "Badges"))
                Spacer()
                Text("\(earned) / \(badges.count)")
                    .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote).monospacedDigit())
                    .foregroundStyle(Color.inkSecondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 14) {
                ForEach(Array(badges.enumerated()), id: \.element.id) { position, badge in
                    Button { onTap(badge) } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                StarburstShape(points: 14)
                                    .fill(badge.earned ? badge.tone.fill : Color.well)
                                    .frame(width: 66, height: 66)
                                Text(badge.earned ? badge.emoji : "?")
                                    .font(badge.earned ? .system(size: 28) : .allo(size: 24, weight: .heavy))
                                    .foregroundStyle(Color.inkTertiary)
                            }
                            .rotationEffect(.degrees(badge.earned ? Double([-8, 6, -4][position % 3]) : 0))
                            .saturation(badge.earned ? 1 : 0)
                            Text(badge.title)
                                .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
                                .foregroundStyle(badge.earned ? Color.ink : Color.inkTertiary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(badge.title)
                    .accessibilityValue(badge.earned ? String(localized: "Earned") : String(localized: "Locked. \(badge.howTo)"))
                }
            }
        }
        .surface(cornerRadius: 30, padding: 18)
    }
}

// MARK: - The week, in the onboarding style

/// "You kept 82% of your rituals." with the highlighter on the number and
/// a proud owl beside it.
private struct KeptHero: View {
    let current: Double
    let delta: Int
    let canCompare: Bool
    let hasHistory: Bool
    let rangeName: String
    let owlHappy: Bool
    let secret: Int
    let onOwl: () -> Void

    private var line: String {
        guard hasHistory else { return String(localized: "Your story\n*starts today*.") }
        let percent: Int = Int((current * 100).rounded())
        return String(localized: "You kept\n*\(percent)%* of your\nrituals.")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 10) {
                Text.marked(line)
                    .font(.hero(40, weight: .heavy))
                    .tracking(-1.8)
                    .foregroundStyle(Color.ink)
                    .textRenderer(MarkerRenderer(color: StickerTone.yellow.fill))
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText(value: current))
                if hasHistory {
                    Text(canCompare ? (delta >= 0 ? String(localized: "↑ \(delta)% vs the \(rangeName) before")
                                                  : String(localized: "↓ \(-delta)% vs the \(rangeName) before"))
                                    : String(localized: "Over the last \(rangeName)"))
                        .font(.allo(size: 14, weight: .heavy, relativeTo: .footnote))
                        .foregroundStyle(canCompare ? (delta >= 0 ? Color.positive : Color.alertInk) : Color.inkSecondary)
                }
            }
            Spacer(minLength: 0)
            OwlMark(size: 76, happy: owlHappy, bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                    pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly, celebrate: secret, reactsToTap: false)
                .rotationEffect(.degrees(8))
                .onTapGesture(perform: onOwl)
                .overlay { SparkleBurst(trigger: secret, radius: CGSize(width: 110, height: 90), count: 14) }
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

/// One number as a flat sticker in its color.
private struct StatSticker: View {
    let label: String
    let value: String
    let tone: StickerTone

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MonoCaps(label, color: tone.deep.opacity(0.75), size: 10)
            Text(value)
                .font(.hero(30, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(tone.deep)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.fill, in: .rect(cornerRadius: Radius.tile, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The last seven days as fat indigo columns; today is yellow.
private struct WeekColumns: View {
    let values: [(Date, Int)]
    @State private var grown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let peak: Int = max(values.map(\.1).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 12) {
            MonoCaps(String(localized: "Last 7 days"), color: Color.ink.opacity(0.55))
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                    column(day: item.0, count: item.1, peak: peak, isToday: index == values.count - 1)
                }
            }
            .frame(height: 130)
        }
        .padding(18)
        .cardBackground()
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.75).delay(0.15)) { grown = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Last 7 days"))
    }

    private func column(day: Date, count: Int, peak: Int, isToday: Bool) -> some View {
        let share: CGFloat = CGFloat(count) / CGFloat(peak)
        return VStack(spacing: 6) {
            GeometryReader { geo in
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isToday ? StickerTone.yellow.fill : StickerTone.indigo.fill)
                        .frame(height: max(8, geo.size.height * (grown ? share : 0.06)))
                }
            }
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2))
                .foregroundStyle(isToday ? Color.ink : Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A fun fact as a white chip.
private struct FactChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1.5))
    }
}

