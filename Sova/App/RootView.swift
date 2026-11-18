import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.03)),
                        removal: .opacity
                    ))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.6), value: hasOnboarded)
        .font(.allo(.body))
        .preferredColorScheme(.light)
    }
}

struct MainTabView: View {
    @State private var router = AppRouter()
    @AppStorage("theme") private var themeRaw = SovaTheme.ink.rawValue

    private var accent: Color { (SovaTheme(rawValue: themeRaw) ?? .ink).accent.color }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                TodayView()
            }
            Tab("Goals", systemImage: "flag", value: AppTab.goals) {
                GoalsView()
            }
            Tab("Rituals", systemImage: "repeat", value: AppTab.routines) {
                RoutinesView()
            }
            Tab("Insights", systemImage: "chart.bar", value: AppTab.insights) {
                InsightsView()
            }
            Tab("New", systemImage: "plus", value: AppTab.create, role: .search) {
                Color.canvas
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
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
        .tint(accent)
        .environment(router)
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
                                .foregroundStyle(Color.accentColor)
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
        .sensoryFeedback(.impact(weight: .light), trigger: router.toast)
    }
}

#Preview("App") {
    MainTabView()
        .preferredColorScheme(.light)
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}

#Preview("Onboarding") {
    OnboardingView()
        .preferredColorScheme(.light)
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
