import SwiftUI

/// A goal as a block in its own color: a tilted icon, a big percentage,
/// one chunky segment per step, and the next step ready to tick off.
struct GoalCard: View {
    let goal: Goal
    var number: Int? = nil

    @State private var cheers = 0

    private var tone: StickerTone { StickerTone(goal.accent) }
    private var ink: Color { tone == .indigo ? .white : tone.deep }
    private var nextStep: Milestone? { goal.sortedMilestones.first(where: { !$0.isDone }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: goal.symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(tone == .indigo ? tone.deep : tone.fill)
                    .frame(width: 46, height: 46)
                    .background(tone == .indigo ? Color.white.opacity(0.15) : tone.deep,
                                in: .rect(cornerRadius: 15, style: .continuous))
                    .rotationEffect(.degrees(-5))
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Int((goal.progress * 100).rounded()), format: .number)
                        .font(.hero(52, weight: .heavy))
                        .tracking(-2.4)
                        .contentTransition(.numericText(value: goal.progress))
                    Text("%").font(.hero(24, weight: .heavy)).opacity(0.5)
                }
            }

            Text(goal.title)
                .font(.allo(size: 22, weight: .heavy, relativeTo: .title3))
                .tracking(-0.6)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.top, 6)

            MonoCaps(label, color: (goal.daysLeft ?? 1) < 0 ? Color.ember : ink.opacity(0.75))
                .padding(.top, 4)

            StepBar(progress: goal.progress, steps: goal.sortedMilestones.map(\.isDone),
                    color: tone == .indigo ? tone.deep : tone.deep)
                .padding(.top, 12)

            if let step = nextStep {
                HStack(spacing: 8) {
                    CheckButton(isOn: false, color: tone.deep, round: true, size: 24, checkColor: tone.fill,
                                label: step.title) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { step.isDone = true }
                        if goal.progress >= 1 {
                            cheers += 1
                            Haptics.celebrate()
                        }
                    }
                    .padding(.leading, -8)
                    Text("\(Text("Next · ").foregroundStyle(ink.opacity(0.6)))\(step.title)")
                        .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                        .foregroundStyle(ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .background(Color.white.opacity(tone == .indigo ? 0.12 : 0.55),
                            in: .rect(cornerRadius: 18, style: .continuous))
                .padding(.top, 14)
            } else {
                Text(goal.milestones.isEmpty ? String(localized: "Progress set by hand")
                     : String(localized: "Every step done 🎉"))
                    .font(.allo(.subheadline, .heavy))
                    .opacity(0.75)
                    .padding(.top, 12)
            }
        }
        .foregroundStyle(ink)
        .block(tone, cornerRadius: 32)
        .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 150, height: 110)) }
        .overlay(alignment: .topTrailing) {
            if goal.progress >= 0.7 {
                SparkleDot(color: .white, size: 20)
                    .padding(.top, 14)
                    .padding(.trailing, 70)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var label: String {
        var parts: [String] = [goal.deadlineText ?? String(localized: "No deadline")]
        if !goal.milestones.isEmpty {
            parts.append(String(localized: "\(goal.completedMilestones) of \(goal.milestones.count) steps"))
        }
        return parts.joined(separator: " · ")
    }
}
