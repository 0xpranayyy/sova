import SwiftUI
import SwiftData
import TipKit

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("userName") private var userName = ""
    @State private var showCompleted = false
    @State private var showSettings = false

    private let captureTip = QuickCaptureTip()
    private let swipeTip = SwipeTip()

    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .ember).accent.color }

    // MARK: Derived

    private var dueTasks: [TaskItem] {
        tasks.filter { !$0.isDone && $0.isDueTodayOrEarlier }.sorted(by: TaskItem.ordering)
    }

    private var upcomingTasks: [TaskItem] {
        tasks.filter { !$0.isDone && !$0.isDueTodayOrEarlier }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var completedToday: [TaskItem] {
        tasks.filter { $0.isDone && ($0.completedAt?.isSameDay(as: .now) ?? false) }
            .sorted { ($0.completedAt ?? .now) > ($1.completedAt ?? .now) }
    }

    private var todaysRoutines: [Routine] { routines.filter { $0.isScheduled(on: .now) } }
    private var routinesDone: Int { todaysRoutines.filter { $0.isDone(on: .now) }.count }
    private var routinesLeft: Int { todaysRoutines.count - routinesDone }

    private var total: Int { dueTasks.count + completedToday.count + todaysRoutines.count }
    private var done: Int { completedToday.count + routinesDone }

    private var focusGoal: Goal? {
        goals.filter { $0.progress < 1 }
            .min { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    private var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return userName.isEmpty ? base + "." : base + ", " + userName + "."
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header.bareListRow()
                }

                if !todaysRoutines.isEmpty {
                    Section {
                        routinesScroller.bareListRow()
                    } header: {
                        SectionLabel(String(localized: "Routines"), trailing: "\(routinesDone) of \(todaysRoutines.count)")
                    }
                }

                Section {
                    if dueTasks.isEmpty {
                        EmptyState(
                            title: total == 0 ? String(localized: "A blank page") : String(localized: "All clear"),
                            message: total == 0
                                ? String(localized: "Add what matters today. Type it the way you'd say it.")
                                : String(localized: "Nothing else due today. Enjoy the space."),
                            actionTitle: String(localized: "New task")
                        ) { router.sheet = .quickTask }
                        .bareListRow()
                    } else {
                        ForEach(dueTasks) { task in
                            TaskRow(task: task) { router.sheet = .task(task) }
                                .surfaceListRow()
                                .taskSwipeActions(task)
                        }
                    }
                } header: {
                    SectionLabel(String(localized: "Tasks"))
                }

                if let goal = focusGoal {
                    Section {
                        Button { router.tab = .goals } label: { GoalCard(goal: goal) }
                            .buttonStyle(.pressable)
                            .bareListRow()
                    } header: {
                        SectionLabel(String(localized: "In focus"))
                    }
                }

                if !upcomingTasks.isEmpty {
                    Section {
                        ForEach(upcomingTasks.prefix(8)) { task in
                            TaskRow(task: task) { router.sheet = .task(task) }
                                .surfaceListRow()
                                .taskSwipeActions(task)
                        }
                    } header: {
                        SectionLabel(String(localized: "Coming up"), trailing: "\(upcomingTasks.count)")
                    }
                }

                if !completedToday.isEmpty {
                    Section {
                        if showCompleted {
                            ForEach(completedToday) { task in
                                TaskRow(task: task) { router.sheet = .task(task) }
                                    .surfaceListRow()
                                    .taskSwipeActions(task)
                            }
                        }
                    } header: {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showCompleted.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                SectionLabel(String(localized: "Done today"), trailing: "\(completedToday.count)")
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.inkSecondary)
                                    .rotationEffect(.degrees(showCompleted ? 90 : 0))
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(showCompleted ? "Collapse" : "Expand")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(26)
            .scrollContentBackground(.hidden)
            .background { CanvasBackground() }
            .navigationTitle(Date.now.formatted(.dateTime.weekday(.wide)))
            .navigationSubtitle(Date.now.formatted(.dateTime.day().month(.wide)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task {
                for await status in captureTip.statusUpdates {
                    if case .invalidated = status { SwipeTip.isReady = true }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(greeting)
                .font(.display(.title2))
                .foregroundStyle(Color.ink)
            summary
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                DaySegments(done: done, total: total, color: accent)
                Text("\(done)/\(total)")
                    .font(.footnote.weight(.medium).monospacedDigit())
                    .foregroundStyle(Color.inkSecondary)
                    .contentTransition(.numericText())
            }
            .padding(.top, 4)

            TipView(captureTip)
                .tipBackground(Color.surface)
                .padding(.top, 10)
            if !dueTasks.isEmpty {
                TipView(swipeTip)
                    .tipBackground(Color.surface)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private var summary: Text {
        let tasksLeft = dueTasks.count
        if total == 0 { return Text("Nothing planned yet.") }
        if tasksLeft == 0 && routinesLeft == 0 { return Text("Everything’s done. Go enjoy the rest of it.") }
        let taskText = Text(tasksLeft == 1 ? String(localized: "1 task") : String(localized: "\(tasksLeft) tasks"))
            .foregroundStyle(Color.ink)
        let routineText = Text(routinesLeft == 1 ? String(localized: "1 routine") : String(localized: "\(routinesLeft) routines"))
            .foregroundStyle(Color.ink)
        if routinesLeft == 0 { return Text("You have \(taskText) left today.") }
        if tasksLeft == 0 { return Text("Just \(routineText) left today.") }
        return Text("You have \(taskText) and \(routineText) left today.")
    }

    private var routinesScroller: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(todaysRoutines) { RoutineDial(routine: $0) }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}

#Preview {
    TodayView()
        .environment(AppRouter())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
