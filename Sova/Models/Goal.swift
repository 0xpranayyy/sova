import Foundation
import SwiftData

@Model
final class Goal {
    var title: String = ""
    var symbol: String = "flag.checkered"
    var notes: String = ""
    var deadline: Date?
    var accentRaw: String = Accent.tide.rawValue
    /// Used when the goal has no milestones.
    var manualProgress: Double = 0
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Milestone.goal)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.goal)
    var tasks: [TaskItem] = []

    init(title: String, symbol: String = "flag.checkered", notes: String = "", deadline: Date? = nil, accent: Accent = .tide) {
        self.title = title
        self.symbol = symbol
        self.notes = notes
        self.deadline = deadline
        self.accentRaw = accent.rawValue
        self.createdAt = .now
    }

    var accent: Accent {
        get { Accent(rawValue: accentRaw) ?? .tide }
        set { accentRaw = newValue.rawValue }
    }

    var sortedMilestones: [Milestone] {
        milestones.sorted { $0.order < $1.order }
    }

    var completedMilestones: Int { milestones.filter(\.isDone).count }

    var progress: Double {
        guard !milestones.isEmpty else { return min(max(manualProgress, 0), 1) }
        return Double(completedMilestones) / Double(milestones.count)
    }

    var daysLeft: Int? {
        guard let deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: deadline.startOfDay).day
    }

    var deadlineText: String? {
        guard let days = daysLeft else { return nil }
        switch days {
        case ..<0: return String(localized: "\(-days)d overdue")
        case 0: return String(localized: "Due today")
        case 1: return String(localized: "1 day left")
        default: return String(localized: "\(days) days left")
        }
    }
}

@Model
final class Milestone {
    var title: String = ""
    var isDone: Bool = false
    var order: Int = 0
    var goal: Goal?

    init(title: String, order: Int, isDone: Bool = false) {
        self.title = title
        self.order = order
        self.isDone = isDone
    }
}
