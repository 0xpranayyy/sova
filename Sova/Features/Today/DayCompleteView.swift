import SwiftUI

/// Where the ring wave lands when the whole day is done: the night-indigo
/// stage, the owl exactly where it sat on Today, and the day's numbers.
///
/// The wave keeps hidden copies of this view mounted, so it plays no sound
/// and no haptic of its own; those already played when the last thing was
/// ticked.
struct DayCompleteView: View {
    let summary: DaySummary
    /// Where the owl sat on Today, in screen coordinates.
    let owlFrame: CGRect
    var onClose: () -> Void

    @AppStorage("userName") private var userName = ""
    @Environment(WaveDirector.self) private var waves

    private var farewell: String {
        userName.isEmpty ? String(localized: "See you tomorrow")
                         : String(localized: "See you tomorrow, \(userName)")
    }

    var body: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            let sat = CGPoint(x: owlFrame.midX - origin.x, y: owlFrame.midY - origin.y)
            // If Today was scrolled and the owl was off screen, it lands up top.
            let visible = owlFrame != .zero && (130...geo.size.height * 0.5).contains(sat.y)
            let owl = visible ? sat : CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.3)
            ZStack {
                StickerTone.indigo.fill

                // The ring, full now, around the owl in its place.
                Circle()
                    .stroke(StickerTone.yellow.fill, lineWidth: 15)
                    .frame(width: 172, height: 172)
                    .position(owl)
                OwlMark(size: 84, happy: true,
                        bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly,
                        reactsToTap: false)
                    .position(owl)

                SparkleDot(color: StickerTone.pink.fill, size: 18).position(x: owl.x + 118, y: owl.y - 62)
                SparkleDot(color: StickerTone.mint.fill, size: 15).position(x: owl.x - 124, y: owl.y + 40)
                SparkleDot(color: StickerTone.yellow.fill, size: 12).position(x: owl.x - 90, y: owl.y - 96)
                SparkleDot(color: StickerTone.lilac.fill, size: 10).position(x: owl.x + 96, y: owl.y + 92)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) { summaryPanel }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var summaryPanel: some View {
        VStack(spacing: 18) {
            Text("Day done!")
                .font(.hero(62, weight: .heavy))
                .tracking(-2.6)
                .foregroundStyle(StickerTone.yellow.fill)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                if summary.tasks > 0 {
                    TiltPill(text: String(localized: "\(summary.tasks) tasks done"), tone: .yellow, tilt: -4)
                }
                if summary.rituals > 0 {
                    TiltPill(text: String(localized: "\(summary.rituals) rituals kept"), tone: .mint, tilt: 3)
                }
                if summary.streak > 1 {
                    TiltPill(text: String(localized: "\(summary.streak)-day streak"), tone: .pink, tilt: -3)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(farewell)
                .font(.allo(.headline, .semibold))
                .foregroundStyle(Color.white.opacity(0.72))
                .multilineTextAlignment(.center)

            Button(action: onClose) {
                Text("Nice!")
            }
            .buttonStyle(.big(.yellow))
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 520)
        .padding(.bottom, max(waves.insets.bottom, 16) + 8)
    }
}

#Preview {
    DayCompleteView(summary: DaySummary(tasks: 4, rituals: 3, streak: 6),
                    owlFrame: CGRect(x: 154, y: 262, width: 84, height: 84)) {}
        .environment(WaveDirector())
}
