import SwiftUI

struct GoalCard: View {
    let goal: Goal

    private var accent: Color { SovaTheme.current.accent.color }

    private var nextStep: String? {
        goal.sortedMilestones.first(where: { !$0.isDone })?.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(symbol: goal.symbol, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Group {
                        if let nextStep {
                            Text("Next: \(Text(nextStep).foregroundStyle(Color.inkSecondary))")
                        } else if goal.milestones.isEmpty {
                            Text("Tracked by feel")
                        } else {
                            Text("Every step done")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.inkTertiary)
                    .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(Int((goal.progress * 100).rounded()), format: .number)
                        .font(.hero(34))
                        .tracking(-1.4)
                        .contentTransition(.numericText(value: goal.progress))
                    Text("%").font(.callout.weight(.medium)).foregroundStyle(Color.inkTertiary)
                }
                .foregroundStyle(Color.ink)
            }

            ProgressLine(progress: goal.progress, color: accent, height: 4,
                         milestones: goal.sortedMilestones.map(\.isDone))
                .padding(.top, 22)

            HStack {
                Text(goal.milestones.isEmpty
                     ? String(localized: "No steps")
                     : String(localized: "\(goal.completedMilestones)/\(goal.milestones.count) steps"))
                Spacer()
                if let text = goal.deadlineText { Text(text) }
            }
            .font(.mono(10.5))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle((goal.daysLeft ?? 1) < 0 ? Color.danger : Color.inkTertiary)
            .padding(.top, 14)
        }
        .surface(cornerRadius: 24, padding: 20)
        .accessibilityElement(children: .combine)
    }
}
