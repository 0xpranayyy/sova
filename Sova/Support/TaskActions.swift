import SwiftUI
import SwiftData

/// Everything needed to put a deleted task back.
struct TaskSnapshot {
    let title: String
    let notes: String
    let dueDate: Date?
    let hasTime: Bool
    let priorityRaw: Int
    let accentRaw: String
    let isDone: Bool
    let completedAt: Date?
    let createdAt: Date
    let repeatRaw: String
    let goal: Goal?

    init(_ task: TaskItem) {
        title = task.title; notes = task.notes; dueDate = task.dueDate; hasTime = task.hasTime
        priorityRaw = task.priorityRaw; accentRaw = task.accentRaw; isDone = task.isDone
        completedAt = task.completedAt; createdAt = task.createdAt; goal = task.goal
        repeatRaw = task.repeatRaw
    }

    func restore(in context: ModelContext) {
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, hasTime: hasTime)
        task.priorityRaw = priorityRaw
        task.accentRaw = accentRaw
        task.isDone = isDone
        task.completedAt = completedAt
        task.createdAt = createdAt
        task.repeatRaw = repeatRaw
        task.goal = goal
        context.insert(task)
        TaskAlerts.schedule(task)
        SovaRefresh.changed(context)
    }
}

@MainActor
enum TaskActions {
    static func toggle(_ task: TaskItem, router: AppRouter?) {
        let context = task.modelContext
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { task.toggle() }
        TaskAlerts.schedule(task)
        // A repeating task hands its repeat on to the next occurrence.
        let next = task.isDone ? spawnNext(after: task) : nil
        SovaRefresh.changed(context)
        guard task.isDone, let router else { return }
        let message = next?.dueDate.map { String(localized: "Done! Next: \($0.relativeDayText(includingTime: false))") }
            ?? String(localized: "Done: \(task.title)")
        router.show(Toast(message: message) {
            // Only reopen it if it's still done (it may have been unticked since).
            guard task.isDone else { return }
            if let next {
                task.repeatRaw = next.repeatRaw
                TaskAlerts.cancel(next)
                context?.delete(next)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { task.toggle() }
            TaskAlerts.schedule(task)
            SovaRefresh.changed(context)
        })
    }

    /// Creates the next occurrence of a repeating task that was just finished.
    private static func spawnNext(after task: TaskItem) -> TaskItem? {
        let rule = task.repeatRule
        guard rule != .none, let due = task.dueDate, let nextDue = rule.next(after: due),
              let context = task.modelContext else { return nil }
        let next = TaskItem(title: task.title, notes: task.notes, dueDate: nextDue, hasTime: task.hasTime,
                            priority: task.priority, accent: task.accent, goal: task.goal)
        next.repeatRaw = task.repeatRaw
        task.repeatRaw = RepeatRule.none.rawValue
        context.insert(next)
        TaskAlerts.schedule(next)
        return next
    }

    static func delete(_ task: TaskItem, context: ModelContext, router: AppRouter?) {
        let snapshot = TaskSnapshot(task)
        Haptics.warning()
        TaskAlerts.cancel(task)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { context.delete(task) }
        SovaRefresh.changed(context)
        router?.show(Toast(message: String(localized: "Deleted: \(snapshot.title)")) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { snapshot.restore(in: context) }
        })
    }

    /// Moves a task to tomorrow, keeping its time of day.
    static func moveToTomorrow(_ task: TaskItem, router: AppRouter?) {
        let previous = task.dueDate
        Haptics.pop(0.6)
        let tomorrow = Date.now.startOfDay.adding(days: 1)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if task.hasTime, let due = task.dueDate {
                let parts = Calendar.current.dateComponents([.hour, .minute], from: due)
                task.dueDate = Calendar.current.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0,
                                                     second: 0, of: tomorrow)
            } else {
                task.dueDate = tomorrow
            }
        }
        TaskAlerts.schedule(task)
        SovaRefresh.changed(task.modelContext)
        router?.show(Toast(message: String(localized: "Moved to tomorrow")) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { task.dueDate = previous }
            TaskAlerts.schedule(task)
            SovaRefresh.changed(task.modelContext)
        })
    }
}
