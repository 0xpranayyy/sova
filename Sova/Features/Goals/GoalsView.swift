import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Goal.createdAt) private var allGoals: [Goal]
    @Namespace private var zoom
    @State private var showArchived = false

    private var active: [Goal] { allGoals.filter { !$0.isArchived } }
    private var archived: [Goal] { allGoals.filter(\.isArchived) }

    private var averageText: String {
        let avg = active.isEmpty ? 0 : active.map(\.progress).reduce(0, +) / Double(active.count)
        return avg.formatted(.percent.precision(.fractionLength(0)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: String(localized: "Goals"),
                                subtitle: active.isEmpty ? String(localized: "Nothing in progress yet")
                                    : String(localized: "\(active.count) in progress · \(averageText) on average")) {
                        CircleAction(symbol: "plus", label: String(localized: "New goal")) { router.sheet = .newGoal }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                    if active.isEmpty {
                        EmptyState(title: String(localized: "No goals yet"),
                                   message: String(localized: "Add a goal and break it into steps you can check off."),
                                   actionTitle: String(localized: "Set a goal")) { router.sheet = .newGoal }
                    } else {
                        ForEach(Array(active.enumerated()), id: \.element.id) { index, goal in
                            NavigationLink(value: goal) { GoalCard(goal: goal, number: index + 1) }
                                .buttonStyle(.pressable)
                                .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                        }
                    }

                    if !archived.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showArchived.toggle() }
                        } label: {
                            HStack(spacing: 8) {
                                MonoCaps(String(localized: "Archived · \(archived.count)"))
                                Image(systemName: "chevron.right")
                                    .font(.allo(.caption2, .bold))
                                    .foregroundStyle(Color.inkTertiary)
                                    .rotationEffect(.degrees(showArchived ? 90 : 0))
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 18)

                        if showArchived {
                            ForEach(archived) { goal in
                                NavigationLink(value: goal) { GoalCard(goal: goal).opacity(0.5) }
                                    .buttonStyle(.pressable)
                                    .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
                    .toolbarVisibility(.visible, for: .navigationBar)
                    .navigationTransition(.zoom(sourceID: goal.persistentModelID, in: zoom))
            }
        }
    }
}
