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
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    MonoCaps(goal.deadlineText ?? String(localized: "No deadline"),
                             color: (goal.daysLeft ?? 1) < 0 ? Color.ember : ink.opacity(0.75))
                    Text(goal.title)
                        .font(.allo(size: 25, weight: .heavy, relativeTo: .title2))
                        .tracking(-0.8)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                Spacer(minLength: 4)
                percent
            }

            StepBar(progress: goal.progress, steps: goal.sortedMilestones.map(\.isDone), color: tone.deep, height: 14)
                .padding(.top, 16)

            if let step = nextStep {
                nextRow(step).padding(.top, 14)
            } else {
                Text(goal.steps.isEmpty ? String(localized: "Progress set by hand")
                     : String(localized: "Every step done 🎉"))
                    .font(.allo(.subheadline, .heavy))
                    .opacity(0.75)
                    .padding(.top, 12)
            }

            if goal.isBehindPace {
                Text("🐢 \(String(localized: "Behind pace")) · \(paceTip)")
                    .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.5), in: .capsule)
                    .padding(.top, 12)
            }
        }
        .foregroundStyle(ink)
        .block(tone, cornerRadius: Radius.hero)
        .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 150, height: 110)) }
        .overlay(alignment: .topTrailing) {
            // The owl peeks over the first card.
            if number == 1 {
                OwlMark(size: 44, happy: goal.progress >= 0.5, bodyColor: StickerTone.yellow.fill,
                        eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, reactsToTap: false)
                    .offset(x: -12, y: -40)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The big number: "50%".
    private var percent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(Int((goal.progress * 100).rounded()), format: .number)
                .font(.hero(60, weight: .heavy))
                .tracking(-2.8)
                .contentTransition(.numericText(value: goal.progress))
            Text("%").font(.hero(26, weight: .heavy)).opacity(0.6)
        }
        .lineLimit(1)
        .fixedSize()
    }

    private func nextRow(_ step: Milestone) -> some View {
        HStack(spacing: 8) {
            CheckButton(isOn: false, color: tone.deep, round: true, size: 24, checkColor: tone.fill,
                        label: step.title) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { step.isDone = true }
                Haptics.pop(0.6, sound: true)
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
    }

    /// The owl's short tip for a goal that's behind.
    private var paceTip: String {
        if let step = nextStep { return String(localized: "try “\(step.title)” today") }
        return goal.steps.isEmpty ? String(localized: "add a few small steps") : String(localized: "one push today")
    }

    private var label: String {
        var parts: [String] = [goal.deadlineText ?? String(localized: "No deadline")]
        if !goal.steps.isEmpty {
            parts.append(String(localized: "\(goal.completedMilestones) of \(goal.steps.count) steps"))
        }
        return parts.joined(separator: " · ")
    }
}

/// "Behind pace": time is running ahead of progress on this goal.
struct BehindPacePill: View {
    let ink: Color

    var body: some View {
        Text("\(Image(systemName: "tortoise.fill")) \(String(localized: "Behind pace"))")
            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ink.opacity(0.14), in: .capsule)
            .rotationEffect(.degrees(-3))
            .lineLimit(1)
            .accessibilityLabel(String(localized: "Behind pace for the deadline"))
    }
}

