import SwiftUI
import SwiftData
import TipKit

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("userName") private var userName = ""
    @State private var showSettings = false
    @State private var showDone = false

    private let captureTip = QuickCaptureTip()
    private let swipeTip = SwipeTip()

    private var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return userName.isEmpty ? base : base + ", " + userName
    }

    private func next(in entries: [TimelineEntry]) -> TimelineEntry? {
        let open = entries.filter { !$0.isDone && $0.section != .overdue }
        if let timed = open.filter({ ($0.dueTime ?? .distantPast) >= .now })
            .min(by: { ($0.dueTime ?? .distantFuture) < ($1.dueTime ?? .distantFuture) }) {
            return timed
        }
        return open.first(where: { $0.section.rawValue >= DaySection.current.rawValue }) ?? open.first
    }

    var body: some View {
        let entries = TimelineEntry.build(tasks: tasks, routines: routines)
        let done = entries.filter(\.isDone)
        let upNext = next(in: entries)
        let open = entries.filter { !$0.isDone && $0.id != upNext?.id }
        let overdue = open.filter { $0.section == .overdue }
        let later = open.filter { $0.section != .overdue }

        NavigationStack {
            List {
                ScreenTitle(title: String(localized: "Today"),
                            subtitle: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                    CircleAction(symbol: "gearshape", label: String(localized: "Settings")) { showSettings = true }
                }
                .cardRow(top: 4, bottom: 14)

                ProgressBlock(greeting: greeting, done: done.count, total: entries.count, overdue: overdue.count)
                    .cardRow(bottom: 10)

                TipView(captureTip).cardRow(bottom: 8)
                if !entries.isEmpty { TipView(swipeTip).cardRow(bottom: 8) }

                if entries.isEmpty {
                    EmptyState(title: String(localized: "Nothing planned"),
                               message: String(localized: "Add a task, or set up a ritual you want to keep."),
                               actionTitle: String(localized: "New task")) { router.sheet = .quickTask }
                        .cardRow(top: 4)
                }

                if let upNext {
                    UpNextCard(entry: upNext) { open(upNext) }
                        .cardRow(bottom: 6)
                }

                if !overdue.isEmpty {
                    SectionLabel(String(localized: "Overdue"), trailing: "\(overdue.count)", color: .ember)
                        .cardRow(top: 18, bottom: 10)
                    ForEach(overdue) { row($0) }
                }

                if !later.isEmpty {
                    SectionLabel(String(localized: "Later today"), trailing: "\(later.count)")
                        .cardRow(top: 18, bottom: 10)
                    ForEach(later) { row($0) }
                }

                if !done.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDone.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            SectionLabel(String(localized: "Done today"), trailing: "\(done.count)")
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Color.inkTertiary)
                                .rotationEffect(.degrees(showDone ? 90 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .cardRow(top: 18, bottom: 10)
                    if showDone { ForEach(done) { row($0) } }
                }

                Color.clear.frame(height: 80).cardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task {
                for await status in captureTip.statusUpdates {
                    if case .invalidated = status { SwipeTip.isReady = true }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ entry: TimelineEntry) -> some View {
        let base = DayRow(entry: entry) { open(entry) }
            .cardRow(top: 4, bottom: 4)
        switch entry.source {
        case .task(let task):
            base.taskSwipeActions(task)
        case .routine(let routine):
            base.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { routine.toggle(on: .now) }
                } label: {
                    Label(routine.isDone(on: .now) ? "Not Done" : "Done",
                          systemImage: routine.isDone(on: .now) ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(StickerTone.mint.deep)
            }
        }
    }

    private func open(_ entry: TimelineEntry) {
        switch entry.source {
        case .task(let t): router.sheet = .task(t)
        case .routine(let r): router.sheet = .routine(r)
        }
    }
}

extension View {
    /// A List row with no chrome and standard side margins.
    func cardRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

/// The day at a glance: a big yellow block with the count and chunky ticks.
struct ProgressBlock: View {
    let greeting: String
    let done: Int
    let total: Int
    let overdue: Int

    private let tone = StickerTone.yellow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                MonoCaps(greeting, color: tone.deep)
                Spacer()
                OwlMark(size: 36, happy: total > 0 && done == total, blinks: true,
                        bodyColor: tone.deep, eyeColor: tone.fill)
                    .rotationEffect(.degrees(-10))
                    .offset(y: -4)
            }
            HStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    Text("\(done)")
                    Text("/\(total)").opacity(0.35)
                }
                .font(.hero(76, weight: .heavy))
                .tracking(-3.4)
                .contentTransition(.numericText(value: Double(done)))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(status).font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                    Text(detail).font(.allo(.footnote, .bold)).opacity(0.7)
                }
                .padding(.bottom, 10)
            }
            .padding(.top, -4)
            DaySegments(done: done, total: max(total, 1), color: tone.deep)
                .padding(.top, 12)
        }
        .block(tone)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: done)
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        if total == 0 { return String(localized: "Clear day") }
        if done == total { return String(localized: "All done") }
        return String(localized: "\(total - done) to go")
    }

    private var detail: String {
        if total == 0 { return String(localized: "nothing planned") }
        if done == total { return String(localized: "nice work") }
        return overdue > 0 ? String(localized: "\(overdue) overdue") : String(localized: "on track")
    }
}

