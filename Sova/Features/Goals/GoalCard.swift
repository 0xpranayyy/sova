import SwiftUI

struct GoalCard: View {
    let goal: Goal
    var number: Int? = nil

    private var nextStep: String? {
        goal.sortedMilestones.first(where: { !$0.isDone })?.title
    }

    private var label: String {
        var parts: [String] = []
        if let number { parts.append(String(format: "%02d", number)) }
        if let deadline = goal.deadlineText { parts.append(deadline) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                MonoCaps(label, color: (goal.daysLeft ?? 1) < 0 ? .danger : .black.opacity(0.45))
                Spacer()
                MonoCaps(goal.milestones.isEmpty ? String(localized: "No steps")
                         : String(localized: "\(goal.completedMilestones)/\(goal.milestones.count) steps"))
            }

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.allo(size: 20, weight: .medium, relativeTo: .title3))
                        .tracking(-0.6)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(nextStep.map { String(localized: "Next: \($0)") }
                         ?? (goal.milestones.isEmpty ? String(localized: "Progress set by hand") : String(localized: "Every step done")))
                        .font(.allo(.subheadline))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(Int((goal.progress * 100).rounded()), format: .number)
                        .font(.hero(40, weight: .medium))
                        .tracking(-2)
                        .contentTransition(.numericText(value: goal.progress))
                    Text("%").font(.allo(.title3)).foregroundStyle(Color.inkTertiary)
                }
                .foregroundStyle(Color.ink)
            }
            .padding(.top, 12)

            ProgressLine(progress: goal.progress, color: .black, height: 3,
                         milestones: goal.sortedMilestones.map(\.isDone))
                .padding(.top, 18)
        }
        .surface(cornerRadius: 16, padding: 18)
        .accessibilityElement(children: .combine)
    }
}
