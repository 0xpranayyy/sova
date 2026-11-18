import SwiftUI

/// Sova's mascot. "Sova" means owl. It blinks now and then, can look
/// toward a point, and closes its eyes in a smile when something's done.
struct OwlMark: View {
    var size: CGFloat = 120
    /// -1…1 on each axis: where the pupils look.
    var look: CGSize = .zero
    var happy = false
    var blinks = true
    var bodyColor: Color = .ink
    var eyeColor: Color = .canvas

    @State private var blinking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let w = size, h = size * 1.08
        ZStack {
            OwlBody().fill(bodyColor)

            HStack(spacing: w * 0.04) {
                eye(w)
                eye(w)
            }
            .offset(y: h * 0.44 - h / 2)

            Beak()
                .fill(StickerTone.orange.fill)
                .frame(width: w * 0.11, height: w * 0.10)
                .offset(y: h * 0.62 - h / 2 + w * 0.05)
        }
        .frame(width: w, height: h)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: look)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: happy)
        .task(id: blinks) { await blinkLoop() }
        .accessibilityHidden(true)
    }

    private func eye(_ w: CGFloat) -> some View {
        ZStack {
            Circle().fill(eyeColor)
            if happy {
                HappyEye()
                    .stroke(bodyColor, style: StrokeStyle(lineWidth: w * 0.045, lineCap: .round))
                    .frame(width: w * 0.16, height: w * 0.07)
                    .offset(y: w * 0.01)
                    .transition(.scale(0.6).combined(with: .opacity))
            } else {
                ZStack(alignment: .topTrailing) {
                    Circle().fill(bodyColor)
                    Circle().fill(eyeColor).frame(width: w * 0.04, height: w * 0.04).offset(x: -w * 0.022, y: w * 0.022)
                }
                .frame(width: w * 0.15, height: w * 0.15)
                .offset(x: look.width * w * 0.06, y: look.height * w * 0.06 + w * 0.01)
                .transition(.scale(0.6).combined(with: .opacity))
            }
        }
        .frame(width: w * 0.31, height: w * 0.31)
        .scaleEffect(x: 1, y: blinking && !happy ? 0.08 : 1)
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

/// Two ear tufts and a soft round body.
struct OwlBody: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * w, y: r.minY + y * h) }
        var path = Path()
        path.move(to: p(0.10, 0.0))
        path.addQuadCurve(to: p(0.5, 0.17), control: p(0.30, 0.20))
        path.addQuadCurve(to: p(0.90, 0.0), control: p(0.70, 0.20))
        path.addCurve(to: p(0.5, 1.0), control1: p(1.10, 0.42), control2: p(1.02, 1.0))
        path.addCurve(to: p(0.10, 0.0), control1: p(-0.02, 1.0), control2: p(-0.10, 0.42))
        path.closeSubpath()
        return path
    }
}

struct Beak: Shape {
    func path(in r: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        path.closeSubpath()
        return path
    }
}

struct FeatherMarks: Shape {
    func path(in r: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.minY))
        path.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.minY + r.height * 0.6))
        path.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.maxY - r.height * 0.2))
        path.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.maxY - r.height * 0.2),
                          control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.2))
        return path
    }
}

/// A closed, smiling eye: an arch.
struct HappyEye: Shape {
    func path(in r: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.maxY))
        path.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.6))
        return path
    }
}

#Preview {
    HStack(spacing: 40) {
        OwlMark(size: 120)
        OwlMark(size: 120, happy: true)
    }
    .padding(40)
    .background(Color.canvas)
}
