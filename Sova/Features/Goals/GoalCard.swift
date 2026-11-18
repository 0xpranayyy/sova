import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                IconTile(symbol: goal.symbol, accent: goal.accent, size: 46, filled: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    MetaLine(parts: meta)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                ProgressLine(progress: goal.progress, color: goal.accent.color, height: 8)
                Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(goal.accent.color)
                    .contentTransition(.numericText(value: goal.progress))
                    .frame(minWidth: 36, alignment: .trailing)
            }
        }
        .surface(cornerRadius: 26, padding: 18, interactive: true)
        .accessibilityElement(children: .combine)
    }

    private var meta: [MetaLine.Part] {
        var parts: [MetaLine.Part] = []
        if !goal.milestones.isEmpty {
            parts.append(.init(text: String(localized: "\(goal.completedMilestones) of \(goal.milestones.count) steps")))
        }
        if let text = goal.deadlineText {
            parts.append(.init(text: text, color: (goal.daysLeft ?? 1) < 0 ? Accent.ember.color : .inkSecondary))
        }
        if parts.isEmpty {
            parts.append(.init(text: goal.progress >= 1 ? String(localized: "Achieved") : String(localized: "No deadline")))
        }
        return parts
    }
}
