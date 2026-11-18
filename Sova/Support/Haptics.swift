import UIKit

/// Hand-tuned haptic moments. Each one is short and matched to what the
/// eye sees, so touch and motion arrive together.
@MainActor
enum Haptics {
    /// A soft, round tap, like touching something squishy.
    static func soft(_ intensity: CGFloat = 0.6) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: intensity)
    }

    /// A small crisp tick, for things appearing.
    static func pop(_ intensity: CGFloat = 0.45, sound: Bool = false) {
        if sound { Sounds.play(.pop) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: intensity)
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// The owl being poked: a squish, then a little bounce.
    static func owl() {
        Sounds.play(.owl)
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.85)
            try? await Task.sleep(for: .milliseconds(160))
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
        }
    }

    /// A whole day, or a whole goal, finished: a rolling flourish that
    /// fades out like the sparkles do.
    static func celebrate() {
        Sounds.play(.celebrate)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            for (delay, intensity) in [(140, 0.75), (90, 0.55), (90, 0.4), (110, 0.25)] {
                try? await Task.sleep(for: .milliseconds(delay))
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: intensity)
            }
        }
    }
}
