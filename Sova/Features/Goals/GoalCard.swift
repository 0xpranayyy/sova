import SwiftUI

struct GoalCard: View {
    let goal: Goal
    var number: Int? = nil

    private var nextStep: String? {
        goal.sortedMilestones.first(where: { !$0.isDone })?.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                StickerIcon(symbol: goal.symbol, tone: StickerTone(goal.accent), size: 46, tilt: -4)
                VStack(alignment: .leading, spacing: 1) {
                    Text(goal.title)
                        .font(.allo(size: 17.5, weight: .heavy, relativeTo: .headline))
                        .tracking(-0.4)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(nextStep.map { String(localized: "Next: \($0)") }
                         ?? (goal.milestones.isEmpty ? String(localized: "Progress set by hand") : String(localized: "Every step done")))
                        .font(.allo(.footnote, .medium))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(Int((goal.progress * 100).rounded()), format: .number)
                        .font(.hero(34, weight: .heavy))
                        .tracking(-1.6)
                        .contentTransition(.numericText(value: goal.progress))
                    Text("%").font(.allo(.callout, .bold)).foregroundStyle(Color.inkTertiary)
                }
                .foregroundStyle(Color.ink)
            }

            ProgressLine(progress: goal.progress, color: .ember, height: 12,
                         milestones: Array(goal.sortedMilestones.map(\.isDone).dropLast()))
                .padding(.top, 16)

            HStack {
                Text(goal.milestones.isEmpty ? String(localized: "Set by hand")
                     : String(localized: "\(goal.completedMilestones) of \(goal.milestones.count) steps"))
                Spacer()
                if let deadline = goal.deadlineText { Text(deadline) }
            }
            .font(.allo(.caption, .bold))
            .foregroundStyle((goal.daysLeft ?? 1) < 0 ? Color.ember : Color.inkSecondary)
            .padding(.top, 10)
        }
        .surface(cornerRadius: 22, padding: 18)
        .accessibilityElement(children: .combine)
    }
}
