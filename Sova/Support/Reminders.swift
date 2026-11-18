import Foundation
import UserNotifications

/// Two gentle daily notifications: plan in the morning, look back at night.
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

    static func schedule(morning: Date?, evening: Date?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID])
        if let morning {
            add(id: morningID, at: morning,
                title: String(localized: "Good morning"),
                body: String(localized: "Your day is ready. Take a minute to plan it."))
        }
        if let evening {
            add(id: eveningID, at: evening,
                title: String(localized: "How did today go?"),
                body: String(localized: "Tick off what you finished and let the rest wait for tomorrow."))
        }
    }

    private static func add(id: String, at time: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func time(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
