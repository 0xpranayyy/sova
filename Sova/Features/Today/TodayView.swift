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
        let progress = entries.isEmpty ? 0 : Double(done.count) / Double(entries.count)

        NavigationStack {
            List {
                header
                    .cardRow(top: 4, bottom: 10)

                SkyCard(progress: progress, owlHappy: !entries.isEmpty && done.count == entries.count) {
                    VStack(spacing: 0) {
                        Text(greeting)
                            .font(.allo(.subheadline, .semibold))
                            .foregroundStyle(Color.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 22)
                            .padding(.top, 20)
                        Text(entries.isEmpty ? String(localized: "A clear sky")
                             : String(localized: "\(done.count) of \(entries.count)"))
                            .font(.hero(52, weight: .heavy))
                            .tracking(-2.5)
                            .foregroundStyle(Color.ink)
                            .contentTransition(.numericText(value: Double(done.count)))
                            .padding(.top, 38)
                        Text(subtitle(done: done.count, total: entries.count, overdue: overdue.count))
                            .font(.allo(.subheadline, .semibold))
                            .foregroundStyle(Color.inkSecondary)
                            .padding(.top, 6)
                    }
                }
                .cardRow(bottom: 10)
                .accessibilityElement(children: .combine)

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
                        .cardRow(top: 0, bottom: 6)
                }

                if !overdue.isEmpty {
                    SectionLabel(String(localized: "Overdue"), trailing: "\(overdue.count)", color: .ember)
                        .cardRow(top: 18, bottom: 8)
                    ForEach(overdue) { row($0) }
                }

                if !later.isEmpty {
                    SectionLabel(String(localized: "Later today"), trailing: "\(later.count)")
                        .cardRow(top: 18, bottom: 8)
                    ForEach(later) { row($0) }
                }

                if !done.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDone.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            SectionLabel(String(localized: "Done today"), trailing: "\(done.count)")
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.inkTertiary)
                                .rotationEffect(.degrees(showDone ? 90 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .cardRow(top: 18, bottom: 8)
                    if showDone { ForEach(done) { row($0) } }
                }

                Color.clear.frame(height: 70).cardRow()
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

    private var header: some View {
        HStack(spacing: 10) {
            OwlMark(size: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                    .tracking(-0.6)
                    .foregroundStyle(Color.ink)
                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                    .font(.allo(.footnote, .semibold))
                    .foregroundStyle(Color.inkSecondary)
            }
            Spacer()
            CircleAction(symbol: "gearshape", label: String(localized: "Settings")) { showSettings = true }
        }
        .padding(.leading, 4)
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
                .tint(Color.ember)
            }
        }
    }

    private func open(_ entry: TimelineEntry) {
        switch entry.source {
        case .task(let t): router.sheet = .task(t)
        case .routine(let r): router.sheet = .routine(r)
        }
    }

    private func subtitle(done: Int, total: Int, overdue: Int) -> String {
        if total == 0 { return String(localized: "Nothing planned yet") }
        if done == total { return String(localized: "done · what a day") }
        if overdue > 0 { return String(localized: "done · \(overdue) overdue") }
        return String(localized: "done · the day is on track")
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

/// The one thing to do next: a bold indigo card.
struct UpNextCard: View {
    let entry: TimelineEntry
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .foregroundStyle(StickerTone.yellow.fill)
                Spacer()
                if let due = entry.dueTime {
                    Text(due.formatted(date: .omitted, time: .shortened)).opacity(0.6)
                }
            }
            .font(.allo(size: 10.5, weight: .heavy, relativeTo: .caption2))
            .tracking(1.2)
            .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if case .task(let t) = entry.source, !t.priority.marks.isEmpty {
                    Text(t.priority.marks).foregroundStyle(Color.ember)
                }
                Text(title)
            }
            .font(.allo(size: 23, weight: .heavy, relativeTo: .title2))
            .tracking(-0.7)
            .padding(.top, 8)
            if let meta {
                Text(meta)
                    .font(.allo(.subheadline, .medium))
                    .opacity(0.6)
                    .padding(.top, 2)
            }
            HStack(spacing: 8) {
                Button(String(localized: "Done"), action: complete)
                    .buttonStyle(.emberCompact)
                    .frame(maxWidth: .infinity)
                if case .task(let t) = entry.source {
                    Button {
                        TaskActions.moveToTomorrow(t, router: router)
                    } label: {
                        Text("Tomorrow")
                            .font(.allo(.subheadline, .bold))
                            .foregroundStyle(Color.canvas)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.canvas.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.top, 14)
        }
        .foregroundStyle(Color.canvas)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 26, style: .continuous))
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
        switch entry.source {
        case .task(let t): t.goal?.title ?? (t.notes.isEmpty ? nil : t.notes)
        case .routine(let r): r.streak > 1 ? String(localized: "Ritual · \(r.streak)-day streak") : String(localized: "Ritual")
        }
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

/// A task or ritual as its own white card.
struct DayRow: View {
    let entry: TimelineEntry
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(spacing: 8) {
            CheckButton(isOn: entry.isDone, color: .ember, round: entry.isRoutine, label: title, action: toggle)
                .padding(.leading, -6)
            if case .routine(let r) = entry.source {
                StickerIcon(symbol: r.symbol, tone: StickerTone(r.accent), size: 34)
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if case .task(let t) = entry.source, !t.priority.marks.isEmpty, !entry.isDone {
                        Text(t.priority.marks).foregroundStyle(Color.ember)
                    }
                    Text(title).foregroundStyle(entry.isDone ? Color.inkTertiary : Color.ink)
                }
                .font(.allo(.body, .bold))
                .tracking(-0.3)
                .lineLimit(2)
                if !meta.isEmpty {
                    Text(meta)
                        .font(.allo(.footnote, .medium))
                        .foregroundStyle(entry.section == .overdue && !entry.isDone ? Color.ember : Color.inkTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            trailing
        }
        .padding(.vertical, 6)
        .padding(.trailing, 6)
        .surface(cornerRadius: 22, padding: 8)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: entry.isDone ? "Mark as not done" : "Mark as done", toggle)
    }

    @ViewBuilder
    private var trailing: some View {
        switch entry.source {
        case .routine(let r) where r.streak > 1:
            StickerChip(text: "\(r.streak)d", tone: .mint)
        default:
            if !time.isEmpty {
                Text(time)
                    .font(.allo(.footnote, .bold).monospacedDigit())
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.canvas, in: .rect(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var title: String {
        switch entry.source {
        case .task(let t): t.title
        case .routine(let r): r.title
        }
    }

    private var meta: String {
        switch entry.source {
        case .task(let t):
            if entry.section == .overdue, let due = t.dueDate {
                return String(localized: "Was due \(due.formatted(.dateTime.month(.abbreviated).day()))")
            }
            return t.goal?.title ?? (t.notes.isEmpty ? String(localized: "Task") : t.notes)
        case .routine(let r):
            return r.period == .anytime ? String(localized: "Ritual · anytime") : String(localized: "Ritual · \(r.period.name.lowercased())")
        }
    }

    private var time: String {
        switch entry.source {
        case .task(let t):
            if t.isDone, let done = t.completedAt { return done.formatted(date: .omitted, time: .shortened) }
            if t.hasTime, let due = t.dueDate { return due.formatted(date: .omitted, time: .shortened) }
            return ""
        case .routine(let r):
            return r.completions.last(where: { $0.isSameDay(as: .now) })?.formatted(date: .omitted, time: .shortened) ?? ""
        }
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
