import SwiftUI
import SwiftData

/// Every task, wherever it falls. Today only shows today; this is where
/// everything else lives.
///
/// Up top, the week ahead on an indigo stage: one column per day, as tall as
/// that day is busy, with the owl perched on the day you're looking at. Tap
/// a column to see just that day. Below, quick filters, then the tasks in
/// groups: Overdue, Today, Tomorrow, the days ahead, Later and Someday.
struct TasksView: View {
    @Environment(AppRouter.self) private var router
    @Query private var open: [TaskItem]
    @Query private var recentlyDone: [TaskItem]

    @State private var focusDay: Date?
    @State private var filter: TaskFilter = .all
    @State private var showDone = false
    @State private var clearedCheers = 0

    init() {
        _open = Query(filter: #Predicate<TaskItem> { !$0.isDone }, sort: \TaskItem.createdAt, order: .reverse)
        var done = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.isDone },
                                             sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        done.fetchLimit = 60
        _recentlyDone = Query(done)
    }

    var body: some View {
        let today = Date.now.startOfDay
        let weekAgo = today.adding(days: -7)
        let doneThisWeek = recentlyDone.filter { ($0.completedAt ?? .distantPast) >= weekAgo }
        let filtered = open.filter(filter.matches)
        let groups = TaskGroup.build(filtered, focus: focusDay)
        let load = DayLoad(open)
        let overdue = open.filter(\.isOverdue)

        NavigationStack {
            List {
                ScreenTitle(title: String(localized: "Tasks"), subtitle: subtitle(overdue: overdue.count)) {
                    CircleAction(symbol: "plus", label: String(localized: "New task")) { router.sheet = .newTask(nil) }
                }
                .cardRow(top: 4, bottom: 14)

                if open.isEmpty {
                    AllClear(hadTasks: !doneThisWeek.isEmpty, cheers: clearedCheers) { router.sheet = .newTask(nil) }
                        .cardRow(top: 4)
                } else {
                    WeekAheadStage(load: load, openCount: open.count, overdue: overdue.count,
                                   doneThisWeek: doneThisWeek.count, selection: $focusDay)
                        .cardRow(bottom: 12)

                    FilterChips(selection: $filter, counts: TaskFilter.counts(in: open))
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    if groups.isEmpty {
                        NothingHere(isFiltered: filter != .all) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                focusDay = nil
                                filter = .all
                            }
                        }
                        .cardRow(top: 18)
                    }

                    ForEach(groups) { group in
                        GroupHeader(group: group) {
                            if group.kind == .overdue {
                                TaskActions.moveOverdueToToday(group.tasks, router: router)
                            }
                        }
                        .cardRow(top: 20, bottom: 10)

                        ForEach(group.tasks) { task in
                            row(task, overdue: group.kind == .overdue)
                        }
                    }
                }

                if focusDay == nil && filter == .all && !doneThisWeek.isEmpty {
                    doneSection(doneThisWeek)
                }

                Color.clear.frame(height: 80).cardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: focusDay)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: filter)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: open.count)
            .refreshable {
                // A small secret: pull down and the owl shares a fact.
                await MainActor.run { Haptics.owl() }
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run { router.show(Toast(message: OwlFacts.random())) }
            }
            .onChange(of: open.count) { old, new in
                // Inbox zero: the whole list, done.
                if old > 0, new == 0 {
                    clearedCheers += 1
                    Haptics.celebrate()
                }
            }
        }
    }

    private func subtitle(overdue: Int) -> String {
        if open.isEmpty { return String(localized: "All clear") }
        if overdue > 0 { return String(localized: "\(open.count) open · \(overdue) overdue") }
        return String(localized: "\(open.count) open")
    }

    private func row(_ task: TaskItem, overdue: Bool) -> some View {
        DayRow(entry: TimelineEntry(source: .task(task), section: overdue ? .overdue : .anytime, sortKey: 0)) {
            router.sheet = .task(task)
        }
        .cardRow(top: 4, bottom: 4)
        .taskSwipeActions(task)
        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .scale(scale: 0.92).combined(with: .opacity)))
    }

    @ViewBuilder
    private func doneSection(_ done: [TaskItem]) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDone.toggle() }
            Haptics.soft(0.4)
        } label: {
            HStack(spacing: 6) {
                SectionLabel(String(localized: "Done this week"), trailing: "\(done.count)")
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.inkTertiary)
                    .rotationEffect(.degrees(showDone ? 90 : 0))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .cardRow(top: 24, bottom: 10)
        if showDone {
            ForEach(done) { row($0, overdue: false) }
        }
    }
}

