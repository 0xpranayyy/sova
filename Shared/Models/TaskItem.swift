import Foundation
import SwiftData
import SwiftUI

enum Priority: Int, CaseIterable, Identifiable {
    case low = 0, medium, high

    var id: Int { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    /// Exclamation marks, the way people actually write urgency.
    var marks: String {
        switch self {
        case .low: ""
        case .medium: "!!"
        case .high: "!!!"
        }
    }

    var color: Color {
        switch self {
        case .low: .inkTertiary
        case .medium: Accent.marigold.color
        case .high: Accent.ember.color
        }
    }
}

/// How a task comes back after it's done.
enum RepeatRule: String, CaseIterable, Identifiable {
    case none, daily, weekdays, weekly, monthly, yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: String(localized: "Never")
        case .daily: String(localized: "Every day")
        case .weekdays: String(localized: "Weekdays")
        case .weekly: String(localized: "Every week")
        case .monthly: String(localized: "Every month")
        case .yearly: String(localized: "Every year")
        }
    }

    /// The next date after `date` (keeps the time of day).
    func step(_ date: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .none: return nil
        case .daily: return cal.date(byAdding: .day, value: 1, to: date)
        case .weekly: return cal.date(byAdding: .day, value: 7, to: date)
        case .monthly: return cal.date(byAdding: .month, value: 1, to: date)
        case .yearly: return cal.date(byAdding: .year, value: 1, to: date)
        case .weekdays:
            var next = cal.date(byAdding: .day, value: 1, to: date) ?? date
            while [1, 7].contains(cal.component(.weekday, from: next)) {
                next = cal.date(byAdding: .day, value: 1, to: next) ?? next
            }
            return next
        }
    }

    /// The first occurrence after `date` that lands today or later, so a
    /// repeating task finished late doesn't come back already overdue.
    func next(after date: Date) -> Date? {
        guard var next = step(date) else { return nil }
        let today = Date.now.startOfDay
        for _ in 0..<800 where next < today {
            guard let n = step(next) else { break }
            next = n
        }
        return next
    }
}

/// One line of a task's checklist.
struct ChecklistItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var title: String
    var done = false
}

@Model
final class TaskItem {
    var title: String = ""
    var notes: String = ""
    var dueDate: Date?
    var hasTime: Bool = false
    var priorityRaw: Int = 0
    var accentRaw: String = Accent.ember.rawValue
    var isDone: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date.now
    var repeatRaw: String = RepeatRule.none.rawValue
    var goal: Goal?
    /// Small steps inside the task, like "passport, charger" for "Pack".
    var checklist: [ChecklistItem] = []

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        hasTime: Bool = false,
        priority: Priority = .low,
        accent: Accent = .ember,
        goal: Goal? = nil
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.priorityRaw = priority.rawValue
        self.accentRaw = accent.rawValue
        self.goal = goal
        self.createdAt = .now
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .low }
        set { priorityRaw = newValue.rawValue }
    }

    var accent: Accent {
        get { Accent(rawValue: accentRaw) ?? .ember }
        set { accentRaw = newValue.rawValue }
    }

    var repeatRule: RepeatRule {
        get { RepeatRule(rawValue: repeatRaw) ?? .none }
        set { repeatRaw = newValue.rawValue }
    }

    /// A stable id for this task's notification.
    var alertID: String { "sova.task.\(Int(createdAt.timeIntervalSinceReferenceDate * 1000))" }

    var isOverdue: Bool {
        guard let dueDate, !isDone else { return false }
        return hasTime ? dueDate < .now : dueDate < Date.now.startOfDay
    }

    var isDueTodayOrEarlier: Bool {
        guard let dueDate else { return true } // undated tasks live in Today
        return dueDate < Date.now.endOfDay
    }

    var checklistDone: Int { checklist.filter(\.done).count }

    func toggle() {
        isDone.toggle()
        completedAt = isDone ? .now : nil
    }

    /// Higher priority first, then earliest due date, then newest.
    static func ordering(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.priorityRaw != b.priorityRaw { return a.priorityRaw > b.priorityRaw }
        let ad = a.dueDate ?? .distantFuture, bd = b.dueDate ?? .distantFuture
        if ad != bd { return ad < bd }
        return a.createdAt > b.createdAt
    }
}
