import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("userName") private var userName = ""
    @State private var showCompleted = false

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
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    header
                    if !todaysRoutines.isEmpty { routinesSection }
                    tasksSection
                    if let goal = focusGoal { focusSection(goal) }
                    if !upcomingTasks.isEmpty { upcomingSection }
                    if !completedToday.isEmpty { completedSection }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: tasks.map(\.isDone))
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .navigationTitle(Date.now.formatted(.dateTime.weekday(.wide)))
            .navigationSubtitle(Date.now.formatted(.dateTime.day().month(.wide)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsMenu() }
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
        }
        .padding(.horizontal, 4)
    }

    private var summary: Text {
        let tasksLeft = dueTasks.count
        if total == 0 {
            return Text("Nothing planned. A rare, open day.")
        }
        if tasksLeft == 0 && routinesLeft == 0 {
            return Text("Everything’s done. Go enjoy the rest of it.")
        }
        let taskText = Text(tasksLeft == 1 ? String(localized: "1 task") : String(localized: "\(tasksLeft) tasks"))
            .foregroundStyle(Color.ink)
        let routineText = Text(routinesLeft == 1 ? String(localized: "1 routine") : String(localized: "\(routinesLeft) routines"))
            .foregroundStyle(Color.ink)
        if routinesLeft == 0 { return Text("You have \(taskText) left today.") }
        if tasksLeft == 0 { return Text("Just \(routineText) left today.") }
        return Text("You have \(taskText) and \(routineText) left today.")
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(String(localized: "Routines"), trailing: "\(routinesDone) of \(todaysRoutines.count)")
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(todaysRoutines) { RoutineDial(routine: $0) }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -20)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Tasks"))
            if dueTasks.isEmpty {
                EmptyState(title: String(localized: "All clear"),
                           message: String(localized: "Nothing due today. Add something, or enjoy the space."),
                           actionTitle: String(localized: "Add a task")) { router.sheet = .newTask(nil) }
            } else {
                GroupedList(items: dueTasks, inset: 52) { task in
                    TaskRow(task: task) { router.sheet = .task(task) }
                }
            }
        }
    }

    private func focusSection(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "In focus"))
            Button { router.tab = .goals } label: { GoalCard(goal: goal) }
                .buttonStyle(.pressable)
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Coming up"), trailing: "\(upcomingTasks.count)")
            GroupedList(items: Array(upcomingTasks.prefix(6)), inset: 52) { task in
                TaskRow(task: task) { router.sheet = .task(task) }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            if showCompleted {
                GroupedList(items: completedToday, inset: 52) { task in
                    TaskRow(task: task) { router.sheet = .task(task) }
                }
                .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
    }
}

#Preview {
    TodayView()
        .environment(AppRouter())
        .modelContainer(SampleData.previewContainer)
}
