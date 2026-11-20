import SwiftUI

/// Sova's owl, drawn from the same shapes as the iPhone's `OwlMark`:
/// a round yellow owl with a lighter belly, wings, orange feet, pink cheeks
/// and indigo eyes that close in a smile when the day is done.
struct WatchOwl: View {
    var happy = false
    var body_: Color = WatchPalette.yellow
    var eye: Color = WatchPalette.indigo

    var body: some View {
        Canvas { context, size in
            // The owl lives in a 140 × 140 box from (-20, -8).
            let s = min(size.width, size.height) / 140
            context.translateBy(x: (size.width - 140 * s) / 2 + 20 * s, y: (size.height - 140 * s) / 2 + 8 * s)
            context.scaleBy(x: s, y: s)

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
            context.fill(left, with: .color(body_))
            context.fill(right, with: .color(body_))

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

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(WatchPalette.yellow, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            WatchOwl(happy: happy)
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
