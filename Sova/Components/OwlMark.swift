import SwiftUI

/// Sova's mascot. "Sova" means owl. A round little owl with a lighter
/// belly, wings, orange feet, pink cheeks and a sparkle in each eye.
///
/// It's alive on one clock (the Motion engine, see `Sova/Support/Motion.swift`
/// and `Sova/Components/MOTION.md`): it breathes, glances around and blinks on
/// each glance, sways its wings out of step, and tilts a little. Nothing ever
/// swaps drawings: the pupils slide inside the eyes, the lids are feathers that
/// lower and rise, and "happy" is the cheeks pushing up into a smiling squint.
/// A celebration is acted: crouch, jump, wings out, land with a squash, settle.
///
/// Drawn in a 128 × 132 unit space; `size` is the width of the body.
struct OwlMark: View {
    var size: CGFloat = 120
    /// -1…1 on each axis: where the pupils look. Leave at zero to let the
    /// owl glance around on its own.
    var look: CGSize = .zero
    var happy = false
    var blinks = true
    /// Indigo with yellow eyes by day; a glowing yellow night owl after dark.
    var bodyColor: Color = Color(light: 0x2B1677, dark: 0xFFE94D)
    var eyeColor: Color = Color(light: 0xFFE94D, dark: 0x2B1677)
    var pupilColor: Color? = nil
    var bellyColor: Color? = nil
    var beakColor: Color = StickerTone.orange.fill
    var cheekColor: Color = StickerTone.pink.fill
    /// Change this to make the owl hop and flap (a celebration).
    var celebrate: Int = 0
    /// Whether tapping the owl gets a reaction. Off for tiny owls.
    var reactsToTap = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()
    @State private var onScreen = false
    /// A hop in progress, and how many wing flaps go with it.
    @State private var hopAt: Date?
    @State private var flaps = 0
    /// Tapped: a short giggle, eyes squinting happily.
    @State private var giggleUntil: Date?
    /// When `happy` (or a giggle) last changed, to morph the eyes, never swap them.
    @State private var happyFrom = 0.0
    @State private var happyTo = 0.0
    @State private var happyChangedAt = Date.distantPast
    /// When the owl started or stopped following `look`.
    @State private var lookActiveChangedAt = Date.distantPast

    /// Tiny owls are decoration: they stay still (often seen, barely moves).
    private var alive: Bool { size >= 30 }
    private var pupil: Color { pupilColor ?? bodyColor }

