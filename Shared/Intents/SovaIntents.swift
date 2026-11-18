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
        guard let routine = RitualStore.find(ritual.id) else {
            return .result(dialog: "I couldn't find that ritual.")
        }
        routine.toggle(on: .now)
        try? RitualStore.context.save()
        WidgetCenter.shared.reloadAllTimelines()
        let done = routine.isDone(on: .now)
        let message = done ? String(localized: "Nice! \(routine.title) is done. 🦉")
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
        let context = SovaStore.shared.mainContext
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        guard let task = tasks.first(where: { $0.alertID == taskID }) else { return .result() }
        task.toggle()
        if task.isDone { task.spawnNextOccurrence() }
        TaskAlerts.schedule(task)
        try? context.save()
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
        let parsed = QuickParse.parse(text)
        let title = parsed.title.isEmpty ? text : parsed.title
        let task = TaskItem(title: title, dueDate: parsed.dueDate ?? Date.now.startOfDay,
                            hasTime: parsed.dueDate != nil && parsed.hasTime,
                            priority: parsed.priority, accent: SovaTheme.current.accent)
        task.repeatRule = parsed.repeatRule
        let context = SovaStore.shared.mainContext
        context.insert(task)
        try? context.save()
        TaskAlerts.schedule(task)
        SovaRefresh.changed(context)
        let when = (task.dueDate ?? .now).relativeDayText(includingTime: task.hasTime)
        return .result(dialog: "Added “\(title)” for \(when).")
    }
}
