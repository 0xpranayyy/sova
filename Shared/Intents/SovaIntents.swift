import AppIntents
import SwiftData
import WidgetKit

/// Ticks (or unticks) today's ritual. Used by Siri and by the interactive widget.
struct ToggleRitualIntent: AppIntent {
    static let title: LocalizedStringResource = "Tick Off a Ritual"
    static let description = IntentDescription("Marks one of today's rituals as done, or not done.")

    @Parameter(title: "Ritual")
    var ritual: RitualEntity

    init() {}
    init(ritual: RitualEntity) { self.ritual = ritual }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = SovaStore.workContext()
        guard let routine = RitualStore.find(ritual.id, in: context) else {
            return .result(dialog: "I couldn't find that ritual.")
        }
        routine.advance(on: .now)
        SovaRefresh.changed(context)
        let done = routine.isDone(on: .now)
        let tally = routine.tally(on: .now)
        let message = done ? String(localized: "Nice! \(routine.title) is done. 🦉")
            : tally > 0 ? String(localized: "\(routine.title): \(tally) of \(routine.target).")
            : String(localized: "Okay, \(routine.title) is open again.")
        return .result(dialog: "\(message)")
    }
}

/// Ticks (or unticks) a task from the widget's check button.
struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Tick Off a Task"
    static let isDiscoverable = false

    @Parameter(title: "Task")
    var taskID: String

    init() {}
    init(taskID: String) { self.taskID = taskID }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = SovaStore.workContext()
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        guard let task = tasks.first(where: { $0.alertID == taskID }) else { return .result() }
        if task.isDone {
            // Unticking: take back the next occurrence that ticking created,
            // and hand its repeat back, the same as Undo in the app.
            if task.repeatRule == .none, let finished = task.completedAt,
               let spawned = tasks.first(where: { other in
                   !other.isDone && other !== task && other.repeatRule != .none
                       && other.title == task.title && other.goal == task.goal
                       && other.createdAt >= finished.addingTimeInterval(-2)
               }) {
                task.repeatRaw = spawned.repeatRaw
                TaskAlerts.cancel(spawned)
                context.delete(spawned)
            }
            task.toggle()
        } else {
            task.toggle()
            task.spawnNextOccurrence()
        }
        TaskAlerts.schedule(task)
        SovaRefresh.changed(context)
        return .result()
    }
}

/// "Add buy milk tomorrow 6pm to Sova": parsed the same way as quick capture.
struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a Task"
    static let description = IntentDescription("Adds a task. Dates, times, repeats and !! priority are understood.")

    @Parameter(title: "Task", requestValueDialog: "What do you need to do?")
    var text: String

    init() {}
    init(text: String) { self.text = text }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = SovaStore.workContext()
        let goals = (try? context.fetch(FetchDescriptor<Goal>(predicate: #Predicate<Goal> { !$0.isArchived }))) ?? []
        let parsed = QuickParse.parse(text, goals: goals.map(\.title))
        let title = parsed.title.isEmpty ? text : parsed.title
        let task = TaskItem(title: title, dueDate: parsed.dueDate ?? Date.now.startOfDay,
                            hasTime: parsed.dueDate != nil && parsed.hasTime,
                            priority: parsed.priority, accent: SovaTheme.current.accent)
        task.repeatRule = parsed.repeatRule
        if let i = parsed.goalIndex, goals.indices.contains(i) { task.goal = goals[i] }
        context.insert(task)
        try? context.save()
        TaskAlerts.schedule(task)
        SovaRefresh.changed(context)
        let when = (task.dueDate ?? .now).relativeDayText(includingTime: task.hasTime)
        return .result(dialog: "Added “\(title)” for \(when).")
    }
}

/// Opens Sova straight into quick capture. Used by the Control Center and
/// Lock Screen button, and by Shortcuts.
struct OpenQuickCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "New Task in Sova"
    static let description = IntentDescription("Opens Sova ready to type a new task.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SovaSettings.shared.set(LaunchAction.quickTask.rawValue, forKey: SovaSettings.Key.pendingAction)
        return .result()
    }
}

/// Something to do as soon as the app is on screen: from a Home Screen quick
/// action, a control, or a notification.
enum LaunchAction: String {
    case quickTask, newRitual, today, tasks
}
