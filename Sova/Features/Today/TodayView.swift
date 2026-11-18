import SwiftUI
import SwiftData
import TipKit

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("theme") private var themeRaw = SovaTheme.lime.rawValue
    @AppStorage("userName") private var userName = ""
    @State private var showSettings = false

    private let captureTip = QuickCaptureTip()
    private let swipeTip = SwipeTip()

    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .lime).accent.color }

    private var entries: [TimelineEntry] { TimelineEntry.build(tasks: tasks, routines: routines) }

    private var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return userName.isEmpty ? base : base + ", " + userName
    }

    /// The single item that deserves attention right now.
    private func nextID(in entries: [TimelineEntry]) -> String? {
        let open = entries.filter { !$0.isDone && $0.section != .overdue }
        if let timed = open.filter({ ($0.dueTime ?? .distantPast) >= .now })
            .min(by: { ($0.dueTime ?? .distantFuture) < ($1.dueTime ?? .distantFuture) }) {
            return timed.id
        }
        return open.first(where: { $0.section.rawValue >= DaySection.current.rawValue })?.id ?? open.first?.id
    }

    var body: some View {
        let entries = self.entries
        let done = entries.filter(\.isDone).count
        let total = entries.count
        let overdue = entries.filter { $0.section == .overdue && !$0.isDone }.count
        let next = nextID(in: entries)
        let sections = DaySection.allCases.filter { section in entries.contains { $0.section == section } }

        NavigationStack {
            List {
                header(done: done, total: total, overdue: overdue)
                    .bareListRow(top: 0, bottom: 10)

                TipView(captureTip)
                    .bareListRow(bottom: 8)
                if total > 0 {
                    TipView(swipeTip)
                        .bareListRow(bottom: 8)
                }

                if total == 0 {
                    EmptyState(title: String(localized: "Nothing planned"),
                               message: String(localized: "Nothing here yet. Add a task, or set up a ritual."),
                               actionTitle: String(localized: "New task")) { router.sheet = .quickTask }
                        .bareListRow(top: 12)
                }

                ForEach(sections) { section in
                    let items = entries.filter { $0.section == section }
                    TimelineSectionHeader(section: section,
                                          count: section.range == nil ? "\(items.filter(\.isDone).count)/\(items.count)" : nil)
                        .background(TimelineRail())
                        .bareListRow()

                    let nowIndex = section == DaySection.current ? (items.firstIndex { !$0.isDone } ?? items.count) : nil
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, entry in
                        if index == nowIndex {
                            NowMarker(accent: accent)
                                .background(TimelineRail())
                                .bareListRow()
                        }
                        row(entry, isNext: entry.id == next)
                    }
                    if nowIndex == items.count {
                        NowMarker(accent: accent)
                            .background(TimelineRail())
                            .bareListRow()
                    }
                }

                Color.clear.frame(height: 40).bareListRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .background { CanvasBackground() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task {
                for await status in captureTip.statusUpdates {
                    if case .invalidated = status { SwipeTip.isReady = true }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ entry: TimelineEntry, isNext: Bool) -> some View {
        let base = TimelineRow(entry: entry, isNext: isNext, accent: accent) {
            switch entry.source {
            case .task(let t): router.sheet = .task(t)
            case .routine(let r): router.sheet = .routine(r)
            }
        }
        .background(TimelineRail())

        switch entry.source {
        case .task(let task):
            base.bareListRow().taskSwipeActions(task)
        case .routine(let routine):
            base.bareListRow()
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { routine.toggle(on: .now) }
                    } label: {
                        Label(routine.isDone(on: .now) ? "Not Done" : "Done",
                              systemImage: routine.isDone(on: .now) ? "arrow.uturn.backward" : "checkmark")
                    }
                    .tint(accent)
                }
        }
    }

    private func header(done: Int, total: Int, overdue: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            Text(greeting)
                .font(.allo(.callout))
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 22)
            HStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    Text("\(done)")
                        .foregroundStyle(Color.ink)
                        .contentTransition(.numericText(value: Double(done)))
                    Text("/\(total)")
                        .foregroundStyle(Color.ink.opacity(0.2))
                        .contentTransition(.numericText(value: Double(total)))
                }
                .font(.hero(100))
                .tracking(-5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(status(done: done, total: total, overdue: overdue))
                        .font(.allo(.subheadline, .semibold))
                        .foregroundStyle(overdue > 0 ? Color.danger : Color.ink)
                    Text(total == done ? String(localized: "Nothing left") : String(localized: "\(total - done) left"))
                        .font(.allo(.footnote))
                        .foregroundStyle(Color.inkTertiary)
                }
                .padding(.bottom, 12)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: done)
            DaySegments(done: done, total: total, color: accent)
                .padding(.top, 16)
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
    }

    private func status(done: Int, total: Int, overdue: Int) -> String {
        if total == 0 { return String(localized: "Nothing planned") }
        if done == total { return String(localized: "All done") }
        if overdue > 0 { return String(localized: "\(overdue) overdue") }
        return String(localized: "On track")
    }
}

#Preview {
    TodayView()
        .environment(AppRouter())
        .preferredColorScheme(.dark)
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