// MARK: - Filters

/// Quick ways to narrow the list.
enum TaskFilter: Hashable, CaseIterable {
    case all, urgent, timed, goals, repeating

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .urgent: String(localized: "Priority")
        case .timed: String(localized: "Timed")
        case .goals: String(localized: "For a goal")
        case .repeating: String(localized: "Repeating")
        }
    }

    var symbol: String {
        switch self {
        case .all: "tray.full.fill"
        case .urgent: "exclamationmark.2"
        case .timed: "clock.fill"
        case .goals: "flag.fill"
        case .repeating: "repeat"
        }
    }

    var tone: StickerTone {
        switch self {
        case .all: .indigo
        case .urgent: .pink
        case .timed: .yellow
        case .goals: .cyan
        case .repeating: .mint
        }
    }

    func matches(_ task: TaskItem) -> Bool {
        switch self {
        case .all: true
        case .urgent: task.priority != .low
        case .timed: task.hasTime
        case .goals: task.goal != nil
        case .repeating: task.repeatRule != .none
        }
    }

    static func counts(in tasks: [TaskItem]) -> [TaskFilter: Int] {
        var counts: [TaskFilter: Int] = [:]
        for task in tasks {
            for filter in allCases where filter.matches(task) { counts[filter, default: 0] += 1 }
        }
        return counts
    }
}

private struct FilterChips: View {
    @Binding var selection: TaskFilter
    let counts: [TaskFilter: Int]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    let on = selection == filter
                    let n = counts[filter] ?? 0
                    if filter == .all || n > 0 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selection = on && filter != .all ? .all : filter
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filter.symbol)
                                    .font(.system(size: 12, weight: .heavy))
                                    .symbolEffect(.bounce, value: on)
                                Text(filter.title)
                                    .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                                Text("\(n)")
                                    .font(.allo(size: 12, weight: .heavy).monospacedDigit())
                                    .opacity(0.6)
                                    .contentTransition(.numericText(value: Double(n)))
                            }
                            .foregroundStyle(on ? (filter.tone == .indigo ? Color.white : filter.tone.deep) : Color.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(on ? filter.tone.fill : Color.surface, in: .capsule)
                            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: on ? 0 : 1.5))
                        }
                        .buttonStyle(.pressable)
                        .accessibilityAddTraits(on ? .isSelected : [])
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .sovaFeedback(.selection, trigger: selection)
    }
}

// MARK: - The week ahead

/// How many open tasks fall on each of the next seven days. Built once per
/// render, so the stage doesn't refilter the list for every column.
struct DayLoad {
    let days: [Date]
    let counts: [Date: Int]
    var busiest: Int { max(3, counts.values.max() ?? 0) }

    init(_ tasks: [TaskItem]) {
        let today = Date.now.startOfDay
        let tomorrow = today.adding(days: 1)
        days = (0..<7).map { today.adding(days: $0) }
        var counts: [Date: Int] = [:]
        for task in tasks {
            guard let due = task.dueDate else { continue }
            // Overdue tasks weigh on today until they're done.
            let day = due < tomorrow ? today : due.startOfDay
            if day < today.adding(days: 7) { counts[day, default: 0] += 1 }
        }
        self.counts = counts
    }

    func count(_ day: Date) -> Int { counts[day] ?? 0 }
}

