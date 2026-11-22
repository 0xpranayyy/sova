import Foundation

/// The owl's one line about your day, picked from what's actually going on,
/// in order of what matters most right now. Shown under the day card on
/// Today, and when you pull Today down.
enum DayBriefing {
    @MainActor
    static func line(tasks: [TaskItem], routines: [Routine], goals: [Goal], now: Date = .now) -> String {
        // 1. Overdue things come first.
        let overdue = tasks.filter(\.isOverdue)
        if overdue.count == 1 {
            return String(localized: "“\(overdue[0].title)” is overdue. Today, or tomorrow?")
        }
        if overdue.count > 1 {
            return String(localized: "\(overdue.count) things are overdue. Want them on today?")
        }

        // 2. In the evening, a streak that's about to break.
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 17,
           let ritual = routines.filter({ $0.isScheduled(on: now) && !$0.isDone(on: now) && $0.streak >= 3 })
               .max(by: { $0.streak < $1.streak }) {
            return String(localized: "Keep it going: \(ritual.title) is on a \(ritual.streak)-day streak.")
        }

        // 3. Something with a time in the next three hours.
        let soon = tasks.filter { task in
            guard !task.isDone, task.hasTime, let due = task.dueDate else { return false }
            return due > now && due < now.addingTimeInterval(3 * 3600)
        }
        .min { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        if let soon, let due = soon.dueDate {
            return String(localized: "Coming up: \(soon.title) at \(due.formatted(date: .omitted, time: .shortened)).")
        }

        // 4. A goal close to its deadline that's still far from done.
        if let goal = goals.first(where: { goal in
            guard !goal.isArchived, goal.progress < 0.8, let days = goal.daysLeft else { return false }
            return days >= 0 && days <= 7
        }), let days = goal.daysLeft {
            let percent = Int((goal.progress * 100).rounded())
            return days == 0
                ? String(localized: "“\(goal.title)” is due today, \(percent)% there. One step?")
                : String(localized: "“\(goal.title)”: \(days) days left, \(percent)% there.")
        }

        // 5. How the day looks.
        let left = tasks.filter { !$0.isDone && $0.isDueTodayOrEarlier }.count
            + routines.filter { $0.isScheduled(on: now) && !$0.isDone(on: now) }.count
        let doneToday = tasks.filter { $0.isDone && ($0.completedAt?.isSameDay(as: now) ?? false) }.count
            + routines.filter { $0.isDone(on: now) }.count
        if left == 0 {
            return doneToday > 0 ? String(localized: "All done for today. Proud of you.")
                                 : String(localized: "A clear day. Add something, or just enjoy it.")
        }
        if left <= 3 { return String(localized: "\(left) left. A light day.") }
        return String(localized: "\(left) left. One thing at a time.")
    }
}
