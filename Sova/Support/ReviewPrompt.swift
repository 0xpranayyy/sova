import Foundation

/// Asks for a rating only at a happy moment: after the whole day is done,
/// on the third or later such day, and at most once every 60 days.
enum ReviewPrompt {
    private static let lastCelebratedDay = "lastCelebratedDay"

    static func shouldAskAfterCelebration() -> Bool {
        let defaults = UserDefaults.standard
        let today = Date.now.startOfDay
        if let last = defaults.object(forKey: lastCelebratedDay) as? Date, last >= today { return false }
        defaults.set(today, forKey: lastCelebratedDay)
        let days = defaults.integer(forKey: SovaSettings.Key.activeDays) + 1
        defaults.set(days, forKey: SovaSettings.Key.activeDays)
        guard days >= 3 else { return false }
        let lastAsked = defaults.object(forKey: SovaSettings.Key.lastReviewPrompt) as? Date ?? .distantPast
        guard Date.now.timeIntervalSince(lastAsked) > 60 * 86_400 else { return false }
        defaults.set(Date.now, forKey: SovaSettings.Key.lastReviewPrompt)
        return true
    }
}
