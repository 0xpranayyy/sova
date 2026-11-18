import SwiftUI
import SwiftData

/// Every task, wherever it falls: overdue, today, tomorrow, the days after,
/// later on and someday. Today only shows today; this is where everything
/// else lives. A strip of the next seven days narrows the list to one day.
struct TasksView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]

    @State private var focusDay: Date?
    @State private var showDone = false

    private var open: [TaskItem] { tasks.filter { !$0.isDone } }

    /// Recently finished, newest first.
    private var done: [TaskItem] {
        let weekAgo = Date.now.startOfDay.adding(days: -7)
        return tasks.filter { $0.isDone && ($0.completedAt ?? .distantPast) >= weekAgo }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var groups: [TaskGroup] {
        TaskGroup.build(open, focus: focusDay)
    }

    var body: some View {
        NavigationStack {
            List {
                ScreenTitle(title: String(localized: "Tasks"), subtitle: subtitle) {
                    CircleAction(symbol: "plus", label: String(localized: "New task")) { router.sheet = .newTask(nil) }
                }
                .cardRow(top: 4, bottom: 14)

                if tasks.isEmpty {
                    EmptyState(title: String(localized: "No tasks yet"),
                               message: String(localized: "Add one for today, tomorrow or someday. They'll all be here."),
                               actionTitle: String(localized: "New task")) { router.sheet = .newTask(nil) }
                        .cardRow(top: 4)
                } else {
                    WeekStrip(tasks: open, selection: $focusDay)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    if groups.isEmpty {
                        nothingHere.cardRow(top: 18)
                    }

                    ForEach(groups) { group in
                        GroupHeader(group: group)
                            .cardRow(top: 18, bottom: 10)
                        ForEach(group.tasks) { task in
                            DayRow(entry: TimelineEntry(source: .task(task),
                                                        section: task.isOverdue ? .overdue : .anytime,
                                                        sortKey: 0)) {
                                router.sheet = .task(task)
                            }
                            .cardRow(top: 4, bottom: 4)
                            .taskSwipeActions(task)
                        }
                    }

                    if focusDay == nil && !done.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDone.toggle() }
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
                        .cardRow(top: 22, bottom: 10)
                        if showDone {
                            ForEach(done) { task in
                                DayRow(entry: TimelineEntry(source: .task(task), section: .anytime, sortKey: 0)) {
                                    router.sheet = .task(task)
                                }
                                .cardRow(top: 4, bottom: 4)
                                .taskSwipeActions(task)
                            }
                        }
                    }
                }

                Color.clear.frame(height: 80).cardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: focusDay)
        }
    }

    private var subtitle: String {
        let overdue = open.filter(\.isOverdue).count
        if overdue > 0 { return String(localized: "\(open.count) open · \(overdue) overdue") }
        return open.isEmpty ? String(localized: "All clear") : String(localized: "\(open.count) open")
    }

    private var nothingHere: some View {
        VStack(spacing: 10) {
            OwlMark(size: 64, happy: true, reactsToTap: false)
            Text(String(localized: "Nothing on this day"))
                .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                .foregroundStyle(Color.ink)
            Button(String(localized: "Show everything")) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { focusDay = nil }
            }
            .buttonStyle(.inkCompact)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

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
        let order: (TaskItem, TaskItem) -> Bool = { a, b in
            let ad = a.dueDate ?? .distantFuture, bd = b.dueDate ?? .distantFuture
            if a.hasTime != b.hasTime, ad.isSameDay(as: bd) { return a.hasTime }
            if ad != bd { return ad < bd }
            if a.priorityRaw != b.priorityRaw { return a.priorityRaw > b.priorityRaw }
            return a.createdAt > b.createdAt
        }

        if let focus {
            let day = focus.startOfDay
            let items = tasks.filter { task in
                guard let due = task.dueDate else { return false }
                // Overdue tasks belong to today until they're done.
                if day == today { return due < today.adding(days: 1) }
                return due.isSameDay(as: day)
            }.sorted(by: order)
            guard !items.isEmpty else { return [] }
            let kind: Kind = day == today ? .today : day == today.adding(days: 1) ? .tomorrow : .day(day)
            return [TaskGroup(kind: kind, tasks: items)]
        }

        var buckets: [Kind: [TaskItem]] = [:]
        var dayKinds: [Date] = []
        for task in tasks {
            let kind: Kind
            if let due = task.dueDate {
                let day = due.startOfDay
                if task.isOverdue && day < today { kind = .overdue }
                else if day <= today { kind = .today }
                else if day == today.adding(days: 1) { kind = .tomorrow }
                else if day < today.adding(days: 7) {
                    kind = .day(day)
                    if !dayKinds.contains(day) { dayKinds.append(day) }
                } else { kind = .later }
            } else {
                kind = .someday
            }
            buckets[kind, default: []].append(task)
        }

        let kinds: [Kind] = [.overdue, .today, .tomorrow] + dayKinds.sorted().map { .day($0) } + [.later, .someday]
        return kinds.compactMap { kind in
            guard let items = buckets[kind], !items.isEmpty else { return nil }
            return TaskGroup(kind: kind, tasks: items.sorted(by: order))
        }
    }
}