private struct WeekAheadStage: View {
    let load: DayLoad
    let openCount: Int
    let overdue: Int
    let doneThisWeek: Int
    @Binding var selection: Date?

    @State private var grown = false
    @State private var owlTaps = 0
    @State private var secret = 0
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var perch: Date { selection ?? load.days[0] }

    var body: some View {
        let tone = StickerTone.indigo
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    MonoCaps(String(localized: "The week ahead"), color: tone.deep)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(openCount)")
                            .font(.hero(44, weight: .heavy))
                            .tracking(-2)
                            .contentTransition(.numericText(value: Double(openCount)))
                        Text(String(localized: "to do"))
                            .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                            .opacity(0.7)
                    }
                    .foregroundStyle(Color.white)
                    if overdue > 0 {
                        TiltPill(text: String(localized: "\(overdue) overdue"), tone: .pink, tilt: -4, size: 13)
                            .padding(.top, 2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Spacer(minLength: 0)
                if doneThisWeek > 0 {
                    Starburst(value: "\(doneThisWeek)", caption: String(localized: "done this week"),
                              tone: .mint, size: 78, tilt: 10)
                        .padding(.top, -6)
                        .padding(.trailing, -6)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(alignment: .bottom, spacing: 7) {
                ForEach(Array(load.days.enumerated()), id: \.element) { index, day in
                    column(day, index: index)
                }
            }
        }
        .padding(20)
        .background {
            ZStack {
                tone.fill
                SparkleDot(color: StickerTone.yellow.fill, size: 13)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 170).padding(.top, 22)
                SparkleDot(color: StickerTone.pink.fill, size: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 110).padding(.top, 70)
            }
        }
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .overlay { SparkleBurst(trigger: secret, radius: CGSize(width: 160, height: 120), count: 16) }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.72).delay(0.05)) { grown = true }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: overdue)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: doneThisWeek)
    }

    private func column(_ day: Date, index: Int) -> some View {
        let n = load.count(day)
        let isToday = index == 0
        let on = selection == day
        let height: CGFloat = 86
        let fill = n == 0 ? 0 : max(0.2, Double(n) / Double(load.busiest))
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                selection = on ? nil : day
            }
            Sounds.play(.tick)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if day == perch {
                        OwlMark(size: 32, happy: overdue == 0 && n == 0 || owlTaps > 0,
                                bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                                pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8),
                                celebrate: secret, reactsToTap: false)
                            .matchedGeometryEffect(id: "owl", in: namespace)
                            .onTapGesture(perform: pokeOwl)
                            .transition(.identity)
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 32)

                ZStack(alignment: .bottom) {
                    Capsule().fill(Color.white.opacity(on ? 0.22 : 0.12))
                    Capsule()
                        .fill(on ? StickerTone.yellow.fill : (isToday ? StickerTone.yellow.fill.opacity(0.85) : StickerTone.lilac.fill))
                        .frame(height: grown ? max(fill > 0 ? 22 : 0, height * fill) : 0)
                        .overlay(alignment: .top) {
                            if n > 0 {
                                Text("\(n)")
                                    .font(.allo(size: 12, weight: .heavy).monospacedDigit())
                                    .foregroundStyle(StickerTone.indigo.fill)
                                    .padding(.top, 4)
                                    .contentTransition(.numericText(value: Double(n)))
                            }
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(Double(index) * 0.035), value: grown)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: n)
                }
                .frame(height: height)
                .overlay {
                    if on { Capsule().strokeBorder(StickerTone.yellow.fill, lineWidth: 2.5) }
                }
                .scaleEffect(on ? 1.06 : 1, anchor: .bottom)

                Text(isToday ? String(localized: "Today") : day.formatted(.dateTime.weekday(.narrow)))
                    .font(.allo(size: isToday ? 10 : 12, weight: .heavy, relativeTo: .caption2))
                    .foregroundStyle(on || isToday ? StickerTone.yellow.fill : Color.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(String(localized: "\(n) tasks"))
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityHint(on ? String(localized: "Shows every day") : String(localized: "Shows only this day"))
    }

    @Namespace private var namespace

    /// Another small secret: poke the owl five times.
    private func pokeOwl() {
        owlTaps += 1
        Haptics.owl()
        if owlTaps == 5 {
            owlTaps = 0
            secret += 1
            Haptics.celebrate()
            router.show(Toast(message: String(localized: "Hoo! You found the owl's hiding spot. 🦉")))
        }
    }
}

