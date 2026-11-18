import Foundation
import SwiftData

/// Rituals offered during onboarding, and how they become routines.
struct RitualOption: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let accent: Accent
    let period: DayPeriod
    var weekdays: [Int] = Array(1...7)

    static let all: [RitualOption] = [
        RitualOption(id: "pages", title: "Morning pages", symbol: "pencil.and.scribble", accent: .plum, period: .morning),
        RitualOption(id: "meditate", title: "Meditate", symbol: "wind", accent: .lagoon, period: .morning),
        RitualOption(id: "move", title: "Move your body", symbol: "figure.walk", accent: .ember, period: .morning),
        RitualOption(id: "water", title: "Drink water", symbol: "drop", accent: .tide, period: .anytime),
        RitualOption(id: "deep", title: "Deep work", symbol: "scope", accent: .graphite, period: .afternoon,
                     weekdays: [2, 3, 4, 5, 6]),
        RitualOption(id: "read", title: "Read", symbol: "book.closed", accent: .marigold, period: .evening),
        RitualOption(id: "plan", title: "Plan tomorrow", symbol: "checklist", accent: .clay, period: .evening),
        RitualOption(id: "unplug", title: "Screens off by ten", symbol: "moon", accent: .moss, period: .evening),
    ]
}

enum StarterContent {
    /// Called when onboarding finishes. Adds the chosen rituals (skipping
    /// any that already exist) and two gentle first tasks.
    @MainActor
    static func install(rituals: [RitualOption], theme: SovaTheme, in context: ModelContext) {
        let existingRoutines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        let existingTitles = Set(existingRoutines.map(\.title))
        var order = (existingRoutines.map(\.order).max() ?? -1) + 1
        for ritual in rituals where !existingTitles.contains(ritual.title) {
            context.insert(Routine(title: ritual.title, symbol: ritual.symbol, accent: ritual.accent,
                                   period: ritual.period, weekdays: ritual.weekdays, order: order))
            order += 1
        }

        let taskCount = (try? context.fetchCount(FetchDescriptor<TaskItem>())) ?? 0
        guard taskCount == 0 else { return }
        let today = Date.now.startOfDay
        context.insert(TaskItem(title: "Tick this off, it feels good", dueDate: today, accent: theme.accent))
        context.insert(TaskItem(title: "Set your first goal", notes: "Something you'd be proud of in three months.",
                                dueDate: today, priority: .medium, accent: theme.accent))
    }
}

/// A lived-in dataset for SwiftUI previews.
enum SampleData {
    @MainActor
    static func seed(_ context: ModelContext) {
        let today = Date.now.startOfDay
        let cal = Calendar.current
        func at(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: today.adding(days: dayOffset)) ?? today
        }

        let marathon = Goal(title: "Run a half marathon", symbol: "figure.run", deadline: today.adding(days: 74), accent: .ember)
        let reading = Goal(title: "Read 24 books this year", symbol: "book.closed", deadline: today.adding(days: 43), accent: .marigold)
        reading.manualProgress = 0.71
        let launch = Goal(title: "Launch the side project", symbol: "paperplane", deadline: today.adding(days: 21), accent: .tide)
        for goal in [marathon, reading, launch] { context.insert(goal) }

        for (i, item) in [("Run 5K without stopping", true), ("10K under an hour", true),
                          ("Long run, 15K", false), ("Race day", false)].enumerated() {
            marathon.milestones.append(Milestone(title: item.0, order: i, isDone: item.1))
        }
        for (i, item) in [("Talk to ten potential users", true), ("Landing page", true),
                          ("Build the MVP", false), ("Private beta", false)].enumerated() {
            launch.milestones.append(Milestone(title: item.0, order: i, isDone: item.1))
        }

        let tasks: [TaskItem] = [
            TaskItem(title: "Plan the week", dueDate: today, priority: .high, accent: .ember),
            TaskItem(title: "Call Mom", dueDate: at(18, 30), hasTime: true, accent: .rose),
            TaskItem(title: "Groceries", notes: "Oat milk, berries, coffee", dueDate: today, accent: .moss),
            TaskItem(title: "Write landing page copy", dueDate: today.adding(days: 1), priority: .medium, accent: .tide, goal: launch),
            TaskItem(title: "Book the dentist", dueDate: today.adding(days: 3), accent: .lagoon),
        ]
        for task in tasks { context.insert(task) }

        let doneTitles = ["Inbox zero", "Pay rent", "Laundry", "Reply to Sam", "Water the plants", "Update résumé"]
        for (offset, count) in [2, 4, 1, 3, 5, 2, 1].enumerated() {
            for n in 0..<count {
                let t = TaskItem(title: doneTitles[(offset + n) % doneTitles.count], dueDate: today.adding(days: offset - 6))
                t.isDone = true
                t.completedAt = at(9 + n, dayOffset: offset - 6)
                context.insert(t)
            }
        }

        let created = today.adding(days: -30)
        for (index, ritual) in RitualOption.all.prefix(6).enumerated() {
            let routine = Routine(title: ritual.title, symbol: ritual.symbol, accent: ritual.accent,
                                  period: ritual.period, weekdays: ritual.weekdays, order: index, createdAt: created)
            for offset in 1...30 {
                let day = today.adding(days: -offset)
                let skip = offset > 4 && (offset * 7 + index * 3) % 5 == 0
                if routine.isScheduled(on: day) && !skip { routine.completions.append(day.addingTimeInterval(9 * 3600)) }
            }
            if index < 2 { routine.completions.append(at(7, 30)) }
            context.insert(routine)
        }
    }

    @MainActor
    static var previewContainer: ModelContainer = {
        let container = try! ModelContainer(
            for: TaskItem.self, Goal.self, Milestone.self, Routine.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        seed(container.mainContext)
        return container
    }()
}