/// A group's heading: a colored sticker dot, the name, the date and a count.
private struct GroupHeader: View {
    let group: TaskGroup

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(group.tone.fill)
                .frame(width: 10, height: 10)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
            Text(group.title)
                .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                .tracking(-0.5)
                .foregroundStyle(group.kind == .overdue ? Color.ember : Color.ink)
            if let caption = group.caption {
                MonoCaps(caption)
            }
            Spacer()
            Text("\(group.tasks.count)")
                .font(.allo(size: 13, weight: .heavy).monospacedDigit())
                .foregroundStyle(group.tone == .yellow ? StickerTone.yellow.deep : group.tone.deep)
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(group.tone.fill, in: .capsule)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The next seven days as tappable stickers, each with how many tasks it
/// holds. Tap one to see only that day; tap it again for everything.
private struct WeekStrip: View {
    let tasks: [TaskItem]
    @Binding var selection: Date?

    private var days: [Date] {
        let today = Date.now.startOfDay
        return (0..<7).map { today.adding(days: $0) }
    }

    private func count(on day: Date) -> Int {
        let today = Date.now.startOfDay
        return tasks.filter { task in
            guard let due = task.dueDate else { return false }
            if day == today { return due < today.adding(days: 1) }
            return due.isSameDay(as: day)
        }.count
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let on = selection == day
                    let isToday = day == Date.now.startOfDay
                    let n = count(on: day)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selection = on ? nil : day
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(isToday ? String(localized: "Today") : day.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.allo(size: 11, weight: .heavy))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .opacity(0.75)
                            Text(day.formatted(.dateTime.day()))
                                .font(.hero(26, weight: .heavy))
                                .tracking(-1)
                            HStack(spacing: 3) {
                                ForEach(0..<min(n, 3), id: \.self) { _ in
                                    Circle().frame(width: 5, height: 5)
                                }
                                if n == 0 { Circle().frame(width: 5, height: 5).opacity(0) }
                            }
                            .opacity(on ? 1 : 0.6)
                        }
                        .foregroundStyle(on ? StickerTone.indigo.deep : (isToday ? StickerTone.indigo.fill : Color.ink))
                        .frame(width: 62, height: 86)
                        .background(on ? StickerTone.indigo.fill : (isToday ? StickerTone.yellow.fill : Color.surface),
                                    in: .rect(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.hairline, lineWidth: on || isToday ? 0 : 1.5)
                        }
                        .rotationEffect(.degrees(on ? -3 : 0))
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .accessibilityValue(String(localized: "\(n) tasks"))
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .scrollIndicators(.hidden)
        .sovaFeedback(.selection, trigger: selection)
    }
}

#Preview {
    TasksView()
        .environment(AppRouter())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