// MARK: - Groups

/// A run of tasks under one heading.
struct TaskGroup: Identifiable {
    enum Kind: Hashable {
        case overdue, today, tomorrow, day(Date), later, someday
    }

    let kind: Kind
    let tasks: [TaskItem]
    var id: Kind { kind }

    var title: String {
        switch kind {
        case .overdue: String(localized: "Overdue")
        case .today: String(localized: "Today")
        case .tomorrow: String(localized: "Tomorrow")
        case .day(let date): date.formatted(.dateTime.weekday(.wide))
        case .later: String(localized: "Later")
        case .someday: String(localized: "Someday")
        }
    }

    var caption: String? {
        switch kind {
        case .day(let date): date.formatted(.dateTime.month(.abbreviated).day())
        case .tomorrow: Date.now.adding(days: 1).formatted(.dateTime.weekday(.abbreviated).day())
        case .later: String(localized: "After this week")
        case .someday: String(localized: "No date")
        default: nil
        }
    }

    var symbol: String {
        switch kind {
        case .overdue: "exclamationmark.circle.fill"
        case .today: "sun.max.fill"
        case .tomorrow: "sunrise.fill"
        case .day: "calendar"
        case .later: "calendar.badge.clock"
        case .someday: "tray.fill"
        }
    }

    var tone: StickerTone {
        switch kind {
        case .overdue: .pink
        case .today: .yellow
        case .tomorrow: .orange
        case .day: .lilac
        case .later: .cyan
        case .someday: .mint
        }
    }

    /// Open tasks grouped by when they're due. With `focus`, only that day.
    static func build(_ tasks: [TaskItem], focus: Date?) -> [TaskGroup] {
        let today = Date.now.startOfDay
        let tomorrow = today.adding(days: 1)
        let weekOut = today.adding(days: 7)
        let order: (TaskItem, TaskItem) -> Bool = { a, b in
            let ad = a.dueDate ?? .distantFuture, bd = b.dueDate ?? .distantFuture
            if a.priorityRaw != b.priorityRaw, ad.isSameDay(as: bd) { return a.priorityRaw > b.priorityRaw }
            if ad != bd { return ad < bd }
            return a.createdAt > b.createdAt
        }

        var buckets: [Kind: [TaskItem]] = [:]
        var dayKinds = Set<Date>()
        for task in tasks {
            let kind: Kind
            if let due = task.dueDate {
                let day = due.startOfDay
                if day < today && task.isOverdue { kind = .overdue }
                else if day < tomorrow { kind = .today }
                else if day == tomorrow { kind = .tomorrow }
                else if day < weekOut { kind = .day(day); dayKinds.insert(day) }
                else { kind = .later }
            } else {
                kind = .someday
            }
            buckets[kind, default: []].append(task)
        }

        var kinds: [Kind] = [.overdue, .today, .tomorrow] + dayKinds.sorted().map { .day($0) } + [.later, .someday]
        if let focus {
            let day = focus.startOfDay
            // Overdue work belongs to today until it's done.
            kinds = day == today ? [.overdue, .today] : day == tomorrow ? [.tomorrow] : [.day(day)]
        }
        return kinds.compactMap { kind in
            guard let items = buckets[kind], !items.isEmpty else { return nil }
            return TaskGroup(kind: kind, tasks: items.sorted(by: order))
        }
    }
}

