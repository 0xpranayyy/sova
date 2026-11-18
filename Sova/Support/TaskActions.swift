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
        let lowered = task.title.lowercased()
        let owlish = ["owl", "sova", "hoot"].contains { lowered.contains($0) }
        if owlish { Haptics.owl() }
        let message = owlish ? String(localized: "Hoo hoo! The owl approves. 🦉")
            : next?.dueDate.map { String(localized: "Done! Next: \($0.relativeDayText(includingTime: false))") }
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

    private static func spawnNext(after task: TaskItem) -> TaskItem? {
        task.spawnNextOccurrence()
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
    /// Pulls a task forward to today, keeping its time of day.
    static func moveToToday(_ task: TaskItem, router: AppRouter?) {
        let previous = task.dueDate
        Haptics.pop(0.6, sound: true)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            task.dueDate = sameTime(as: task, on: Date.now.startOfDay)
        }
        TaskAlerts.schedule(task)
        SovaRefresh.changed(task.modelContext)
        router?.show(Toast(message: String(localized: "Moved to today")) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { task.dueDate = previous }
            TaskAlerts.schedule(task)
            SovaRefresh.changed(task.modelContext)
        })
    }

    /// Brings every overdue task to today in one go, with one Undo.
    static func moveOverdueToToday(_ tasks: [TaskItem], router: AppRouter?) {
        guard !tasks.isEmpty else { return }
        let previous = tasks.map(\.dueDate)
        Haptics.pop(0.7, sound: true)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            for task in tasks { task.dueDate = sameTime(as: task, on: Date.now.startOfDay) }
        }
        for task in tasks { TaskAlerts.schedule(task) }
        SovaRefresh.changed(tasks.first?.modelContext)
        router?.show(Toast(message: tasks.count == 1 ? String(localized: "Moved 1 task to today")
                                                     : String(localized: "Moved \(tasks.count) tasks to today")) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                for (task, due) in zip(tasks, previous) { task.dueDate = due }
            }
            for task in tasks { TaskAlerts.schedule(task) }
            SovaRefresh.changed(tasks.first?.modelContext)
        })
    }

    /// The task's date moved to `day`, keeping the time if it has one.
    private static func sameTime(as task: TaskItem, on day: Date) -> Date {
        guard task.hasTime, let due = task.dueDate else { return day }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: due)
        return Calendar.current.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0, second: 0, of: day) ?? day
    }

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
