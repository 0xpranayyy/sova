import Foundation
import SwiftData

extension TaskItem {
    /// Creates the next occurrence of a repeating task that was just
    /// finished, and hands the repeat on to it. Used by the app and by the
    /// widget's check button.
    @discardableResult
    func spawnNextOccurrence() -> TaskItem? {
        let rule = repeatRule
        guard rule != .none, let due = dueDate, let nextDue = rule.next(after: due),
              let context = modelContext else { return nil }
        let next = TaskItem(title: title, notes: notes, dueDate: nextDue, hasTime: hasTime,
                            priority: priority, accent: accent, goal: goal)
        next.repeatRaw = repeatRaw
        next.checklist = checklist.map { ChecklistItem(title: $0.title) }
        repeatRaw = RepeatRule.none.rawValue
        context.insert(next)
        TaskAlerts.schedule(next)
        return next
    }
}
