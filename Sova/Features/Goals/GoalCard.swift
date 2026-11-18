import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                EmojiTile(emoji: goal.emoji, accent: goal.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(goal.accent.gradient)
                    .contentTransition(.numericText(value: goal.progress))
            }

            GradientProgressBar(progress: goal.progress, accent: goal.accent)

            if let deadline = goal.deadlineText {
                HStack(spacing: 6) {
                    MetaChip(text: deadline, symbol: "hourglass",
                             tint: (goal.daysLeft ?? 1) < 0 ? Accent.rose.color : goal.accent.color)
                    if let date = goal.deadline {
                        MetaChip(text: date.formatted(.dateTime.month(.abbreviated).day().year()), symbol: "flag.checkered")
                    }
                }
            }
        }
        .card(tint: goal.accent.color, cornerRadius: 28)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        if goal.milestones.isEmpty {
            return goal.progress >= 1 ? String(localized: "Complete") : String(localized: "Tracking manually")
        }
        return String(localized: "\(goal.completedMilestones) of \(goal.milestones.count) milestones")
    }
}

struct EmojiTile: View {
    let emoji: String
    let accent: Accent
    var size: CGFloat = 56

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(accent.gradient)
                    .opacity(0.28)
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(accent.color.opacity(0.35), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}
