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
    }
}

struct MainTabView: View {
    @State private var router = AppRouter()
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                TodayView()
            }
            Tab("Goals", systemImage: "flag", value: AppTab.goals) {
                GoalsView()
            }
            Tab("Routines", systemImage: "repeat", value: AppTab.routines) {
                RoutinesView()
            }
            Tab("Insights", systemImage: "chart.bar", value: AppTab.insights) {
                InsightsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            QuickAddAccessory()
        }
        .sheet(item: $router.sheet) { sheet in
            editor(for: sheet)
        }
        .tint(theme.accent.color)
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

/// Sits on the Liquid Glass bar above the tabs. Normally one tap to create
/// whatever fits the current tab; briefly an Undo bar after a change.
struct QuickAddAccessory: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            if let toast = router.toast {
                HStack(spacing: 12) {
                    Text(toast.message)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let undo = toast.undo {
                        Button("Undo") {
                            undo()
                            router.dismissToast()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 16)
                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                .id(toast.id)
            } else {
                Button {
                    router.sheet = router.primaryCreateAction
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.inkInverse)
                            .frame(width: 26, height: 26)
                            .background(Color.ink, in: .circle)
                        Text(router.primaryCreateTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.ink)
                            .contentTransition(.interpolate)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(router.primaryCreateTitle)
                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
            }
        }
        .frame(maxHeight: .infinity)
        .clipped()
        .animation(.snappy, value: router.tab)
        .sensoryFeedback(.impact(weight: .light), trigger: router.toast)
    }
}

#Preview("App") {
    MainTabView()
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}

#Preview("Onboarding") {
    OnboardingView()
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
