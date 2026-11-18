import Foundation
import SwiftData

/// A friendly first-launch dataset so the app never opens to a blank screen.
enum SampleData {
    @MainActor
    static func seedIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<TaskItem>())) ?? 0
        let existingRoutines = (try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0
        guard existing == 0, existingRoutines == 0 else { return }

        let today = Date.now.startOfDay
        let cal = Calendar.current
        func at(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: today.adding(days: dayOffset)) ?? today
        }

        // Goals
        let marathon = Goal(title: "Run a half marathon", emoji: "🏃", deadline: today.adding(days: 74), accent: .coral)
        let reading = Goal(title: "Read 24 books this year", emoji: "📚", deadline: today.adding(days: 43), accent: .iris)
        reading.manualProgress = 0.71
        let launch = Goal(title: "Launch my side project", emoji: "🚀", deadline: today.adding(days: 21), accent: .lagoon)
        for goal in [marathon, reading, launch] { context.insert(goal) }

        for (i, item) in [("Run 5K without stopping", true), ("10K under 60 minutes", true),
                          ("Long run: 15K", false), ("Race day", false)].enumerated() {
            marathon.milestones.append(Milestone(title: item.0, order: i, isDone: item.1))
        }
        for (i, item) in [("Validate the idea with 10 people", true), ("Design the landing page", true),
                          ("Build the MVP", false), ("Private beta", false), ("Public launch", false)].enumerated() {
            launch.milestones.append(Milestone(title: item.0, order: i, isDone: item.1))
        }

        // Tasks
        let tasks: [TaskItem] = [
            TaskItem(title: "Plan the week ahead", dueDate: today, priority: .high, accent: .iris),
            TaskItem(title: "Call Mom", dueDate: at(18, 30), hasTime: true, accent: .rose),
            TaskItem(title: "Pick up groceries", notes: "Oat milk, berries, coffee beans", dueDate: today, accent: .mint),
            TaskItem(title: "Write landing page copy", dueDate: today.adding(days: 1), priority: .medium, accent: .lagoon, goal: launch),
            TaskItem(title: "Book a dentist appointment", dueDate: today.adding(days: 3), accent: .sky),
            TaskItem(title: "Buy new running shoes", dueDate: today.adding(days: 5), accent: .coral, goal: marathon),
        ]
        for task in tasks { context.insert(task) }

        // A few completed tasks spread over the past week, for Insights.
        let doneCounts = [2, 4, 1, 3, 5, 2, 1]
        let doneTitles = ["Inbox zero", "Pay rent", "Laundry", "Reply to Sam", "Water the plants",
                          "Update résumé", "Team sync notes", "Renew library card"]
        var titleIndex = 0
        for (offset, count) in doneCounts.enumerated() {
            for n in 0..<count {
                let title = doneTitles[titleIndex % doneTitles.count]
                titleIndex += 1
                let t = TaskItem(title: title, dueDate: today.adding(days: offset - 6), accent: Accent.allCases[titleIndex % Accent.allCases.count])
                t.isDone = true
                t.completedAt = at(9 + n, dayOffset: offset - 6)
                context.insert(t)
            }
        }

        // Routines with some history
        let created = today.adding(days: -30)
        let routines: [Routine] = [
            Routine(title: "Meditate", symbol: "leaf.fill", accent: .mint, period: .morning, order: 0, createdAt: created),
            Routine(title: "Stretch", symbol: "figure.flexibility", accent: .lagoon, period: .morning, order: 1, createdAt: created),
            Routine(title: "Deep work", symbol: "brain.head.profile", accent: .iris, period: .afternoon,
                    weekdays: [2, 3, 4, 5, 6], order: 2, createdAt: created),
            Routine(title: "Drink water", symbol: "drop.fill", accent: .sky, period: .anytime, order: 3, createdAt: created),
            Routine(title: "Journal", symbol: "book.closed.fill", accent: .orchid, period: .evening, order: 4, createdAt: created),
            Routine(title: "Read 20 pages", symbol: "books.vertical.fill", accent: .peach, period: .evening, order: 5, createdAt: created),
        ]
        for (index, routine) in routines.enumerated() {
            for offset in 1...30 {
                let day = today.adding(days: -offset)
                // Deterministic "mostly consistent" pattern, recent days always kept.
                let skip = offset > 4 && (offset * 7 + index * 3) % 5 == 0
                if routine.isScheduled(on: day) && !skip {
                    routine.completions.append(day.addingTimeInterval(9 * 3600))
                }
            }
            context.insert(routine)
        }
        routines[0].completions.append(at(7, 15))
        routines[3].completions.append(at(10))
    }
}
