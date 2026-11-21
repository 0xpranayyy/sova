import SwiftUI

/// Sova's owl, drawn from the same shapes as the iPhone's `OwlMark`:
/// a round yellow owl with a lighter belly, wings, orange feet, pink cheeks
/// and indigo eyes that close in a smile when the day is done.
struct WatchOwl: View {
    var happy = false
    var body_: Color = WatchPalette.yellow
    var eye: Color = WatchPalette.indigo
    /// Upper eyelid, 0 open … 1 closed.
    var lid: Double = 0
    /// Each wing's angle in degrees, around its shoulder.
    var wingLeft: Double = 0
    var wingRight: Double = 0
    /// Breathing: how much taller the body is, from the feet (0.012 = 1.2%).
    var breath: Double = 0

    var body: some View {
        Canvas { context, size in
            // The owl lives in a 140 × 140 box from (-20, -8).
            let s = min(size.width, size.height) / 140
            context.translateBy(x: (size.width - 140 * s) / 2 + 20 * s, y: (size.height - 140 * s) / 2 + 8 * s)
            context.scaleBy(x: s, y: s)
            // Breathe from the feet up.
            context.translateBy(x: 50, y: 116)
            context.scaleBy(x: 1, y: 1 + breath)
            context.translateBy(x: -50, y: -116)

            let orange = WatchPalette.orange
            context.fill(Path(ellipseIn: CGRect(x: 29, y: 114, width: 18, height: 10)), with: .color(orange))
            context.fill(Path(ellipseIn: CGRect(x: 53, y: 114, width: 18, height: 10)), with: .color(orange))

            var left = Path()
            left.move(to: CGPoint(x: -6, y: 66))
            left.addQuadCurve(to: CGPoint(x: 8, y: 104), control: CGPoint(x: -12, y: 92))
            left.addQuadCurve(to: CGPoint(x: 6, y: 66), control: CGPoint(x: 4, y: 84))
            left.closeSubpath()
            var right = Path()
            right.move(to: CGPoint(x: 106, y: 66))
            right.addQuadCurve(to: CGPoint(x: 92, y: 104), control: CGPoint(x: 112, y: 92))
            right.addQuadCurve(to: CGPoint(x: 94, y: 66), control: CGPoint(x: 96, y: 84))
            right.closeSubpath()
            // Wings hinge at the shoulders.
            var l = context
            l.translateBy(x: 6, y: 66); l.rotate(by: .degrees(wingLeft)); l.translateBy(x: -6, y: -66)
            l.fill(left, with: .color(body_))
            var r = context
            r.translateBy(x: 94, y: 66); r.rotate(by: .degrees(-wingRight)); r.translateBy(x: -94, y: -66)
            r.fill(right, with: .color(body_))

            var figure = Path()
            figure.move(to: CGPoint(x: 10, y: 0))
            figure.addQuadCurve(to: CGPoint(x: 50, y: 18.36), control: CGPoint(x: 30, y: 21.6))
            figure.addQuadCurve(to: CGPoint(x: 90, y: 0), control: CGPoint(x: 70, y: 21.6))
            figure.addCurve(to: CGPoint(x: 50, y: 116), control1: CGPoint(x: 110, y: 45.36), control2: CGPoint(x: 104, y: 116))
            figure.addCurve(to: CGPoint(x: 10, y: 0), control1: CGPoint(x: -4, y: 116), control2: CGPoint(x: -10, y: 45.36))
            figure.closeSubpath()
            context.fill(figure, with: .color(body_))
            context.fill(Path(ellipseIn: CGRect(x: 25, y: 68, width: 50, height: 44)), with: .color(WatchPalette.belly))

            for cx in [30.0, 70.0] {
                context.fill(Path(ellipseIn: CGRect(x: cx - 17, y: 30, width: 34, height: 34)), with: .color(eye))
                if happy {
                    var smile = Path()
                    smile.move(to: CGPoint(x: cx - 9, y: 51))
                    smile.addQuadCurve(to: CGPoint(x: cx + 9, y: 51), control: CGPoint(x: cx, y: 39))
                    context.stroke(smile, with: .color(body_), style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                } else {
                    context.fill(Path(ellipseIn: CGRect(x: cx + 1.5 - 8.5, y: 50 - 8.5, width: 17, height: 17)),
                                 with: .color(body_))
                    context.fill(Path(ellipseIn: CGRect(x: cx + 4.5 - 2.8, y: 46.5 - 2.8, width: 5.6, height: 5.6)),
                                 with: .color(eye))
                    if lid > 0.001 {
                        // The lid is skin, clipped 2 units wider than the eye,
                        // so no ring shows around a closed eye.
                        var lidContext = context
                        lidContext.clip(to: Path(ellipseIn: CGRect(x: cx - 19, y: 28, width: 38, height: 38)))
                        // The upper lid comes down and the lower one rises to
                        // meet it a little below the middle.
                        let edge = 28 + 22 * lid
                        lidContext.fill(Path(CGRect(x: cx - 20, y: 26, width: 40, height: edge - 26)), with: .color(body_))
                        let low = 66 - 14 * lid
                        lidContext.fill(Path(CGRect(x: cx - 20, y: low, width: 40, height: 68 - low)), with: .color(body_))
                        if lid > 0.5 {
                            // A closed eye reads as a soft curved line, not blank skin.
                            var lash = Path()
                            lash.move(to: CGPoint(x: cx - 15, y: edge))
                            lash.addQuadCurve(to: CGPoint(x: cx + 15, y: edge), control: CGPoint(x: cx, y: edge + 6 * lid))
                            context.stroke(lash, with: .color(eye.opacity(min(1, (lid - 0.5) * 3))),
                                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                    }
                }
            }
            for cx in [14.0, 86.0] {
                context.fill(Path(ellipseIn: CGRect(x: cx - 6, y: 57, width: 12, height: 12)),
                             with: .color(WatchPalette.pink.opacity(0.85)))
            }
            var beak = Path()
            beak.move(to: CGPoint(x: 44, y: 62))
            beak.addLine(to: CGPoint(x: 56, y: 62))
            beak.addLine(to: CGPoint(x: 50, y: 72))
            beak.closeSubpath()
            context.fill(beak, with: .color(orange))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// The day's ring: yellow fills it as things get done, with the owl inside.
struct OwlRing: View {
    var progress: Double
    var happy = false
    var lineWidth: CGFloat = 6
    /// In the app the owl breathes and blinks; complications stay still.
    var live = false

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(WatchPalette.yellow, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Group {
                if live { LiveWatchOwl(happy: happy) } else { WatchOwl(happy: happy) }
            }
            .padding(lineWidth + 4)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
    }
}

/// Where the Watch keeps the last day the iPhone sent, so the app opens
/// instantly and the complications can read it.
enum WatchDayStore {
    private static var defaults: UserDefaults { UserDefaults(suiteName: WatchKeys.appGroup) ?? .standard }

    static func load() -> WatchDay? {
        WatchDay.decode(defaults.data(forKey: WatchKeys.storedDay))
    }

    static func save(_ day: WatchDay) {
        defaults.set(day.encoded(), forKey: WatchKeys.storedDay)
    }
}


// MARK: - Alive

/// The owl's idle life, on one clock: breathing, blinks and a little sway in
/// each wing. Numbers in milliseconds and drawing units.
enum OwlMotion {
    static func wave(_ t: Double, _ period: Double, _ phase: Double = 0) -> Double {
        sin((t / period + phase) * 2 * .pi)
    }
    static func easeInOut(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
    static func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }

    /// About 1.2% taller on the in-breath, every 3.6 s.
    static func breath(_ t: Double) -> Double { 0.012 * (wave(t, 3600) + 1) / 2 }
    /// The wings sway on different periods, so they never mirror.
    static func wingLeft(_ t: Double) -> Double { 1.8 * wave(t, 3100) }
    static func wingRight(_ t: Double) -> Double { 1.5 * wave(t, 3700, 0.3) }

    /// A 7.2 s loop: one blink, then a double blink. Each closes in 110 ms,
    /// holds 40 ms and reopens in 190 ms with an ease-out.
    static func lid(_ t: Double) -> Double {
        let loop = t.truncatingRemainder(dividingBy: 7200)
        func blink(_ start: Double) -> Double {
            let x = loop - start
            if x < 0 || x > 340 { return 0 }
            if x < 110 { return easeInOut(x / 110) }
            if x < 150 { return 1 }
            return 1 - easeOut((x - 150) / 190)
        }
        return max(blink(2000), blink(5600), blink(5940))
    }
}

/// The owl, breathing and blinking. Pauses when the screen dims (always-on)
/// and stays still with Reduce Motion.
struct LiveWatchOwl: View {
    var happy = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || dimmed)) { context in
            let t = (reduceMotion || dimmed) ? 0 : context.date.timeIntervalSinceReferenceDate * 1000
            WatchOwl(happy: happy, lid: happy ? 0 : OwlMotion.lid(t),
                     wingLeft: OwlMotion.wingLeft(t), wingRight: OwlMotion.wingRight(t), breath: OwlMotion.breath(t))
        }
    }
}
