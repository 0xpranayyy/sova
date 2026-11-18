import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// A notification at a task's time (or a few minutes before, per Settings).
enum TaskAlerts {
    private static var center: UNUserNotificationCenter { .current() }

    static func schedule(_ task: TaskItem) {
        cancel(task)
        guard !task.isDone, task.hasTime, let due = task.dueDate else { return }
        let offset = SovaSettings.alertOffset
        let fire = due.addingTimeInterval(-Double(offset) * 60)
        guard fire > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        let time = due.formatted(date: .omitted, time: .shortened)
        content.body = offset == 0
            ? String(localized: "It's \(time). Time for this one!")
            : String(localized: "Coming up at \(time).")
        content.sound = .default
        content.threadIdentifier = "sova.tasks"
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.add(UNNotificationRequest(identifier: task.alertID, content: content, trigger: trigger))
    }

    static func cancel(_ task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [task.alertID])
    }

    /// Asks once, the first time someone gives a task a time.
    static func requestPermissionIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Rebuilds pending alerts for the next upcoming timed tasks. iOS keeps
    /// at most 64 pending notifications, so only the soonest are scheduled.
    static func resync(in context: ModelContext) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("sova.task.") })
        let now = Date.now
        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate<TaskItem> { !$0.isDone && $0.hasTime })
        let tasks = ((try? context.fetch(descriptor)) ?? [])
            .filter { ($0.dueDate ?? .distantPast) > now }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        for task in tasks.prefix(50) { schedule(task) }
    }
}

/// After anything changes: refresh widgets and the overdue badge.
enum SovaRefresh {
    /// Writes any pending changes to disk first, so the widgets and Siri,
    /// which read the store from their own process, see them.
    static func changed(_ context: ModelContext?) {
        if let context, context.hasChanges { try? context.save() }
        WidgetCenter.shared.reloadAllTimelines()
        updateBadge(context)
    }

    static func updateBadge(_ context: ModelContext?) {
        var count = 0
        if SovaSettings.badgeOverdue, let context {
            let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate<TaskItem> { !$0.isDone && $0.dueDate != nil })
            count = ((try? context.fetch(descriptor)) ?? []).filter(\.isOverdue).count
        }
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
