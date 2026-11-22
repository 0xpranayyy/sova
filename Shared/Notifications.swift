import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// The buttons on Sova's notifications, and what they do. A task alert can
/// be finished, snoozed for an hour or pushed to tomorrow without opening
/// the app; a ritual reminder can be ticked off.
enum NotificationActions {
    static let taskCategory = "SOVA_TASK"
    static let ritualCategory = "SOVA_RITUAL"
    /// The evening check-in, with a button that moves what's left to tomorrow.
    static let eveningCategory = "SOVA_EVENING"

    enum Action: String {
        case done = "SOVA_DONE"
        case snooze = "SOVA_SNOOZE"
        case tomorrow = "SOVA_TOMORROW"
        case ritualDone = "SOVA_RITUAL_DONE"
        case moveOpenToTomorrow = "SOVA_MOVE_OPEN"
    }

    static func register() {
        let done = UNNotificationAction(identifier: Action.done.rawValue, title: String(localized: "Done"),
                                        options: [], icon: UNNotificationActionIcon(systemImageName: "checkmark.circle"))
        let snooze = UNNotificationAction(identifier: Action.snooze.rawValue, title: String(localized: "In 1 hour"),
                                          options: [], icon: UNNotificationActionIcon(systemImageName: "clock.arrow.circlepath"))
        let tomorrow = UNNotificationAction(identifier: Action.tomorrow.rawValue, title: String(localized: "Tomorrow"),
                                            options: [], icon: UNNotificationActionIcon(systemImageName: "arrow.turn.up.right"))
        let ritualDone = UNNotificationAction(identifier: Action.ritualDone.rawValue, title: String(localized: "Done"),
                                              options: [], icon: UNNotificationActionIcon(systemImageName: "checkmark.circle"))
        let moveOpen = UNNotificationAction(identifier: Action.moveOpenToTomorrow.rawValue,
                                            title: String(localized: "Move to tomorrow"),
                                            options: [], icon: UNNotificationActionIcon(systemImageName: "arrow.turn.up.right"))
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: taskCategory, actions: [done, snooze, tomorrow], intentIdentifiers: []),
            UNNotificationCategory(identifier: ritualCategory, actions: [ritualDone], intentIdentifiers: []),
            UNNotificationCategory(identifier: eveningCategory, actions: [moveOpen], intentIdentifiers: []),
        ])
    }

    /// Runs a notification button. `id` is the request's identifier.
    @MainActor
    static func handle(action: String, id: String, userInfo: [String: String]) {
        let context = SovaStore.shared.mainContext
        if let taskID = userInfo["taskID"] {
            let tasks = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isDone }))) ?? []
            guard let task = tasks.first(where: { $0.alertID == taskID }) else { return }
            switch Action(rawValue: action) {
            case .done:
                task.toggle()
                task.spawnNextOccurrence()
                TaskAlerts.cancel(task)
            case .snooze:
                TaskAlerts.snooze(task, minutes: 60)
            case .tomorrow:
                task.postponeToTomorrow()
                TaskAlerts.schedule(task)
            default:
                // A tap on the notification itself opens the task.
                SovaSettings.shared.set(taskID, forKey: SovaSettings.Key.pendingTask)
            }
            SovaRefresh.changed(context)
        } else if action == Action.moveOpenToTomorrow.rawValue {
            // The evening check-in: everything still open today goes to tomorrow.
            let open = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isDone }))) ?? []
            for task in open where task.isDueTodayOrEarlier && task.dueDate != nil {
                task.postponeToTomorrow()
                TaskAlerts.schedule(task)
            }
            SovaRefresh.changed(context)
        } else if let ritualID = userInfo["ritualID"], action == Action.ritualDone.rawValue {
            guard let routine = RitualStore.find(ritualID), !routine.isDone(on: .now) else { return }
            if routine.isCounted {
                while !routine.isDone(on: .now) { routine.advance(on: .now) }
            } else {
                routine.advance(on: .now)
            }
            SovaRefresh.changed(context)
        }
    }
}

/// A nudge for a ritual at its time, on the days it's due. Reminders are
/// one-off and cover the next few days, so a ritual already done today stays
/// quiet; they're rebuilt after every change and each time Sova opens.
/// iOS keeps at most 64 pending notifications, so rituals share a budget
/// with task alerts.
enum RitualReminders {
    static let daysAhead = 3
    static let budget = 24

    private static func dayKey(_ day: Date) -> Int { Int(day.startOfDay.timeIntervalSinceReferenceDate / 86_400) }

    private static func ids(_ routine: Routine) -> [String] {
        let today = Date.now.startOfDay
        // The days ahead, plus the weekday ids an earlier version used.
        return (-1...daysAhead).map { "sova.ritual.\(routine.entityID).d\(dayKey(today.adding(days: $0)))" }
            + (1...7).map { "sova.ritual.\(routine.entityID).\($0)" }
    }

    static func cancel(_ routine: Routine) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids(routine))
    }

    /// Schedules up to `limit` reminders; returns how many it added.
    @discardableResult
    static func schedule(_ routine: Routine, limit: Int = daysAhead) -> Int {
        cancel(routine)
        guard routine.reminderMinutes >= 0, limit > 0 else { return 0 }
        let center = UNUserNotificationCenter.current()
        let today = Date.now.startOfDay
        var added = 0
        for offset in 0..<daysAhead where added < limit {
            let day = today.adding(days: offset)
            guard routine.isScheduled(on: day), !(offset == 0 && routine.isDone(on: day)),
                  let fire = Calendar.current.date(bySettingHour: routine.reminderMinutes / 60,
                                                   minute: routine.reminderMinutes % 60, second: 0, of: day),
                  fire > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = routine.title
            content.body = routine.isCounted
                ? String(localized: "Time for your ritual. Goal today: \(routine.target).")
                : String(localized: "Time for your ritual. Keep the streak going! 🔥")
            content.sound = .default
            content.threadIdentifier = "sova.rituals"
            content.categoryIdentifier = NotificationActions.ritualCategory
            content.userInfo = ["ritualID": routine.entityID]
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            center.add(UNNotificationRequest(identifier: "sova.ritual.\(routine.entityID).d\(dayKey(day))",
                                             content: content,
                                             trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
            added += 1
        }
        return added
    }

    /// Rebuilds every ritual's reminders within the shared budget.
    static func resync(in context: ModelContext) {
        let routines = (try? context.fetch(FetchDescriptor<Routine>(
            predicate: #Predicate { $0.reminderMinutes >= 0 }, sortBy: [SortDescriptor(\.order)]))) ?? []
        var left = budget
        for routine in routines { left -= schedule(routine, limit: left) }
    }
}
