import SwiftUI

/// A counted ritual, like 8 glasses of water: turn the Digital Crown or tap
/// +1 to log one more.
struct RitualDetail: View {
    let ritualID: String
    @Environment(WatchStore.self) private var store
    @State private var crown: Double = 0

    private var ritual: WatchRitual? { store.day.rituals.first { $0.id == ritualID } }

    var body: some View {
        if let ritual {
            let tone = WatchTone(name: ritual.tone)
            VStack(spacing: 8) {
                ZStack {
                    Circle().stroke(tone.fill.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: max(0.001, Double(ritual.tally) / Double(max(ritual.target, 1))))
                        .stroke(tone.fill, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Image(systemName: ritual.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(tone.fill)
                        Text("\(ritual.tally)")
                            .font(.sova(34, .heavy, relativeTo: .largeTitle))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("of \(ritual.target)")
                            .font(.sova(12, .bold, relativeTo: .caption))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(width: 112, height: 112)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: ritual.tally)

                Button {
                    store.tapRitual(ritual.id)
                    crown = Double(ritual.done ? 0 : ritual.tally + 1)
                } label: {
                    Text(ritual.done ? String(localized: "Done! Start over") : "+1")
                        .font(.sova(16, .heavy, relativeTo: .headline))
                        .foregroundStyle(tone.deep)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(tone.fill)
            }
            .navigationTitle(ritual.title)
            .focusable()
            .digitalCrownRotation($crown, from: 0, through: Double(ritual.target), by: 1,
                                  sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
            .onAppear { crown = Double(ritual.tally) }
            .onChange(of: crown) { _, value in
                // Turning forward logs one more each notch; turning back does
                // nothing (only the iPhone takes taps away).
                let wanted = Int(value.rounded())
                guard let current = self.ritual, !current.done, wanted > current.tally else {
                    if let current = self.ritual { crown = Double(current.tally) }
                    return
                }
                store.tapRitual(current.id)
            }
        } else {
            Text("This ritual isn't on today anymore.")
                .font(.sova(14, .bold))
                .multilineTextAlignment(.center)
        }
    }
}