/// The one thing to do next: an indigo block with big buttons.
struct UpNextCard: View {
    let entry: TimelineEntry
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(label, color: StickerTone.indigo.deep)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if case .task(let t) = entry.source, !t.priority.marks.isEmpty {
                    Text(t.priority.marks).foregroundStyle(StickerTone.pink.fill)
                }
                Text(title)
            }
            .font(.allo(size: 26, weight: .heavy, relativeTo: .title2))
            .tracking(-0.8)
            .padding(.top, 8)
            if let meta {
                Text(meta)
                    .font(.allo(.subheadline, .bold))
                    .opacity(0.6)
                    .padding(.top, 4)
            }
            HStack(spacing: 8) {
                Button(action: complete) {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(.big(.yellow, height: 50))
                .layoutPriority(1)
                if case .task(let t) = entry.source {
                    Button {
                        TaskActions.moveToTomorrow(t, router: router)
                    } label: {
                        Text("Tomorrow")
                            .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.white.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.top, 16)
        }
        .block(.indigo)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
    }

    private var title: String {
        switch entry.source {
        case .task(let t): t.title
        case .routine(let r): r.title
        }
    }

    private var meta: String? {
        var parts: [String] = []
        if let due = entry.dueTime { parts.append(due.formatted(date: .omitted, time: .shortened)) }
        switch entry.source {
        case .task(let t):
            if let goal = t.goal { parts.append(goal.title) } else if !t.notes.isEmpty { parts.append(t.notes) }
        case .routine(let r):
            parts.append(r.streak > 1 ? String(localized: "Ritual · \(r.streak)-day streak") : String(localized: "Ritual"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var label: String {
        guard let due = entry.dueTime, due > .now else { return String(localized: "Up next") }
        let minutes = Int(due.timeIntervalSinceNow / 60)
        if minutes < 60 { return String(localized: "Up next · in \(max(minutes, 1)) min") }
        return minutes < 12 * 60 ? String(localized: "Up next · in \(minutes / 60) h") : String(localized: "Up next")
    }

    private func complete() {
        switch entry.source {
        case .task(let t): TaskActions.toggle(t, router: router)
        case .routine(let r):
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { r.toggle(on: .now) }
        }
    }
}

/// A ritual as a block in its color; a task as a white card.
struct DayRow: View {
    let entry: TimelineEntry
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        switch entry.source {
        case .routine(let r): ritualRow(r)
        case .task(let t): taskRow(t)
        }
    }

    private func ritualRow(_ r: Routine) -> some View {
        let tone = StickerTone(r.accent)
        let ink = tone == .indigo ? Color.white : tone.deep
        return HStack(spacing: 12) {
            Image(systemName: r.symbol)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(ink)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(r.title)
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                Text(r.period == .anytime ? String(localized: "Anytime") : r.period.name)
                    .font(.allo(.footnote, .bold))
                    .opacity(0.7)
            }
            .foregroundStyle(ink)
            Spacer(minLength: 6)
            if r.streak > 1 {
                Text(String(localized: "\(r.streak) days"))
                    .font(.allo(size: 10.5, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.45), in: .rect(cornerRadius: 9, style: .continuous))
            }
            CheckButton(isOn: entry.isDone, color: tone == .indigo ? tone.deep : tone.deep,
                        round: true, size: 30, checkColor: tone.fill, label: r.title, action: toggle)
                .padding(.trailing, -6)
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .background(tone.fill, in: .rect(cornerRadius: 24, style: .continuous))
        .opacity(entry.isDone ? 0.55 : 1)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: entry.isDone ? "Mark as not done" : "Mark as done", toggle)
    }

    private func taskRow(_ t: TaskItem) -> some View {
        HStack(spacing: 10) {
            CheckButton(isOn: entry.isDone, color: Color.ink, round: false, size: 28, label: t.title, action: toggle)
                .padding(.leading, -6)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if !t.priority.marks.isEmpty && !t.isDone {
                        Text(t.priority.marks).foregroundStyle(Color.ember)
                    }
                    Text(t.title).foregroundStyle(t.isDone ? Color.inkTertiary : Color.ink)
                }
                .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                .tracking(-0.4)
                .lineLimit(2)
                Text(meta(t))
                    .font(.allo(.footnote, .bold))
                    .foregroundStyle(entry.section == .overdue && !t.isDone ? Color.ember : Color.inkSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            if let time = time(t) {
                Text(time)
                    .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline).monospacedDigit())
                    .foregroundStyle(Color.ink)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(Color.white, in: .rect(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: entry.isDone ? "Mark as not done" : "Mark as done", toggle)
    }

    private func meta(_ t: TaskItem) -> String {
        if entry.section == .overdue, let due = t.dueDate {
            return String(localized: "Was due \(due.formatted(.dateTime.month(.abbreviated).day()))")
        }
        return t.goal?.title ?? (t.notes.isEmpty ? String(localized: "Task") : t.notes)
    }

    private func time(_ t: TaskItem) -> String? {
        if t.isDone, let done = t.completedAt { return done.formatted(date: .omitted, time: .shortened) }
        if t.hasTime, let due = t.dueDate { return due.formatted(date: .omitted, time: .shortened) }
        return nil
    }

    private func toggle() {
        switch entry.source {
        case .task(let t): TaskActions.toggle(t, router: router)
        case .routine(let r):
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { r.toggle(on: .now) }
        }
    }
}

#Preview {
    TodayView()
        .environment(AppRouter())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
