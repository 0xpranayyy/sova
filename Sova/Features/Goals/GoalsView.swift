import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Goal.createdAt) private var allGoals: [Goal]
    @Namespace private var zoom
    @State private var path: [Goal] = []
    @State private var showArchived = false

    private var active: [Goal] { allGoals.filter { !$0.isArchived } }
    private var archived: [Goal] { allGoals.filter(\.isArchived) }
    private var average: Double {
        active.isEmpty ? 0 : active.map(\.progress).reduce(0, +) / Double(active.count)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenTitle(title: String(localized: "Goals"),
                                subtitle: active.isEmpty ? String(localized: "Nothing in progress")
                                    : String(localized: "\(active.count) in progress")) {
                        CircleAction(symbol: "plus", label: String(localized: "New goal")) { router.sheet = .newGoal }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)

                    if active.isEmpty {
                        EmptyState(title: String(localized: "No goals yet"),
                                   message: String(localized: "Add a goal and break it into steps you can check off."),
                                   actionTitle: String(localized: "Set a goal")) { router.sheet = .newGoal }
                    } else {
                        GoalsStage(average: average, count: active.count,
                                   achieved: allGoals.filter { $0.progress >= 1 }.count)
                        ForEach(Array(active.enumerated()), id: \.element.id) { index, goal in
                            GoalCard(goal: goal, number: index + 1)
                                .contentShape(.rect)
                                .onTapGesture { path.append(goal) }
                                .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                        }
                    }

                    if !archived.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showArchived.toggle() }
                        } label: {
                            HStack(spacing: 8) {
                                SectionLabel(String(localized: "Archived · \(archived.count)"))
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(Color.inkTertiary)
                                    .rotationEffect(.degrees(showArchived ? 90 : 0))
                                Spacer()
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)

                        if showArchived {
                            ForEach(archived) { goal in
                                GoalCard(goal: goal)
                                    .opacity(0.5)
                                    .contentShape(.rect)
                                    .onTapGesture { path.append(goal) }
                                    .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
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

/// The season at a glance: the average on indigo, with the owl.
struct GoalsStage: View {
    let average: Double
    let count: Int
    let achieved: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            StickerTone.indigo.fill

            VStack(alignment: .leading, spacing: 4) {
                MonoCaps(String(localized: "This season"), color: StickerTone.indigo.deep)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Int((average * 100).rounded()), format: .number)
                        .font(.hero(64, weight: .heavy))
                        .tracking(-3)
                        .contentTransition(.numericText(value: average))
                    Text("%").font(.hero(28, weight: .heavy)).opacity(0.6)
                }
                .foregroundStyle(StickerTone.indigo.deep)
                Text(count == 1 ? String(localized: "across 1 goal") : String(localized: "average across \(count) goals"))
                    .font(.allo(.subheadline, .heavy))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(20)

            HStack(alignment: .top, spacing: 0) {
                Spacer()
                if achieved > 0 {
                    TiltPill(text: String(localized: "\(achieved) done 🏆"), tone: .mint, tilt: -8, size: 13)
                        .padding(.top, 18)
                        .padding(.trailing, -4)
                        .zIndex(1)
                }
                OwlMark(size: 74, bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8))
                    .rotationEffect(.degrees(6))
                    .padding(.top, 20)
                    .padding(.trailing, 16)
            }

            SparkleDot(color: StickerTone.pink.fill, size: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 44)
                .padding(.bottom, 14)
        }
        .frame(height: 150)
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("This season")
        .accessibilityValue(String(localized: "\(Int((average * 100).rounded())) percent average across \(count) goals"))
    }
}
