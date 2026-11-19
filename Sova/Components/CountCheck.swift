import SwiftUI

/// The check for a counted ritual ("Drink water, 8 a day"): a ring that
/// fills one step per tap with the count in the middle, turning into a
/// solid check once the target is reached.
struct CountCheck: View {
    let routine: Routine
    let ink: Color
    let fill: Color
    var size: CGFloat = 32
    let action: () -> Void

    var body: some View {
        let tally = routine.tally(on: .now)
        let target = max(routine.target, 1)
        let done = routine.isDone(on: .now)
        Button {
            action()
            if routine.isDone(on: .now) {
                Sounds.play(.check)
                Haptics.success()
            } else if routine.tally(on: .now) > 0 {
                Sounds.play(.tick)
                Haptics.pop(0.5)
            } else {
                Sounds.play(.uncheck)
            }
        } label: {
            ZStack {
                Circle().stroke(ink.opacity(0.22), lineWidth: size * 0.11)
                Circle()
                    .trim(from: 0, to: done ? 1 : Double(tally) / Double(target))
                    .stroke(ink, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if done {
                    Circle().fill(ink)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.42, weight: .black))
                        .foregroundStyle(fill)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(tally)")
                        .font(.allo(size: size * 0.44, weight: .heavy).monospacedDigit())
                        .contentTransition(.numericText(value: Double(tally)))
                }
            }
            .frame(width: size, height: size)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tally)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(routine.title)
        .accessibilityValue(done ? String(localized: "Done") : String(localized: "\(tally) of \(target)"))
        .accessibilityHint(done ? String(localized: "Tap to undo today") : String(localized: "Tap to add one"))
    }
}
