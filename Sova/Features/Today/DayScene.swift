import SwiftUI

/// The little flat scene behind Today's hero: two soft hills in the card's
/// own tints, and the sky for the part of the day. A rising sun at dawn,
/// a full sun in the morning, a cloud and a high sun in the afternoon, a
/// setting sun in the evening, and the moon with sparkles at night.
/// Sparkles stay on the right, away from the text.
struct DayScene: View {
    let part: DayPart
    let harmony: Harmony

    private static let yellow = StickerTone.yellow.fill

    var body: some View {
        Canvas { context, size in
            drawSky(&context, size)
            drawHills(&context, size)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawHills(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width, h = size.height
        var far = Path()
        far.move(to: CGPoint(x: 0, y: h - 64))
        far.addQuadCurve(to: CGPoint(x: w * 0.54, y: h - 72), control: CGPoint(x: w * 0.25, y: h - 102))
        far.addQuadCurve(to: CGPoint(x: w, y: h - 88), control: CGPoint(x: w * 0.8, y: h - 52))
        far.addLine(to: CGPoint(x: w, y: h))
        far.addLine(to: CGPoint(x: 0, y: h))
        far.closeSubpath()
        context.fill(far, with: .color(harmony.top))

        var near = Path()
        near.move(to: CGPoint(x: 0, y: h - 36))
        near.addQuadCurve(to: CGPoint(x: w * 0.65, y: h - 42), control: CGPoint(x: w * 0.33, y: h - 68))
        near.addQuadCurve(to: CGPoint(x: w, y: h - 46), control: CGPoint(x: w * 0.86, y: h - 20))
        near.addLine(to: CGPoint(x: w, y: h))
        near.addLine(to: CGPoint(x: 0, y: h))
        near.closeSubpath()
        context.fill(near, with: .color(harmony.pill))
    }

    private func drawSky(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width, h = size.height
        switch part {
        case .dawn:
            circle(&context, CGPoint(x: w * 0.67, y: h - 52), 64, Self.yellow.opacity(0.25))
            circle(&context, CGPoint(x: w * 0.67, y: h - 52), 50, Self.yellow)
        case .morning:
            circle(&context, CGPoint(x: w * 0.64, y: h * 0.42), 64, Color.white.opacity(0.28))
            circle(&context, CGPoint(x: w * 0.64, y: h * 0.42), 40, Self.yellow)
            sparkle(&context, CGPoint(x: w * 0.88, y: 40), 13, .white)
        case .afternoon:
            circle(&context, CGPoint(x: w * 0.85, y: 46), 26, Self.yellow)
            cloud(&context, CGPoint(x: w * 0.67, y: 80))
        case .evening:
            circle(&context, CGPoint(x: w * 0.69, y: h - 70), 58, StickerTone.orange.fill.opacity(0.25))
            circle(&context, CGPoint(x: w * 0.69, y: h - 70), 44, Self.yellow)
            sparkle(&context, CGPoint(x: w * 0.9, y: 36), 11, .white)
        case .night:
            // A crescent: the moon, with a circle of sky bitten out of it.
            circle(&context, CGPoint(x: w * 0.74, y: 64), 34, Self.yellow)
            circle(&context, CGPoint(x: w * 0.79, y: 54), 30, harmony.bg)
            sparkle(&context, CGPoint(x: w * 0.61, y: 34), 12, Self.yellow)
            sparkle(&context, CGPoint(x: w * 0.92, y: 116), 9, .white)
            sparkle(&context, CGPoint(x: w * 0.65, y: 108), 7, StickerTone.pink.fill)
            sparkle(&context, CGPoint(x: w * 0.94, y: 28), 7, StickerTone.mint.fill)
        }
    }

    private func circle(_ context: inout GraphicsContext, _ center: CGPoint, _ radius: CGFloat, _ color: Color) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                            width: radius * 2, height: radius * 2)), with: .color(color))
    }

    private func cloud(_ context: inout GraphicsContext, _ center: CGPoint) {
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - 34, y: center.y - 12, width: 68, height: 24))
        path.addEllipse(in: CGRect(x: center.x - 26, y: center.y - 23, width: 28, height: 28))
        path.addEllipse(in: CGRect(x: center.x - 9, y: center.y - 32, width: 36, height: 36))
        context.fill(path, with: .color(.white))
    }

    /// Sova's four-point sparkle.
    private func sparkle(_ context: inout GraphicsContext, _ center: CGPoint, _ radius: CGFloat, _ color: Color) {
        let r = radius, k = radius * 0.28
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - r))
        path.addCurve(to: CGPoint(x: center.x + r, y: center.y),
                      control1: CGPoint(x: center.x + k * 0.4, y: center.y - k), control2: CGPoint(x: center.x + k, y: center.y - k * 0.4))
        path.addCurve(to: CGPoint(x: center.x, y: center.y + r),
                      control1: CGPoint(x: center.x + k, y: center.y + k * 0.4), control2: CGPoint(x: center.x + k * 0.4, y: center.y + k))
        path.addCurve(to: CGPoint(x: center.x - r, y: center.y),
                      control1: CGPoint(x: center.x - k * 0.4, y: center.y + k), control2: CGPoint(x: center.x - k, y: center.y + k * 0.4))
        path.addCurve(to: CGPoint(x: center.x, y: center.y - r),
                      control1: CGPoint(x: center.x - k, y: center.y - k * 0.4), control2: CGPoint(x: center.x - k * 0.4, y: center.y - k))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }
}

/// "3 of 8 done" as eight rounded segments.
struct SegmentBar: View {
    let done: Int
    let total: Int
    let fill: Color
    let empty: Color

    var body: some View {
        let count: Int = max(min(total, 12), 1)
        let lit: Int = total <= 12 ? done : Int((Double(done) / Double(max(total, 1)) * 12).rounded())
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index < lit ? fill : empty)
                    .frame(height: 8)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: lit)
    }
}

/// The streak as a small white sticker: "🔥 12".
struct StreakSticker: View {
    let streak: Int

    var body: some View {
        Text("🔥 \(streak)")
            .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote).monospacedDigit())
            .foregroundStyle(StickerTone.indigo.fill)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.white, in: .capsule)
            .rotationEffect(.degrees(-5))
            .shadow(color: Color(hex: 0x120840).opacity(0.18), radius: 4, y: 2)
            .contentTransition(.numericText())
    }
}
