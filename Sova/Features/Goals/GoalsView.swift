import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Goal.createdAt) private var allGoals: [Goal]
    @Namespace private var zoom
    @State private var showArchived = false

    private var active: [Goal] { allGoals.filter { !$0.isArchived } }
    private var archived: [Goal] { allGoals.filter(\.isArchived) }

    private var averageProgress: Double {
        guard !active.isEmpty else { return 0 }
        return active.map(\.progress).reduce(0, +) / Double(active.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if active.isEmpty {
                        EmptyCard(symbol: "target",
                                  title: String(localized: "Dream a little"),
                                  message: String(localized: "Goals turn big ideas into small steps. Start with one."),
                                  actionTitle: String(localized: "Create a Goal")) { router.sheet = .newGoal }
                    } else {
                        overview
                        ForEach(active) { goal in
                            NavigationLink(value: goal) {
                                GoalCard(goal: goal)
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                        }
                    }

                    if !archived.isEmpty {
                        Button {
                            withAnimation(.snappy) { showArchived.toggle() }
                        } label: {
                            HStack {
                                SectionHeader(title: String(localized: "Archived"), symbol: "archivebox",
                                              trailing: "\(archived.count)")
                                Image(systemName: "chevron.down")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(showArchived ? 0 : -90))
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 12)

                        if showArchived {
                            ForEach(archived) { goal in
                                NavigationLink(value: goal) {
                                    GoalCard(goal: goal).opacity(0.75)
                                }
                                .buttonStyle(.plain)
                                .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background { AuroraBackground() }
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

    private var overview: some View {
        HStack(spacing: 0) {
            OverviewStat(value: "\(active.count)", label: String(localized: "Active"))
            Divider().frame(height: 36)
            OverviewStat(value: averageProgress.formatted(.percent.precision(.fractionLength(0))),
                         label: String(localized: "Avg. progress"))
            Divider().frame(height: 36)
            OverviewStat(value: "\(allGoals.filter { $0.progress >= 1 }.count)", label: String(localized: "Achieved"))
        }
        .card(cornerRadius: 24, padding: 14)
    }
}

private struct OverviewStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
