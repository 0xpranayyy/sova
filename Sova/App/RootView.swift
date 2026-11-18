import SwiftUI
import SwiftData

struct RootView: View {
    @State private var router = AppRouter()
    @Environment(\.modelContext) private var context
    @AppStorage("didSeedSampleData") private var didSeed = false
    @AppStorage("theme") private var themeRaw = AuroraTheme.aurora.rawValue

    private var theme: AuroraTheme { AuroraTheme(rawValue: themeRaw) ?? .aurora }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                TodayView()
            }
            Tab("Goals", systemImage: "target", value: AppTab.goals) {
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
        .tint(theme.tint)
        .environment(router)
        .task {
            guard !didSeed else { return }
            SampleData.seedIfEmpty(context)
            didSeed = true
        }
    }

    @ViewBuilder
    private func editor(for sheet: EditorSheet) -> some View {
        switch sheet {
        case .newTask(let goal): TaskEditor(task: nil, defaultGoal: goal)
        case .task(let task): TaskEditor(task: task)
        case .newGoal: GoalEditor(goal: nil)
        case .goal(let goal): GoalEditor(goal: goal)
        case .newRoutine: RoutineEditor(routine: nil)
        case .routine(let routine): RoutineEditor(routine: routine)
        }
    }
}

/// Floating Liquid Glass accessory above the tab bar: one tap to create
/// whatever fits the current tab.
struct QuickAddAccessory: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button {
            router.sheet = router.primaryCreateAction
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.gradient, in: .circle)
                Text(router.primaryCreateTitle)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.interpolate)
                Spacer(minLength: 0)
                Text(Date.now, format: .dateTime.weekday(.abbreviated).day())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: router.tab)
        .accessibilityLabel(router.primaryCreateTitle)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
