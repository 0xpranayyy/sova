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
    let goal: Goal?

    init(_ task: TaskItem) {
        title = task.title; notes = task.notes; dueDate = task.dueDate; hasTime = task.hasTime
        priorityRaw = task.priorityRaw; accentRaw = task.accentRaw; isDone = task.isDone
        completedAt = task.completedAt; createdAt = task.createdAt; goal = task.goal
    }

    func restore(in context: ModelContext) {
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate, hasTime: hasTime)
        task.priorityRaw = priorityRaw
        task.accentRaw = accentRaw
        task.isDone = isDone
        task.completedAt = completedAt
        task.createdAt = createdAt
        task.goal = goal
        context.insert(task)
    }
}

@MainActor
enum TaskActions {
    static func toggle(_ task: TaskItem, router: AppRouter?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { task.toggle() }
        guard task.isDone, let router else { return }
        router.show(Toast(message: String(localized: "Done: \(task.title)")) {
            // Only reopen it if it's still done (it may have been unticked since).
            guard task.isDone else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { task.toggle() }
        })
    }

    static func delete(_ task: TaskItem, context: ModelContext, router: AppRouter?) {
        let snapshot = TaskSnapshot(task)
        Haptics.warning()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { context.delete(task) }
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
        router?.show(Toast(message: String(localized: "Moved to tomorrow")) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { task.dueDate = previous }
        })
    }
}
