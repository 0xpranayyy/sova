import Foundation
import UserNotifications

/// Two gentle daily notifications: plan in the morning, look back at night.
@MainActor
enum Reminders {
    static let morningID = "sova.morning"
    static let eveningID = "sova.evening"

    /// Asks for permission, then schedules. Returns whether it's allowed.
    static func enable(morning: Date?, evening: Date?) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted { schedule(morning: morning, evening: evening) }
        return granted
    }

    /// The morning and evening notifications are written from your day by
    /// `DailyDigest`; this hands it the chosen times.
    static func schedule(morning: Date?, evening: Date?) {
        DailyDigest.refresh(morning: .some(morning.map(minutes(of:))), evening: .some(evening.map(minutes(of:))))
    }

    private static func minutes(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    nonisolated static func time(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
