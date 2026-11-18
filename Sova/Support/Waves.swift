import SwiftUI
import UIKit
import Observation
import DistortionWavesKit

// Distortion Waves (MIT, Jakub Antalik, libraries.dev) for Sova's two big
// moments: the first open after onboarding, and finishing the whole day.
//
// The wave bends pictures of plain SwiftUI views and keeps hidden copies of
// both sides mounted, so it never wraps a live screen. At the moment of the
// tap we take a picture of the screen, the wave carries that picture into a
// light, side-effect-free destination view, and the real screen takes over
// underneath when it has finished.

extension DistortionWavePalette {
    /// Sova's sticker colors, with a pink fringe ahead and a cyan one behind.
    static let sova = DistortionWavePalette(
        colors: [
            DistortionWaveColor(255, 233, 77), DistortionWaveColor(77, 242, 176),
            DistortionWaveColor(255, 92, 147), DistortionWaveColor(217, 206, 255),
            DistortionWaveColor(61, 203, 255), DistortionWaveColor(255, 160, 58),
        ],
        ahead: DistortionWaveColor(255, 92, 147),
        behind: DistortionWaveColor(61, 203, 255)
    )
}

extension DistortionWaveStyle {
    /// Up the screen from a button at the bottom.
    static var sovaRise: DistortionWaveStyle {
        var style = DistortionWaveStyle.vertical
        style.palette = .sova
        return style
    }

    /// A ring out from the owl.
    static var sovaRing: DistortionWaveStyle {
        var style = DistortionWaveStyle.center
        style.palette = .sova
        return style
    }
}

/// A picture of what's on screen right now.
enum ScreenSnapshot {
    @MainActor
    static var window: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive })?.keyWindow
            ?? scenes.first?.keyWindow
    }

    @MainActor
    static func safeArea() -> EdgeInsets {
        guard let i = window?.safeAreaInsets else { return EdgeInsets() }
        return EdgeInsets(top: i.top, leading: i.left, bottom: i.bottom, trailing: i.right)
    }

    @MainActor
    static func take() -> UIImage? {
        guard let window else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }
}

/// What a wave lands on.
enum WaveScene: Equatable {
    case welcome
    case dayDone(DaySummary)

    var style: DistortionWaveStyle {
        switch self {
        case .welcome: .sovaRise
        case .dayDone: .sovaRing
        }
    }

    /// Seconds after the wave sets off when the real screen takes over at the
    /// latest. The welcome hands over once the front has crossed the screen,
    /// without waiting for the colored edges to fade, so the stand-in Today
    /// isn't left on screen; the day summary waits for the whole wave.
    var handOver: Double {
        let style = self.style
        switch self {
        case .welcome: return style.anticipation + style.travel * 0.6 + 0.6
        case .dayDone: return style.duration + 0.8
        }
    }
}

/// The numbers shown when the whole day is done.
struct DaySummary: Equatable {
    var tasks: Int
    var rituals: Int
    var streak: Int
}

/// Runs one wave at a time over the whole app.
///
/// The live screen underneath is always already the real destination: the
/// caller changes it right after `play`. The wave is only a cover, and the
/// cover always goes away on its own, on a plain main-queue timer, whatever
/// the wave itself reports. A tap on it also skips it.
@MainActor
@Observable
final class WaveDirector {
    private(set) var scene: WaveScene?
    private(set) var snapshot: UIImage?
    private(set) var source: CGRect = .zero
    private(set) var focus: CGPoint?
    private(set) var revealed = false
    /// The screen's safe area when the wave started. The wave's stage spans
    /// the whole screen and passes no safe area down, so the destination
    /// views pad themselves with this.
    private(set) var insets = EdgeInsets()
    private var afterDismiss: (() -> Void)?
    /// Which run the pending timers belong to, so a stale timer does nothing.
    private var run = 0

    var isActive: Bool { scene != nil }

    /// Takes a picture of the screen and covers the app with it, then sends
    /// the wave out once its shaders have warmed up.
    /// - Returns: false if no picture could be taken; the caller should then
    ///   carry on without the wave.
    @discardableResult
    func play(_ scene: WaveScene, from source: CGRect, afterDismiss: (() -> Void)? = nil) -> Bool {
        guard !isActive, let picture = ScreenSnapshot.take() else { return false }
        run += 1
        let thisRun = run
        snapshot = picture
        insets = ScreenSnapshot.safeArea()
        self.source = source
        focus = CGPoint(x: source.midX, y: source.midY)
        revealed = false
        self.afterDismiss = afterDismiss
        self.scene = scene

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self, self.run == thisRun, self.scene != nil else { return }
            // The day-done moment already celebrated when the last thing was ticked.
            if scene == .welcome { Haptics.celebrate() }
            self.revealed = true
        }
        // The welcome uncovers the real Today once the wave has crossed the
        // screen. The day summary waits for its "Nice!", but never forever.
        let limit = scene == .welcome ? scene.handOver : 30
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + limit) { [weak self] in
            guard let self, self.run == thisRun else { return }
            self.dismiss()
        }
        return true
    }

    /// Called by the wave when it has left and the edges have cleared.
    func waveFinished() {
        guard let scene, revealed else { return }
        switch scene {
        case .welcome:
            dismiss()
        case .dayDone:
            AccessibilityNotification.Announcement(String(localized: "Day complete")).post()
        }
    }

    /// A tap on the cover: skip ahead to the real screen. The day summary
    /// only closes once it's on screen.
    func skip() {
        guard let scene else { return }
        if case .dayDone = scene, !revealed { return }
        dismiss()
    }

    /// Fades the cover away, uncovering the live screen underneath.
    func dismiss() {
        guard scene != nil else { return }
        run += 1
        withAnimation(.smooth(duration: 0.35)) {
            scene = nil
            snapshot = nil
            revealed = false
        }
        let after = afterDismiss
        afterDismiss = nil
        after?()
    }
}

/// The wave over everything, while one is playing.
struct WaveOverlay: View {
    @Environment(WaveDirector.self) private var waves

    var body: some View {
        if let scene = waves.scene, let snapshot = waves.snapshot {
            DistortionWave(
                isRevealed: waves.revealed,
                source: waves.source,
                focus: waves.focus,
                style: scene.style,
                onFinish: { waves.waveFinished() }
            ) {
                Image(uiImage: snapshot)
                    .resizable()
                    .ignoresSafeArea()
            } revealed: {
                destination(for: scene)
            }
            .contentShape(.rect)
            .onTapGesture { waves.skip() }
            .ignoresSafeArea()
            .transition(.opacity)
            .zIndex(10)
        }
    }

    @ViewBuilder
    private func destination(for scene: WaveScene) -> some View {
        switch scene {
        case .welcome:
            TodayIntroView()
        case .dayDone(let summary):
            DayCompleteView(summary: summary, owlFrame: waves.source) {
                waves.dismiss()
            }
        }
    }
}