    var body: some View {
        let still = reduceMotion || !onScreen || scenePhase != .active || !alive
        let width = size * 1.28, height = size * 1.32
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: still && hopAt == nil)) { context in
            let now = context.date
            Canvas { ctx, _ in draw(&ctx, at: now, still: still) }
        }
        .frame(width: width, height: height)
        .contentShape(.rect)
        .onTapGesture { if reactsToTap && size >= 40 { poke() } }
        .onChange(of: celebrate) { cheer() }
        .onChange(of: happy, initial: true) { _, isHappy in setHappy(isHappy ? 1 : 0) }
        .onChange(of: look == .zero) { lookActiveChangedAt = Date() }
        .onAppear { onScreen = true }
        .onDisappear { onScreen = false }
        .accessibilityHidden(true)
    }

    // MARK: Choreography (ms)

    /// One idle loop. Glances glide in ~500 ms and hold; the owl blinks on
    /// each glance and once in between. Blinks close in 110 ms, hold 40 ms and
    /// reopen in 190 ms with an ease-out.
    private static let period = 9000.0
    private static let lookX: Keys = [Key(0, 0), Key(1800, 0), Key(2300, -0.8), Key(3600, -0.8), Key(4100, 0),
                                      Key(6000, 0), Key(6500, 0.7), Key(7600, 0.7), Key(8100, 0), Key(period, 0)]
    private static let lookY: Keys = [Key(0, 0), Key(1800, 0), Key(2300, 0.25), Key(3600, 0.25), Key(4100, 0),
                                      Key(6000, 0), Key(6500, -0.35), Key(7600, -0.35), Key(8100, 0), Key(period, 0)]
    private static let lid: Keys = {
        var keys: Keys = [Key(0, 0)]
        for b in [1760.0, 4800.0, 5960.0, 8060.0, 8400.0] {
            keys += [Key(b, 0), Key(b + 110, 1), Key(b + 150, 1), Key(b + 340, 0, out: true)]
        }
        return keys + [Key(period, 0)]
    }()
    /// The hop, as acting (`flow` passes through the poses without stopping).
    private static let hopMs = 900.0
    private static let hopSquash: FlowKeys = [(0, 1), (100, 0.9), (220, 1.08), (380, 1.0), (520, 1.05), (580, 0.83), (720, 1.04), (900, 1)]
    private static let hopLift: FlowKeys = [(0, 0), (100, 0), (220, -0.13), (380, -0.2), (520, 0), (900, 0)]
    private static let hopTilt: FlowKeys = [(0, 0), (100, -2), (220, 3), (380, 2), (520, 0), (720, -1), (900, 0)]

    /// This owl's own phase, so two owls on screen never blink together.
    private var phase: Double { seeded(Int(size * 7), salt: 0.3) * Self.period }

    // MARK: Drawing

    private func draw(_ ctx: inout GraphicsContext, at now: Date, still: Bool) {
        let ms = now.timeIntervalSince(start) * 1000
        let t = still ? 0 : (ms + phase).truncatingRemainder(dividingBy: Self.period)

        // Happy: the morph between eyes and smile (ease-out, 260 ms).
        let giggling = giggleUntil.map { now < $0 } ?? false
        let hp = reduceMotion ? 1 : min(1, now.timeIntervalSince(happyChangedAt) / 0.26)
        var smile = happyFrom + (happyTo - happyFrom) * easeOut.value(at: hp)
        if giggling { smile = 1 }

        // The hop and the flaps.
        var sy = 1.0, lift = 0.0, tilt = still ? 0 : 1.5 * wave(t, period: 4700)
        var flapL = 0.0, flapR = 0.0
        if let hopAt {
            let h = now.timeIntervalSince(hopAt) * 1000
            if h < Self.hopMs {
                sy = flow(h, Self.hopSquash); lift = flow(h, Self.hopLift) * 100; tilt += flow(h, Self.hopTilt)
                for i in 0..<flaps {
                    flapL = max(flapL, 28 * wingPulse(h - 120 - Double(i) * 240))
                    flapR = max(flapR, 26 * wingPulse(h - 160 - Double(i) * 240))
                }
            } else {
                DispatchQueue.main.async { self.hopAt = nil }
            }
        }
        // Breathing: about 1.8% taller from the feet, every 3.6 s.
        let breath = still ? 0 : 0.009 * (wave(t, period: 3600) + 1)
        let sx = 1 / pow(sy, 0.6)          // squash keeps the volume
        let swayL = still ? 0 : 2 * wave(t, period: 3100)
        let swayR = still ? 0 : 1.6 * wave(t, period: 3700, phase: 0.3)

        // Owl units: x −14…114, y −4…128.
        let s = size / 100
        ctx.translateBy(x: 14 * s, y: 4 * s)
        ctx.scaleBy(x: s, y: s)
        // Everything moves from the feet: lift, tilt, squash and breath.
        ctx.translateBy(x: 50, y: 119 + lift)
        ctx.rotate(by: .degrees(tilt))
        ctx.scaleBy(x: sx, y: sy * (1 + breath))
        ctx.translateBy(x: -50, y: -119)

        // Feet.
        ctx.fill(Path(ellipseIn: CGRect(x: 29, y: 114, width: 18, height: 10)), with: .color(beakColor))
        ctx.fill(Path(ellipseIn: CGRect(x: 53, y: 114, width: 18, height: 10)), with: .color(beakColor))

        // Wings, hinged at the shoulders; the right one trails the left.
        var left = Path()
        left.move(to: CGPoint(x: -6, y: 66)); left.addQuadCurve(to: CGPoint(x: 8, y: 104), control: CGPoint(x: -12, y: 92))
        left.addQuadCurve(to: CGPoint(x: 6, y: 66), control: CGPoint(x: 4, y: 84)); left.closeSubpath()
        var right = Path()
        right.move(to: CGPoint(x: 106, y: 66)); right.addQuadCurve(to: CGPoint(x: 92, y: 104), control: CGPoint(x: 112, y: 92))
        right.addQuadCurve(to: CGPoint(x: 94, y: 66), control: CGPoint(x: 96, y: 84)); right.closeSubpath()
        var wl = ctx
        wl.translateBy(x: 6, y: 66); wl.rotate(by: .degrees(swayL + flapL)); wl.translateBy(x: -6, y: -66)
        wl.fill(left, with: .color(bodyColor))
        var wr = ctx
        wr.translateBy(x: 94, y: 66); wr.rotate(by: .degrees(-(swayR + flapR))); wr.translateBy(x: -94, y: -66)
        wr.fill(right, with: .color(bodyColor))

        // Body, belly and two rows of feathers.
        var figure = Path()
        figure.move(to: CGPoint(x: 10, y: 0))
        figure.addQuadCurve(to: CGPoint(x: 50, y: 18.4), control: CGPoint(x: 30, y: 21.6))
        figure.addQuadCurve(to: CGPoint(x: 90, y: 0), control: CGPoint(x: 70, y: 21.6))
        figure.addCurve(to: CGPoint(x: 50, y: 116), control1: CGPoint(x: 110, y: 45.4), control2: CGPoint(x: 104, y: 116))
        figure.addCurve(to: CGPoint(x: 10, y: 0), control1: CGPoint(x: -4, y: 116), control2: CGPoint(x: -10, y: 45.4))
        figure.closeSubpath()
        ctx.fill(figure, with: .color(bodyColor))
        ctx.fill(Path(ellipseIn: CGRect(x: 25, y: 68, width: 50, height: 44)), with: .color(bellyColor ?? Color.white.opacity(0.16)))
        var feathers = Path()
        feathers.move(to: CGPoint(x: 40, y: 84)); feathers.addQuadCurve(to: CGPoint(x: 50, y: 84), control: CGPoint(x: 45, y: 88))
        feathers.addQuadCurve(to: CGPoint(x: 60, y: 84), control: CGPoint(x: 55, y: 88))
        feathers.move(to: CGPoint(x: 43, y: 95)); feathers.addQuadCurve(to: CGPoint(x: 50, y: 95), control: CGPoint(x: 46.5, y: 98.5))
        feathers.addQuadCurve(to: CGPoint(x: 57, y: 95), control: CGPoint(x: 53.5, y: 98.5))
        ctx.stroke(feathers, with: .color(bodyColor.opacity(0.4)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

        // Cheeks warm up and grow a little with the smile.
        let cr = 6 * (1 + 0.12 * smile)
        for cx in [14.0, 86.0] {
            ctx.fill(Path(ellipseIn: CGRect(x: cx - cr, y: 63 - cr, width: cr * 2, height: cr * 2)),
                     with: .color(cheekColor.opacity(0.8 + 0.2 * smile)))
        }
        var beak = Path()
        beak.move(to: CGPoint(x: 44, y: 62)); beak.addLine(to: CGPoint(x: 56, y: 62)); beak.addLine(to: CGPoint(x: 50, y: 72)); beak.closeSubpath()
        ctx.fill(beak, with: .color(beakColor))

        // The live eyes.
        let blink = (blinks && !still && smile < 0.5) ? track(t, Self.lid) : 0
        let idleX = still ? 0 : track(t, Self.lookX), idleY = still ? 0 : track(t, Self.lookY)
        let follow = easeInOut.value(at: min(1, now.timeIntervalSince(lookActiveChangedAt) / 0.3))
        let lookOn = look == .zero ? 1 - follow : follow
        let lx = (idleX * (1 - lookOn) + Double(look.width) * lookOn) * 4
        let ly = (idleY * (1 - lookOn) + Double(look.height) * lookOn) * 4
        for cx in [30.0, 70.0] { drawEye(&ctx, cx: cx, lx: lx, ly: ly, lid: blink, smile: smile) }
    }

    /// One eye: the pupil and its shine slide inside the disc; the smile is a
    /// squint that draws on as the pupil shrinks away; the lids are feathers,
    /// clipped 2 units wider than the eye so no ring shows when it's closed.
    private func drawEye(_ ctx: inout GraphicsContext, cx: Double, lx: Double, ly: Double, lid: Double, smile: Double) {
        let disc = Path(ellipseIn: CGRect(x: cx - 17, y: 30, width: 34, height: 34))
        ctx.fill(disc, with: .color(eyeColor))
        let k = 1 - smile
        if k > 0.01 {
            ctx.drawLayer { c in
                c.clip(to: disc)
                let pr = 8.5 * k
                c.fill(Path(ellipseIn: CGRect(x: cx + 1.5 + lx - pr, y: 50 + ly - pr, width: pr * 2, height: pr * 2)), with: .color(pupil))
                let sr = 2.8 * k
                c.fill(Path(ellipseIn: CGRect(x: cx + 4.5 + lx - sr, y: 46.5 + ly - sr, width: sr * 2, height: sr * 2)), with: .color(eyeColor))
            }
        }
        if smile > 0.01 {
            var arc = Path()
            arc.move(to: CGPoint(x: cx - 9, y: 51)); arc.addQuadCurve(to: CGPoint(x: cx + 9, y: 51), control: CGPoint(x: cx, y: 39))
            ctx.stroke(arc.trimmedPath(from: 0.5 - 0.5 * smile, to: 0.5 + 0.5 * smile), with: .color(pupil),
                       style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
        }
        guard lid > 0.001 else { return }
        let upper = 28 + 24 * lid, lower = 66 - 14 * lid
        ctx.drawLayer { c in
            c.clip(to: Path(ellipseIn: CGRect(x: cx - 19, y: 28, width: 38, height: 38)))
            c.fill(Path(CGRect(x: cx - 20, y: 26, width: 40, height: upper - 26)), with: .color(bodyColor))
            c.fill(Path(CGRect(x: cx - 20, y: lower, width: 40, height: 68 - lower)), with: .color(bodyColor))
        }
        let closed = min(1, max(0, (lid - 0.85) / 0.15))
        if closed > 0 {
            var line = Path()
            line.move(to: CGPoint(x: cx - 14, y: upper)); line.addQuadCurve(to: CGPoint(x: cx + 14, y: upper), control: CGPoint(x: cx, y: upper + 6))
            ctx.stroke(line, with: .color(pupil.opacity(closed)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
    }

    /// One wing beat, 0 → 1 → 0: opens in 100 ms (ease-out), folds in 150 ms.
    private func wingPulse(_ ms: Double) -> Double {
        if ms <= 0 || ms >= 250 { return 0 }
        return ms < 100 ? easeOut.value(at: ms / 100) : 1 - easeInOut.value(at: (ms - 100) / 150)
    }

    // MARK: Behavior

    private func setHappy(_ target: Double) {
        let now = Date()
        let p = min(1, now.timeIntervalSince(happyChangedAt) / 0.26)
        happyFrom = happyFrom + (happyTo - happyFrom) * easeOut.value(at: p)
        happyTo = target
        happyChangedAt = now
    }

    /// Poked: a hop with one flap and a happy squint.
    private func poke() {
        Haptics.owl()
        guard !reduceMotion else { return }
        flaps = 1
        hopAt = Date()
        giggleUntil = Date().addingTimeInterval(0.75)
    }

    /// Something worth celebrating: a hop with three flaps.
    private func cheer() {
        guard !reduceMotion, alive else { return }
        flaps = 3
        hopAt = Date()
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