/// A group's heading: a tilted sticker icon, the name, the date, a count,
/// and for overdue work, one tap to bring it all to today.
private struct GroupHeader: View {
    let group: TaskGroup
    let onAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: group.symbol)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(group.tone.deep)
                .frame(width: 28, height: 28)
                .background(group.tone.fill, in: .rect(cornerRadius: 9, style: .continuous))
                .rotationEffect(.degrees(-6))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(group.title)
                    .font(.allo(size: 21, weight: .heavy, relativeTo: .title3))
                    .tracking(-0.6)
                    .foregroundStyle(group.kind == .overdue ? Color.ember : Color.ink)
                if let caption = group.caption {
                    MonoCaps(caption)
                }
            }
            Spacer(minLength: 6)
            if group.kind == .overdue {
                Button(action: onAction) {
                    Label(String(localized: "All to today"), systemImage: "arrow.uturn.forward")
                        .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                        .foregroundStyle(StickerTone.pink.deep)
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .background(StickerTone.pink.fill, in: .capsule)
                }
                .buttonStyle(.pressable)
            } else {
                Text("\(group.tasks.count)")
                    .font(.allo(size: 13, weight: .heavy).monospacedDigit())
                    .foregroundStyle(group.tone.deep)
                    .padding(.horizontal, 9)
                    .frame(minWidth: 26, minHeight: 24)
                    .background(group.tone.fill.opacity(0.55), in: .capsule)
                    .contentTransition(.numericText(value: Double(group.tasks.count)))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Empty states

/// Nothing left to do: the owl celebrates (with sparkles, the first time it
/// happens) and offers to add the next thing.
private struct AllClear: View {
    let hadTasks: Bool
    let cheers: Int
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(StickerTone.mint.fill).frame(width: 128, height: 128)
                OwlMark(size: 84, happy: true, celebrate: cheers)
                SparkleBurst(trigger: cheers, radius: CGSize(width: 130, height: 110), count: 14)
            }
            .padding(.top, 8)
            Text(hadTasks ? String(localized: "All clear!") : String(localized: "No tasks yet"))
                .font(.hero(34, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(Color.ink)
            Text(hadTasks ? String(localized: "Every task is done. The owl is very proud of you.")
                          : String(localized: "Add one for today, tomorrow or someday. They'll all live here."))
                .font(.allo(.body, .semibold))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button(String(localized: "New task"), action: onAdd)
                .buttonStyle(.inkCompact)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(Color.surface, in: .rect(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
    }
}

private struct NothingHere: View {
    let isFiltered: Bool
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            OwlMark(size: 60, happy: true, reactsToTap: false)
            Text(isFiltered ? String(localized: "Nothing matches") : String(localized: "A free day"))
                .font(.allo(size: 19, weight: .heavy, relativeTo: .headline))
                .foregroundStyle(Color.ink)
            Text(isFiltered ? String(localized: "Try another filter.") : String(localized: "Nothing planned for this day yet."))
                .font(.allo(.subheadline, .semibold))
                .foregroundStyle(Color.inkSecondary)
            Button(String(localized: "Show everything"), action: onReset)
                .buttonStyle(.inkCompact)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

/// True owl facts, for anyone who pulls to refresh.
enum OwlFacts {
    static let all = [
        String(localized: "🦉 Owl fact: owls can turn their heads about 270 degrees."),
        String(localized: "🦉 Owl fact: a group of owls is called a parliament."),
        String(localized: "🦉 Owl fact: owls can't move their eyes, so they turn their heads instead."),
        String(localized: "🦉 Owl fact: soft feather edges let most owls fly almost silently."),
        String(localized: "🦉 Owl fact: some owls' ears sit at different heights, to pinpoint sounds."),
        String(localized: "🦉 Owl fact: baby owls are called owlets."),
    ]

    static func random() -> String { all.randomElement() ?? all[0] }
}

#Preview {
    TasksView()
        .environment(AppRouter())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
