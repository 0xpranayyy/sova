import SwiftUI

/// A happy wiggle when `trigger` changes: a quick swell and a shake that
/// settles. Shared by the ritual tiles and rows. Kept in its own modifier,
/// with every type spelled out, so the views using it type-check quickly.
struct Wiggle: ViewModifier {
    let trigger: Int
    var angle: Double = 1
    var swell: Double = 0.012

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: Double(0), trigger: trigger) { view, t in
            let value: Double = t
            let scale: CGFloat = CGFloat(1 + abs(value) * swell)
            let turn: Angle = .degrees(value * angle)
            view.scaleEffect(scale).rotationEffect(turn)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(Double(-5), duration: 0.09, spring: .snappy)
                SpringKeyframe(Double(4), duration: 0.1, spring: .snappy)
                SpringKeyframe(Double(-2), duration: 0.1, spring: .snappy)
                SpringKeyframe(Double(0), duration: 0.3, spring: Spring(response: 0.35, dampingRatio: 0.78))
            }
        }
    }
}

extension View {
    func wiggle(on trigger: Int, angle: Double = 1, swell: Double = 0.012) -> some View {
        modifier(Wiggle(trigger: trigger, angle: angle, swell: swell))
    }
}
