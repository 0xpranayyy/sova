import SwiftUI
import SwiftData
import Combine

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @State private var waves = WaveDirector()

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }

            // Sova's two big moments: the welcome and a whole day done.
            WaveOverlay()
        }
        .animation(.smooth(duration: 0.45), value: hasOnboarded)
        .environment(waves)
        .font(.allo(.body))
        .preferredColorScheme((Appearance(rawValue: appearanceRaw) ?? .system).scheme)
    }
}

struct MainTabView: View {
    @State private var router = AppRouter()
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allRoutines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var activeGoals: [Goal]
    /// Bumps at midnight so day-based screens don't keep showing yesterday.
    @State private var today = Date.now.startOfDay
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("userName") private var userName = ""

    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .ember).accent.color }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                TodayView().id(today)
            }
            Tab("Tasks", systemImage: "checklist", value: AppTab.tasks) {
                TasksView().id(today)
            }
            Tab("Goals", systemImage: "flag", value: AppTab.goals) {
                GoalsView()
            }
            Tab("Rituals", systemImage: "repeat", value: AppTab.routines) {
                RoutinesView().id(today)
            }
            Tab("Insights", systemImage: "chart.bar", value: AppTab.insights) {
                InsightsView().id(today)
            }
            Tab("New", systemImage: "plus", value: AppTab.create, role: .search) {
                Color.canvas
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            today = Date.now.startOfDay
        }
        .onChange(of: userName, initial: true) { _, name in
            // The widgets greet you by name too.
            guard SovaSettings.shared.string(forKey: SovaSettings.Key.userName) != name else { return }
            SovaSettings.shared.set(name, forKey: SovaSettings.Key.userName)
            SovaRefresh.changed(context)
        }
        .onChange(of: allRoutines.count, initial: true) { _, n in router.routineCount = n }
        .onChange(of: activeGoals.count, initial: true) { _, n in router.activeGoalCount = n }
        .task {
            await TaskAlerts.resync(in: context)
            SovaRefresh.changed(context)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // Leaving the app: make the widgets and the badge match what just changed.
            if phase == .background { SovaRefresh.changed(context) }
            if phase == .active { runPendingAction() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sovaPendingAction)) { _ in runPendingAction() }
        .sovaFeedback(.selection, trigger: router.tab)
        .onChange(of: router.tab) { previous, current in
            guard current == .create else { return }
            router.tab = previous
            router.sheet = router.createAction(from: previous)
        }
        .overlay(alignment: .bottom) {
            ToastBar()
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
        }
        .sheet(item: $router.sheet) { sheet in
            editor(for: sheet)
        }
        .tint(Color.ink)
        .environment(router)
    }

    /// Runs whatever a quick action, control or notification asked for.
    private func runPendingAction() {
        let defaults = SovaSettings.shared
        if let taskID = defaults.string(forKey: SovaSettings.Key.pendingTask) {
            defaults.removeObject(forKey: SovaSettings.Key.pendingTask)
            let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
            if let task = tasks.first(where: { $0.alertID == taskID }) {
                router.tab = .tasks
                router.sheet = .task(task)
            }
        }
        guard let raw = defaults.string(forKey: SovaSettings.Key.pendingAction),
              let action = LaunchAction(rawValue: raw) else { return }
        defaults.removeObject(forKey: SovaSettings.Key.pendingAction)
        switch action {
        case .quickTask: router.sheet = .quickTask
        case .newRitual:
            router.tab = .routines
            router.sheet = router.newRoutineSheet
        case .today: router.tab = .today
        case .tasks: router.tab = .tasks
        }
    }

    @ViewBuilder
    private func editor(for sheet: EditorSheet) -> some View {
        switch sheet {
        case .quickTask: QuickCaptureView()
        case .newTask(let goal): TaskEditor(task: nil, defaultGoal: goal)
        case .task(let task): TaskEditor(task: task)
        case .newGoal: GoalEditor(goal: nil)
        case .goal(let goal): GoalEditor(goal: goal)
        case .newRoutine: RoutineEditor(routine: nil)
        case .routine(let routine): RoutineEditor(routine: routine)
        case .plus(let reason): PlusView(reason: reason)
        case .search: SearchView()
        }
    }
}

/// A floating Liquid Glass bar with an Undo, shown briefly after a change.
struct ToastBar: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            if let toast = router.toast {
                HStack(spacing: 12) {
                    Text(toast.message)
                        .font(.allo(.subheadline))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let undo = toast.undo {
                        Button {
                            undo()
                            router.dismissToast()
                        } label: {
                            Text("Undo")
                                .font(.allo(.subheadline, .semibold))
                                .foregroundStyle(Color.ink)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 18)
                .padding(.trailing, 10)
                .frame(height: 52)
                .glassEffect(.regular, in: .capsule)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .id(toast.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: router.toast)
        .sovaFeedback(.impact(weight: .light), trigger: router.toast)
    }
}

#Preview("App") {
    MainTabView()
        .environment(WaveDirector())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}

#Preview("Onboarding") {
    OnboardingView()
        .environment(WaveDirector())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
