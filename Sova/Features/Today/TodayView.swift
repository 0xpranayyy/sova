import SwiftUI
import SwiftData
import TipKit

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("theme") private var themeRaw = SovaTheme.ink.rawValue
    @AppStorage("userName") private var userName = ""
    @State private var showSettings = false
    @State private var showDone = false

    private let captureTip = QuickCaptureTip()
    private let swipeTip = SwipeTip()
    private let heroHeight: CGFloat = 330

    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .ink).accent.color }

    private var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return userName.isEmpty ? base : base + ", " + userName
    }

    /// The one item that deserves attention now.
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
        let sections = DaySection.allCases.filter { s in open.contains { $0.section == s } }
        let overdue = entries.filter { $0.section == .overdue && !$0.isDone }.count

        NavigationStack {
            List {
                // Greeting, over the sunlight.
                VStack(spacing: 6) {
                    if !entries.isEmpty && done.count == entries.count {
                        OwlMark(size: 34, happy: true, blinks: false, bodyColor: .white, eyeColor: Color.sun)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.bottom, 4)
                    }
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.allo(.subheadline, .medium))
                        .opacity(0.92)
                    Text(greeting)
                        .font(.allo(size: 32, weight: .medium, relativeTo: .largeTitle))
                        .tracking(-1.2)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(summary(done: done.count, total: entries.count, overdue: overdue))
                        .font(.allo(.subheadline))
                        .opacity(0.92)
                        .contentTransition(.numericText())
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: done.count)
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight - 110 - 40, alignment: .center)
                .padding(.top, 40)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if entries.isEmpty {
                    Section {
                        EmptyState(title: String(localized: "Nothing planned"),
                                   message: String(localized: "Add a task, or set up a ritual you want to keep."),
                                   actionTitle: String(localized: "New task")) { router.sheet = .quickTask }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                if let upNext {
                    Section {
                        UpNextCard(entry: upNext, accent: accent) { open(upNext) }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                Section {
                    TipView(captureTip)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    if !entries.isEmpty {
                        TipView(swipeTip)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
                .listSectionSpacing(0)

                ForEach(sections) { section in
                    Section {
                        ForEach(open.filter { $0.section == section }) { entry in
                            row(entry)
                        }
                    } header: {
                        SectionLabel(title(for: section), color: section == .overdue ? .danger : .inkSecondary)
                    }
                }

                if !done.isEmpty {
                    Section {
                        if showDone {
                            ForEach(done) { row($0) }
                        }
                    } header: {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDone.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                SectionLabel(String(localized: "Done today"), trailing: "\(done.count)")
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.inkTertiary)
                                    .rotationEffect(.degrees(showDone ? 90 : 0))
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Color.clear.frame(height: 60)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(18)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(alignment: .top) {
                ZStack(alignment: .top) {
                    Color.canvas
                    SunHero(height: heroHeight + 60, arcDepth: 56) { EmptyView() }
                }
                .ignoresSafeArea()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                SovaNavPill {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Settings")
                }
                .padding(.top, 4)
            }
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
        let base = DayRow(entry: entry, accent: accent) { open(entry) }
            .listRowInsets(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 14))
            .listRowBackground(Color.white)
            .listRowSeparatorTint(Color.hairline)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 50 }
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
                .tint(.black)
            }
        }
    }

    private func open(_ entry: TimelineEntry) {
        switch entry.source {
        case .task(let t): router.sheet = .task(t)
        case .routine(let r): router.sheet = .routine(r)
        }
    }

    private func title(for section: DaySection) -> String {
        guard section != .overdue, section != .anytime else { return section.title }
        if section == DaySection.current {
            switch section {
            case .morning: return String(localized: "This morning")
            case .afternoon: return String(localized: "This afternoon")
            default: return String(localized: "This evening")
            }
        }
        return section.title
    }

    private func summary(done: Int, total: Int, overdue: Int) -> String {
        if total == 0 { return String(localized: "Nothing planned yet") }
        if done == total { return String(localized: "All \(total) done") }
        if overdue > 0 { return String(localized: "\(done) of \(total) done · \(overdue) overdue") }
        return String(localized: "\(done) of \(total) done · on track")
    }
}

/// The one thing to do next, with its two most useful actions.
struct UpNextCard: View {
    let entry: TimelineEntry
    var accent: Color
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                MonoCaps(label)
                Spacer()
                if let due = entry.dueTime {
                    MonoCaps(due.formatted(.dateTime.hour().minute()))
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if case .task(let t) = entry.source, !t.priority.marks.isEmpty {
                    Text(t.priority.marks).foregroundStyle(Color.danger)
                }
                Text(title).foregroundStyle(Color.ink)
            }
            .font(.allo(size: 23, weight: .medium, relativeTo: .title2))
            .tracking(-0.8)
            .padding(.top, 10)
            if let meta {
                Text(meta)
                    .font(.allo(.subheadline))
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 4)
            }
            HStack(spacing: 8) {
                Button(String(localized: "Mark done"), action: complete)
                    .buttonStyle(.inkCompact)
                    .frame(maxWidth: .infinity)
                if case .task(let t) = entry.source {
                    Button(String(localized: "Tomorrow")) { TaskActions.moveToTomorrow(t, router: router) }
                        .buttonStyle(.quiet)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 16)
        }
        .surface(cornerRadius: 16, padding: 18)
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

/// A task or ritual as a row inside a white card.
struct DayRow: View {
    let entry: TimelineEntry
    var accent: Color
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            CheckButton(isOn: entry.isDone, color: accent, round: entry.isRoutine, label: title, action: toggle)
                .padding(.top, -1)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if case .task(let t) = entry.source, !t.priority.marks.isEmpty, !entry.isDone {
                        Text(t.priority.marks).foregroundStyle(Color.danger)
                    }
                    Text(title).foregroundStyle(entry.isDone ? Color.inkTertiary : Color.ink)
                }
                .font(.allo(.body, .medium))
                .lineLimit(2)
                if !meta.isEmpty {
                    Text(meta)
                        .font(.allo(.footnote))
                        .foregroundStyle(entry.section == .overdue && !entry.isDone ? Color.danger : Color.inkTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 11)
            Spacer(minLength: 8)
            Text(time)
                .font(.mono(13, weight: .regular))
                .foregroundStyle(Color.inkTertiary)
                .padding(.top, 13)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: entry.isDone ? "Mark as not done" : "Mark as done", toggle)
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
            return r.streak > 1 ? String(localized: "Ritual · \(r.streak)-day streak") : String(localized: "Ritual")
        }
    }

    private var time: String {
        switch entry.source {
        case .task(let t):
            if t.isDone, let done = t.completedAt { return done.formatted(.dateTime.hour().minute()) }
            if t.hasTime, let due = t.dueDate { return due.formatted(.dateTime.hour().minute()) }
            return ""
        case .routine(let r):
            return r.completions.last(where: { $0.isSameDay(as: .now) })?.formatted(.dateTime.hour().minute()) ?? ""
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
