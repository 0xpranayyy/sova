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

    enum Action: String {
        case done = "SOVA_DONE"
        case snooze = "SOVA_SNOOZE"
        case tomorrow = "SOVA_TOMORROW"
        case ritualDone = "SOVA_RITUAL_DONE"
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
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: taskCategory, actions: [done, snooze, tomorrow], intentIdentifiers: []),
            UNNotificationCategory(identifier: ritualCategory, actions: [ritualDone], intentIdentifiers: []),
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
                if let due = task.dueDate {
                    task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: due)
                }
                TaskAlerts.schedule(task)
            default:
                // A tap on the notification itself opens the task.
                SovaSettings.shared.set(taskID, forKey: SovaSettings.Key.pendingTask)
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

/// A daily nudge for a ritual, on the days it's scheduled.
enum RitualReminders {
    private static func ids(_ routine: Routine) -> [String] {
        (1...7).map { "sova.ritual.\(routine.entityID).\($0)" }
    }

    static func cancel(_ routine: Routine) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids(routine))
    }

    static func schedule(_ routine: Routine) {
        cancel(routine)
        guard routine.reminderMinutes >= 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = routine.title
        content.body = routine.isCounted
            ? String(localized: "Time for your ritual. Goal today: \(routine.target).")
            : String(localized: "Time for your ritual. Keep the streak going! 🔥")
        content.sound = .default
        content.threadIdentifier = "sova.rituals"
        content.categoryIdentifier = NotificationActions.ritualCategory
        content.userInfo = ["ritualID": routine.entityID]
        for weekday in routine.weekdays {
            var parts = DateComponents()
            parts.weekday = weekday
            parts.hour = routine.reminderMinutes / 60
            parts.minute = routine.reminderMinutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: "sova.ritual.\(routine.entityID).\(weekday)", content: content, trigger: trigger))
        }
    }
}
