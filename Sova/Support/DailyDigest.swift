import Foundation
import SwiftData
import UserNotifications

/// The morning and evening notifications, written from your real day: the
/// morning one names your top three, the evening one says what's still open
/// and offers to move it to tomorrow. They're one-off notifications for the
/// next few days, rebuilt a moment after any change and whenever Sova opens.
@MainActor
enum DailyDigest {
    static let daysAhead = 5
    private static var pending: Task<Void, Never>?
    private static var observer: NSObjectProtocol?

    private static func morningID(_ offset: Int) -> String { "sova.digest.morning.\(offset)" }
    private static func eveningID(_ offset: Int) -> String { "sova.digest.evening.\(offset)" }

    /// Call once at launch.
    static func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil,
                                                          queue: .main) { _ in
            Task { @MainActor in DailyDigest.refreshSoon() }
        }
    }

    /// Rebuilds soon, folding bursts of saves into one rebuild.
    static func refreshSoon() {
        pending?.cancel()
        pending = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            refresh()
        }
    }

    // MARK: Settings (the same keys as the Settings screen)

    private static func minutes(on onKey: String, at minutesKey: String, default fallback: Int) -> Int? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: onKey) else { return nil }
        return defaults.object(forKey: minutesKey) as? Int ?? fallback
    }

    static var savedMorning: Int? { minutes(on: "morningReminderOn", at: "morningReminderMinutes", default: 8 * 60) }
    static var savedEvening: Int? { minutes(on: "eveningReminderOn", at: "eveningReminderMinutes", default: 21 * 60) }

    // MARK: Building

    /// Replaces the pending morning and evening notifications. Pass the
    /// times (minutes after midnight) to use them before they're saved.
    static func refresh(morning: Int?? = .none, evening: Int?? = .none) {
        let morning = morning ?? savedMorning
        let evening = evening ?? savedEvening
        let center = UNUserNotificationCenter.current()
        let ids = (0..<daysAhead).flatMap { [morningID($0), eveningID($0)] }
        center.removePendingNotificationRequests(withIdentifiers: ids + [Reminders.morningID, Reminders.eveningID])
        guard morning != nil || evening != nil else { return }

        let context = SovaStore.shared.mainContext
        let open = ((try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate<TaskItem> { !$0.isDone }))) ?? [])
            .filter { $0.dueDate != nil }
            .sorted(by: TaskItem.ordering)
        let routines = RitualStore.all(in: context)
        let name = (SovaSettings.shared.string(forKey: SovaSettings.Key.userName) ?? "")
            .trimmingCharacters(in: .whitespaces)
        let today = Date.now.startOfDay

        for offset in 0..<daysAhead {
            let day = today.adding(days: offset)
            if let morning, let fire = time(morning, on: day), fire > .now {
                let dueBy = open.filter { ($0.dueDate ?? .distantFuture) < day.endOfDay }
                let rituals = routines.filter { $0.isScheduled(on: day) && !$0.isDone(on: day) }
                add(id: morningID(offset), at: fire, content: morningContent(tasks: dueBy, rituals: rituals, name: name))
            }
            if let evening, let fire = time(evening, on: day), fire > .now {
                // Only today's count is known now; later days get the
                // gentle version, and the button still works on what's open then.
                let left = offset == 0 ? open.filter { ($0.dueDate ?? .distantFuture) < day.endOfDay } : nil
                add(id: eveningID(offset), at: fire, content: eveningContent(left: left))
            }
        }
    }

    private static func time(_ minutes: Int, on day: Date) -> Date? {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)
    }

    private static func add(id: String, at fire: Date, content: UNMutableNotificationContent) {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private static func morningContent(tasks: [TaskItem], rituals: [Routine], name: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = name.isEmpty ? String(localized: "Good morning") : String(localized: "Good morning, \(name)")
        content.sound = .default
        if tasks.isEmpty && rituals.isEmpty {
            content.body = String(localized: "A clear day. Take a minute to plan it.")
            return content
        }
        var lines = tasks.prefix(3).map { task in
            task.hasTime ? "\(task.title) · \((task.dueDate ?? .now).formatted(date: .omitted, time: .shortened))" : task.title
        }
        if tasks.count > 3 { lines.append(String(localized: "+\(tasks.count - 3) more")) }
        if !rituals.isEmpty {
            lines.append(rituals.count == 1 ? String(localized: "Ritual: \(rituals[0].title)")
                                            : String(localized: "\(rituals.count) rituals"))
        }
        content.body = lines.joined(separator: "\n")
        return content
    }

    private static func eveningContent(left: [TaskItem]?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        guard let left else {
            content.title = String(localized: "How did today go?")
            content.body = String(localized: "Tick off what you finished. Anything left can move to tomorrow.")
            content.categoryIdentifier = NotificationActions.eveningCategory
            return content
        }
        if left.isEmpty {
            content.title = String(localized: "All done today")
            content.body = String(localized: "Nothing left on your list. Proud of you.")
            return content
        }
        content.title = left.count == 1 ? String(localized: "1 still open") : String(localized: "\(left.count) still open")
        let names = left.prefix(2).map(\.title).joined(separator: ", ")
        content.body = left.count > 2 ? String(localized: "\(names) and \(left.count - 2) more. Move them to tomorrow?")
                                      : String(localized: "\(names). Move to tomorrow?")
        content.categoryIdentifier = NotificationActions.eveningCategory
        return content
    }
}
