import SwiftUI

/// A goal as a block in its own color: deadline, name, next step, a big
/// percentage and one chunky segment per step.
struct GoalCard: View {
    let goal: Goal
    var number: Int? = nil

    private var tone: StickerTone { StickerTone(goal.accent) }
    private var ink: Color { tone == .indigo ? .white : tone.deep }

    private var nextStep: String? {
        goal.sortedMilestones.first(where: { !$0.isDone })?.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                MonoCaps(goal.deadlineText ?? String(localized: "No deadline"),
                         color: (goal.daysLeft ?? 1) < 0 ? Color.ember : ink)
                Spacer()
                Image(systemName: goal.symbol)
                    .font(.system(size: 20, weight: .semibold))
            }
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.allo(size: 22, weight: .heavy, relativeTo: .title3))
                        .tracking(-0.6)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(nextStep.map { String(localized: "Next: \($0)") }
                         ?? (goal.milestones.isEmpty ? String(localized: "Progress set by hand") : String(localized: "Every step done")))
                        .font(.allo(.subheadline, .bold))
                        .opacity(0.7)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Int((goal.progress * 100).rounded()), format: .number)
                        .font(.hero(52, weight: .heavy))
                        .tracking(-2.4)
                        .contentTransition(.numericText(value: goal.progress))
                    Text("%").font(.hero(24, weight: .heavy)).opacity(0.5)
                }
            }
            .padding(.top, 10)
            StepBar(progress: goal.progress, steps: goal.sortedMilestones.map(\.isDone),
                    color: tone == .indigo ? tone.deep : tone.deep)
                .padding(.top, 14)
        }
        .foregroundStyle(ink)
        .block(tone)
        .accessibilityElement(children: .combine)
    }
}
