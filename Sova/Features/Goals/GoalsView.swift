import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Goal.createdAt) private var allGoals: [Goal]
    @Namespace private var zoom
    @State private var showArchived = false

    private var active: [Goal] { allGoals.filter { !$0.isArchived } }
    private var archived: [Goal] { allGoals.filter(\.isArchived) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if active.isEmpty {
                        EmptyState(title: String(localized: "Somewhere to aim"),
                                   message: String(localized: "Goals turn big ideas into small, finishable steps."),
                                   actionTitle: String(localized: "Set a goal")) { router.sheet = .newGoal }
                    } else {
                        ForEach(active) { goal in
                            NavigationLink(value: goal) { GoalCard(goal: goal) }
                                .buttonStyle(.pressable)
                                .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                        }
                    }

                    if !archived.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showArchived.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                SectionLabel(String(localized: "Archived"), trailing: "\(archived.count)")
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.inkSecondary)
                                    .rotationEffect(.degrees(showArchived ? 90 : 0))
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 18)

                        if showArchived {
                            ForEach(archived) { goal in
                                NavigationLink(value: goal) { GoalCard(goal: goal).opacity(0.6) }
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
            .navigationTitle("Goals")
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
                    .navigationTransition(.zoom(sourceID: goal.persistentModelID, in: zoom))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Goal", systemImage: "plus") { router.sheet = .newGoal }
                }
            }
        }
    }
}
