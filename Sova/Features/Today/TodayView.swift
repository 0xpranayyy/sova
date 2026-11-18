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

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }

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
    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }

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
        return userName.isEmpty ? base : base + ", " + userName
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                hero.bareListRow(top: 4, bottom: 8)

                TipView(captureTip)
                    .bareListRow(bottom: 6)
                if !dueTasks.isEmpty {
                    TipView(swipeTip)
                        .bareListRow(bottom: 6)
                }

                if !todaysRoutines.isEmpty {
                    SectionLabel(String(localized: "Routines"), trailing: "\(routinesDone)/\(todaysRoutines.count)")
                        .bareListRow(top: 18, bottom: 6)
                    routinesScroller
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                SectionLabel(String(localized: "Tasks"), trailing: dueTasks.isEmpty ? nil : "\(dueTasks.count)")
                    .bareListRow(top: 18, bottom: 6)
                if dueTasks.isEmpty {
                    EmptyState(
                        title: total == 0 ? String(localized: "A fresh start") : String(localized: "All clear"),
                        message: total == 0
                            ? String(localized: "Add what matters today. Type it the way you'd say it.")
                            : String(localized: "Nothing else due today. Enjoy the space."),
                        actionTitle: String(localized: "New Task")
                    ) { router.sheet = .quickTask }
                    .bareListRow(top: 4, bottom: 4)
                } else {
                    ForEach(dueTasks) { task in
                        TaskRow(task: task) { router.sheet = .task(task) }
                            .glassListRow(tint: task.accent.color)
                            .taskSwipeActions(task)
                    }
                }

                if let goal = focusGoal {
                    SectionLabel(String(localized: "In Focus"))
                        .bareListRow(top: 18, bottom: 6)
                    Button { router.tab = .goals } label: { GoalCard(goal: goal) }
                        .buttonStyle(.pressable)
                        .bareListRow(top: 4, bottom: 4)
                }

                if !upcomingTasks.isEmpty {
                    SectionLabel(String(localized: "Coming Up"), trailing: "\(upcomingTasks.count)")
                        .bareListRow(top: 18, bottom: 6)
                    ForEach(upcomingTasks.prefix(8)) { task in
                        TaskRow(task: task) { router.sheet = .task(task) }
                            .glassListRow(tint: task.accent.color)
                            .taskSwipeActions(task)
                    }
                }

                if !completedToday.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showCompleted.toggle() }
                    } label: {
                        HStack(spacing: 8) {
                            SectionLabel(String(localized: "Done Today"), trailing: "\(completedToday.count)")
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.inkSecondary)
                                .rotationEffect(.degrees(showCompleted ? 90 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(showCompleted ? "Collapse" : "Expand")
                    .bareListRow(top: 18, bottom: 6)

                    if showCompleted {
                        ForEach(completedToday) { task in
                            TaskRow(task: task) { router.sheet = .task(task) }
                                .glassListRow()
                                .taskSwipeActions(task)
                        }
                    }
                }

                Color.clear.frame(height: 24).bareListRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .navigationTitle("Today")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
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

    private var hero: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 11, colors: [theme.accent.color, theme.companion.color])
                VStack(spacing: 0) {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .contentTransition(.numericText(value: progress))
                    Text("done")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            .frame(width: 92, height: 92)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Day progress")

            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                summary
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .surface(cornerRadius: 30, padding: 18, tint: theme.accent.color)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)
    }

    private var summary: Text {
        let tasksLeft = dueTasks.count
        if total == 0 { return Text("Nothing planned yet.") }
        if tasksLeft == 0 && routinesLeft == 0 { return Text("Everything’s done. Enjoy the rest of your day.") }
        let taskText = Text(tasksLeft == 1 ? String(localized: "1 task") : String(localized: "\(tasksLeft) tasks"))
            .foregroundStyle(Color.ink).fontWeight(.semibold)
        let routineText = Text(routinesLeft == 1 ? String(localized: "1 routine") : String(localized: "\(routinesLeft) routines"))
            .foregroundStyle(Color.ink).fontWeight(.semibold)
        if routinesLeft == 0 { return Text("\(taskText) left today.") }
        if tasksLeft == 0 { return Text("\(routineText) left today.") }
        return Text("\(taskText) and \(routineText) left today.")
    }

    private var routinesScroller: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 16) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(todaysRoutines) { RoutineDial(routine: $0) }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    TodayView()
        .environment(AppRouter())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
