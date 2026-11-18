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
    var goal: Goal?

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
        get { Accent(rawValue: accentRaw) ?? .ink }
        set { accentRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard let dueDate, !isDone else { return false }
        return hasTime ? dueDate < .now : dueDate < Date.now.startOfDay
    }

    var isDueTodayOrEarlier: Bool {
        guard let dueDate else { return true } // undated tasks live in Today
        return dueDate < Date.now.endOfDay
    }

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
