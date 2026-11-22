import SwiftUI

/// The weekly review at the top of Insights on Sundays and Mondays: the
/// owl's note on your week, the numbers, the slip, and a close button.
struct WeeklyReviewCard: View {
    let review: WeeklyReview
    var onClose: () -> Void

    @State private var note: String?

    private let tone = StickerTone.yellow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                MonoCaps(String(localized: "Your week"), color: tone.deep)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(tone.deep)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.45), in: .circle)
                        .contentShape(Circle().inset(by: -8))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(String(localized: "Hide this week's review"))
            }

            HStack(alignment: .top, spacing: 12) {
                OwlMark(size: 44, happy: true, bodyColor: StickerTone.indigo.fill, eyeColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, reactsToTap: false)
                    .rotationEffect(.degrees(-6))
                    .accessibilityHidden(true)
                Text(note ?? review.template)
                    .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.3)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .redacted(reason: note == nil && StepSuggester.isAvailable ? .placeholder : [])
            }
            .padding(.top, 10)

            HStack(spacing: 8) {
                stat("\(review.tasksDone)", String(localized: "Tasks"))
                stat("\(review.checkIns)", String(localized: "Check-ins"))
                stat("\(review.bestStreak)", String(localized: "Best streak"))
            }
            .padding(.top, 14)

            if let slip = review.slip {
                let line: String = String(localized: "\(slip) · kept \(review.slipKept) of \(review.slipScheduled) days")
                Label(line, systemImage: "arrow.down.right")
                    .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.45), in: .capsule)
                    .padding(.top, 12)
            }
        }
        .block(tone, cornerRadius: Radius.hero)
        .animation(.smooth(duration: 0.3), value: note)
        .task(id: review) {
            guard StepSuggester.isAvailable else { return }
            note = await review.phrased()
        }
        .accessibilityElement(children: .contain)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.hero(24, weight: .heavy).monospacedDigit())
                .tracking(-0.8)
            Text(label)
                .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2))
                .opacity(0.7)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.45), in: .rect(cornerRadius: Radius.small, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
