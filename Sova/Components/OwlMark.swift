import SwiftUI

/// Sova's mascot. "Sova" means owl. A round little owl with a lighter
/// belly, wings, orange feet, pink cheeks and a sparkle in each eye. It
/// blinks now and then, can look toward a point, and closes its eyes in a
/// smile when something's done.
///
/// Drawn in a 128 × 132 unit space; `size` is the width of the body.
struct OwlMark: View {
    var size: CGFloat = 120
    /// -1…1 on each axis: where the pupils look.
    var look: CGSize = .zero
    var happy = false
    var blinks = true
    var bodyColor: Color = StickerTone.indigo.fill
    var eyeColor: Color = StickerTone.yellow.fill
    var pupilColor: Color? = nil
    var bellyColor: Color? = nil
    var beakColor: Color = StickerTone.orange.fill
    var cheekColor: Color = StickerTone.pink.fill

    @State private var blinking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pupil: Color { pupilColor ?? bodyColor }

    var body: some View {
        let width = size * 1.28
        let height = size * 1.32
        ZStack {
            // Feet and wings sit behind the body.
            OwlPart { p, at, _ in
                p.addEllipse(in: rect(at, 38, 119, 9, 5))
                p.addEllipse(in: rect(at, 62, 119, 9, 5))
            }
            .fill(beakColor)
            OwlPart { p, at, _ in
                p.move(to: at(-6, 66)); p.addQuadCurve(to: at(8, 104), control: at(-12, 92))
                p.addQuadCurve(to: at(6, 66), control: at(4, 84)); p.closeSubpath()
                p.move(to: at(106, 66)); p.addQuadCurve(to: at(92, 104), control: at(112, 92))
                p.addQuadCurve(to: at(94, 66), control: at(96, 84)); p.closeSubpath()
            }
            .fill(bodyColor)
            OwlPart { p, at, _ in
                p.move(to: at(10, 0))
                p.addQuadCurve(to: at(50, 18.4), control: at(30, 21.6))
                p.addQuadCurve(to: at(90, 0), control: at(70, 21.6))
                p.addCurve(to: at(50, 116), control1: at(110, 45.4), control2: at(104, 116))
                p.addCurve(to: at(10, 0), control1: at(-4, 116), control2: at(-10, 45.4))
                p.closeSubpath()
            }
            .fill(bodyColor)

            // Belly with two rows of feathers.
            OwlPart { p, at, _ in p.addEllipse(in: rect(at, 50, 90, 25, 22)) }
                .fill(bellyColor ?? Color.white.opacity(0.16))
            OwlPart { p, at, _ in
                p.move(to: at(40, 84)); p.addQuadCurve(to: at(50, 84), control: at(45, 88))
                p.addQuadCurve(to: at(60, 84), control: at(55, 88))
                p.move(to: at(43, 95)); p.addQuadCurve(to: at(50, 95), control: at(46.5, 98.5))
                p.addQuadCurve(to: at(57, 95), control: at(53.5, 98.5))
            }
            .stroke(bodyColor.opacity(0.4), style: StrokeStyle(lineWidth: size * 0.024, lineCap: .round))

            // Cheeks and beak.
            OwlPart { p, at, _ in
                p.addEllipse(in: rect(at, 14, 63, 6, 6))
                p.addEllipse(in: rect(at, 86, 63, 6, 6))
            }
            .fill(cheekColor.opacity(0.85))
            OwlPart { p, at, _ in
                p.move(to: at(44, 62)); p.addLine(to: at(56, 62)); p.addLine(to: at(50, 72)); p.closeSubpath()
            }
            .fill(beakColor)

            // Eyes.
            ZStack {
                OwlPart { p, at, _ in
                    p.addEllipse(in: rect(at, 30, 47, 17, 17))
                    p.addEllipse(in: rect(at, 70, 47, 17, 17))
                }
                .fill(eyeColor)
                if happy {
                    OwlPart { p, at, _ in
                        for cx in [30.0, 70.0] {
                            p.move(to: at(cx - 9, 51)); p.addQuadCurve(to: at(cx + 9, 51), control: at(cx, 39))
                        }
                    }
                    .stroke(pupil, style: StrokeStyle(lineWidth: size * 0.055, lineCap: .round))
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    let dx = look.width * 4
                    let dy = look.height * 4
                    OwlPart { p, at, _ in
                        p.addEllipse(in: rect(at, 31.5 + dx, 49 + dy, 8.5, 8.5))
                        p.addEllipse(in: rect(at, 71.5 + dx, 49 + dy, 8.5, 8.5))
                    }
                    .fill(pupil)
                    OwlPart { p, at, _ in
                        p.addEllipse(in: rect(at, 34.5 + dx, 45.5 + dy, 2.8, 2.8))
                        p.addEllipse(in: rect(at, 74.5 + dx, 45.5 + dy, 2.8, 2.8))
                    }
                    .fill(eyeColor)
                }
            }
            .scaleEffect(x: 1, y: blinking && !happy ? 0.1 : 1, anchor: UnitPoint(x: 0.5, y: 51.0 / 132.0))
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: look)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: happy)
        .task(id: blinks) { await blinkLoop() }
        .accessibilityHidden(true)
    }

    private func blinkLoop() async {
        guard blinks, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.4...5.5)))
            withAnimation(.easeIn(duration: 0.07)) { blinking = true }
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.easeOut(duration: 0.14)) { blinking = false }
        }
    }
}

/// A unit-space rectangle centered on (cx, cy) with radii (rx, ry).
private func rect(_ at: (CGFloat, CGFloat) -> CGPoint, _ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGRect {
    let a = at(cx - rx, cy - ry), b = at(cx + rx, cy + ry)
    return CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)
}

/// One piece of the owl, drawn in the 128 × 132 unit space.
private struct OwlPart: Shape {
    let draw: (inout Path, (CGFloat, CGFloat) -> CGPoint, CGFloat) -> Void

    func path(in r: CGRect) -> Path {
        let s = r.width / 128
        var path = Path()
        draw(&path, { x, y in CGPoint(x: r.minX + (x + 14) * s, y: r.minY + (y + 4) * s) }, s)
        return path
    }
}

/// Allo's four-point sparkle.
struct Sparkle: Shape {
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let w = r.width / 2, h = r.height / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + x * w, y: c.y + y * h) }
        var path = Path()
        path.move(to: p(0, -1))
        path.addCurve(to: p(1, 0), control1: p(0.12, -0.28), control2: p(0.28, -0.12))
        path.addCurve(to: p(0, 1), control1: p(0.28, 0.12), control2: p(0.12, 0.28))
        path.addCurve(to: p(-1, 0), control1: p(-0.12, 0.28), control2: p(-0.28, 0.12))
        path.addCurve(to: p(0, -1), control1: p(-0.28, -0.12), control2: p(-0.12, -0.28))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack(spacing: 30) {
        OwlMark(size: 100)
        OwlMark(size: 100, happy: true, bodyColor: StickerTone.yellow.fill,
                eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill)
    }
    .padding(40)
}
