import SwiftUI

/// The welcome's giant owl face: two big eyes whose pupils follow your
/// finger, an idle blink, and a happy squint when you tap it. Flat shapes in
/// Sova's sticker colors, sized from the space it's given.
struct OwlFace: View {
    /// Where to look, -1…1 on each axis (from the onboarding drag).
    var look: CGSize

    @State private var blink = false
    @State private var happy = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let yellow = StickerTone.yellow.fill
    private let ear = Color(hex: 0xF5D820)
    private let indigo = StickerTone.indigo.fill

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            ZStack {
                yellow
                ears(w: w)
                belly(w: w, h: h)
                cheeks(w: w, h: h)
                beak(w: w, h: h)
                eye(at: CGPoint(x: w * 0.3, y: h * 0.5), radius: w * 0.235)
                eye(at: CGPoint(x: w * 0.7, y: h * 0.5), radius: w * 0.235)
            }
        }
        .clipShape(.rect(cornerRadius: 44, style: .continuous))
        .contentShape(.rect(cornerRadius: 44, style: .continuous))
        .onTapGesture(perform: squint)
        .task { await idleBlinks() }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Sova the owl, waving hello"))
    }

    // MARK: Parts

    private func ears(w: CGFloat) -> some View {
        Canvas { context, _ in
            var left = Path()
            left.move(to: CGPoint(x: -w * 0.05, y: 0))
            left.addLine(to: CGPoint(x: w * 0.16, y: 0))
            left.addLine(to: CGPoint(x: w * 0.3, y: w * 0.3))
            left.closeSubpath()
            var right = Path()
            right.move(to: CGPoint(x: w * 1.05, y: 0))
            right.addLine(to: CGPoint(x: w * 0.84, y: 0))
            right.addLine(to: CGPoint(x: w * 0.7, y: w * 0.3))
            right.closeSubpath()
            context.fill(left, with: .color(ear))
            context.fill(right, with: .color(ear))
        }
        .allowsHitTesting(false)
    }

    private func belly(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(Color.owlBelly)
            .frame(width: w * 0.78, height: w * 0.56)
            .position(x: w / 2, y: h + w * 0.1)
    }

    private func cheeks(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Circle().fill(StickerTone.pink.fill.opacity(0.8))
                .frame(width: w * 0.14, height: w * 0.14)
                .position(x: w * 0.1, y: h * 0.75)
            Circle().fill(StickerTone.pink.fill.opacity(0.8))
                .frame(width: w * 0.14, height: w * 0.14)
                .position(x: w * 0.9, y: h * 0.75)
        }
        .scaleEffect(happy ? 1.12 : 1)
    }

    private func beak(w: CGFloat, h: CGFloat) -> some View {
        Canvas { context, _ in
            var p = Path()
            p.move(to: CGPoint(x: w * 0.43, y: h * 0.72))
            p.addLine(to: CGPoint(x: w * 0.57, y: h * 0.72))
            p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.72 + w * 0.12))
            p.closeSubpath()
            context.fill(p, with: .color(StickerTone.orange.fill))
        }
        .allowsHitTesting(false)
    }

    /// One eye: the indigo ring, a yellow pupil that follows `look`, a white
    /// glint, and a lid that closes for a blink. Happy eyes are smiling arcs.
    @ViewBuilder
    private func eye(at center: CGPoint, radius r: CGFloat) -> some View {
        let travel: CGFloat = r * 0.4
        let dx: CGFloat = max(-1, min(1, look.width)) * travel
        let dy: CGFloat = (max(-1, min(1, look.height)) - 0.2) * travel
        ZStack {
            Circle().fill(indigo)
            if happy {
                SmileArc()
                    .stroke(yellow, style: StrokeStyle(lineWidth: r * 0.2, lineCap: .round))
                    .frame(width: r * 1.1, height: r * 0.5)
                    .offset(y: -r * 0.05)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                ZStack {
                    Circle().fill(yellow).frame(width: r * 0.84, height: r * 0.84)
                    Circle().fill(Color.white).frame(width: r * 0.26, height: r * 0.26)
                        .offset(x: r * 0.17, y: -r * 0.17)
                }
                .offset(x: dx, y: dy)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: look)
                // The lid: yellow, sliding down over the eye for a blink.
                Rectangle().fill(yellow)
                    .frame(height: r * 2)
                    .offset(y: blink ? 0 : -r * 2)
                    .clipShape(Circle())
            }
        }
        .frame(width: r * 2, height: r * 2)
        .position(center)
    }

    // MARK: Behaviour

    private func squint() {
        Haptics.owl()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { happy = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { happy = false }
        }
    }

    private func idleBlinks() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 2600...4800)))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.07)) { blink = true }
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.easeOut(duration: 0.12)) { blink = false }
        }
    }
}

/// A smiling eye: an upward arc.
private struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
        return p
    }
}
