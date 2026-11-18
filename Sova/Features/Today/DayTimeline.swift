import SwiftUI

/// Where an item sits in the day.
enum DaySection: Int, CaseIterable, Identifiable {
    case overdue, morning, afternoon, evening, anytime

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .overdue: String(localized: "Overdue")
        case .morning: String(localized: "Morning")
        case .afternoon: String(localized: "Afternoon")
        case .evening: String(localized: "Evening")
        case .anytime: String(localized: "Anytime")
        }
    }

    var range: String? {
        switch self {
        case .morning: "06—12"
        case .afternoon: "12—18"
        case .evening: "18—24"
        default: nil
        }
    }

    /// Minutes since midnight where the section starts, for ordering.
    var startMinutes: Int {
        switch self {
        case .overdue: -1
        case .morning: 0
        case .afternoon: 12 * 60
        case .evening: 18 * 60
        case .anytime: 24 * 60
        }
    }

    static func forHour(_ hour: Int) -> DaySection {
        switch hour {
        case 0..<12: .morning
        case 12..<18: .afternoon
        default: .evening
        }
    }

    static func forPeriod(_ period: DayPeriod) -> DaySection {
        switch period {
        case .morning: .morning
        case .afternoon: .afternoon
        case .evening: .evening
        case .anytime: .anytime
        }
    }

    static var current: DaySection { forHour(Calendar.current.component(.hour, from: .now)) }
}

/// One thing on today's timeline: a task or a ritual.
struct TimelineEntry: Identifiable {
    enum Source {
        case task(TaskItem)
        case routine(Routine)
    }

    let source: Source
    let section: DaySection
    let sortKey: Int

    var id: String {
        switch source {
        case .task(let t): "t-\(ObjectIdentifier(t).hashValue)"
        case .routine(let r): "r-\(ObjectIdentifier(r).hashValue)"
        }
    }

    var isDone: Bool {
        switch source {
        case .task(let t): t.isDone
        case .routine(let r): r.isDone(on: .now)
        }
    }

    var isRoutine: Bool {
        if case .routine = source { return true }
        return false
    }

    /// The scheduled time for timed tasks.
    var dueTime: Date? {
        if case .task(let t) = source, t.hasTime { return t.dueDate }
        return nil
    }

    static func build(tasks: [TaskItem], routines: [Routine]) -> [TimelineEntry] {
        let cal = Calendar.current
        var entries: [TimelineEntry] = []
        for task in tasks {
            let relevant = task.isDone
                ? (task.completedAt?.isSameDay(as: .now) ?? false)
                : task.isDueTodayOrEarlier
            guard relevant else { continue }
            let section: DaySection
            var key: Int
            if !task.isDone, let due = task.dueDate, due < Date.now.startOfDay {
                section = .overdue
                key = Int(due.timeIntervalSince1970 / 60)
            } else if task.hasTime, let due = task.dueDate {
                let comps = cal.dateComponents([.hour, .minute], from: due)
                section = .forHour(comps.hour ?? 9)
                key = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            } else {
                section = .anytime
                key = DaySection.anytime.startMinutes + 500
                    + Int(task.createdAt.timeIntervalSince1970.truncatingRemainder(dividingBy: 10_000))
            }
            if task.priority == .high && section == .anytime { key -= 400 }
            entries.append(TimelineEntry(source: .task(task), section: section, sortKey: key))
        }
        for routine in routines where routine.isScheduled(on: .now) {
            let section = DaySection.forPeriod(routine.period)
            entries.append(TimelineEntry(source: .routine(routine), section: section,
                                         sortKey: section.startMinutes + 1 + routine.order))
        }
        return entries.sorted { ($0.section.rawValue, $0.sortKey) < ($1.section.rawValue, $1.sortKey) }
    }
}

