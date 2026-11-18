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
                    VStack(alignment: .leading, spacing: 18) {
                        MonoCaps(active.isEmpty ? String(localized: "No active goals")
                                 : String(localized: "\(active.count) active · \(averageText) average"))
                        Text("Goals")
                            .font(.hero(44, weight: .bold))
                            .tracking(-1.8)
                            .foregroundStyle(Color.ink)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 10)

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
                            HStack(spacing: 8) {
                                MonoCaps(String(localized: "Archived · \(archived.count)"))
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
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
            .toolbarTitleDisplayMode(.inline)
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
