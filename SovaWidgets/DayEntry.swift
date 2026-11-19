import WidgetKit
import SwiftData
import SwiftUI

struct RitualItem: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let tone: StickerTone
    let done: Bool
    let entity: RitualEntity
    var tally: Int = 0
    var target: Int = 1
}

struct TaskRowItem: Identifiable {
    let id: String
    let title: String
    let time: Date?
    let priority: Priority
    let tone: StickerTone
    let done: Bool
    let overdue: Bool
}

struct NextItem {
    let title: String
    let time: Date?
}

/// Today, as the widgets show it.
struct DayEntry: TimelineEntry {
    let date: Date
    let done: Int
    let total: Int
    let next: NextItem?
    let rituals: [RitualItem]
    /// Open tasks first (soonest and most urgent on top), then the ones
    /// already done today.
    var tasks: [TaskRowItem] = []
    var streak: Int = 0
    var name: String = ""
    /// The last seven days, oldest first, today last: the share of scheduled
    /// rituals kept, or nil on a day with nothing scheduled.
    var week: [Double?] = []

    var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    var allDone: Bool { total > 0 && done == total }
    var ritualsDone: Int { rituals.filter(\.done).count }
    var openTasks: Int { tasks.filter { !$0.done }.count }

    var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: date) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return name.isEmpty ? base : base + ", " + name
    }

    /// What the widget gallery shows before there's real data.
    static let placeholder: DayEntry = {
        let today = Date.now
        func at(_ hour: Int, _ minute: Int = 0) -> Date {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
        }
        func ritual(_ n: Int, _ title: String, _ symbol: String, _ tone: StickerTone, _ done: Bool) -> RitualItem {
            RitualItem(id: "sample-\(n)", title: title, symbol: symbol, tone: tone, done: done,
                       entity: RitualEntity(id: "sample-\(n)", title: title, symbol: symbol))
        }
        return DayEntry(
            date: today, done: 4, total: 7,
            next: NextItem(title: String(localized: "Call Mom"), time: at(18)),
            rituals: [
                RitualItem(id: "sample-1", title: String(localized: "Drink water"), symbol: "drop", tone: .cyan,
                           done: false, entity: RitualEntity(id: "sample-1", title: String(localized: "Drink water"), symbol: "drop"),
                           tally: 5, target: 8),
                ritual(2, String(localized: "Read"), "book.closed", .yellow, true),
                ritual(3, String(localized: "Morning walk"), "figure.walk", .orange, false),
                ritual(4, String(localized: "Stretch"), "figure.flexibility", .lilac, false),
                ritual(5, String(localized: "Journal"), "pencil.line", .pink, true),
                ritual(6, String(localized: "Screens off"), "moon", .lime, false),
            ],
            tasks: [
                TaskRowItem(id: "t1", title: String(localized: "Call Mom"), time: at(18), priority: .high,
                            tone: .pink, done: false, overdue: false),
                TaskRowItem(id: "t2", title: String(localized: "Book dentist"), time: nil, priority: .medium,
                            tone: .orange, done: false, overdue: false),
                TaskRowItem(id: "t3", title: String(localized: "Buy flowers"), time: at(19, 30), priority: .low,
                            tone: .mint, done: false, overdue: false),
                TaskRowItem(id: "t4", title: String(localized: "Send the deck"), time: at(10), priority: .low,
                            tone: .cyan, done: true, overdue: false),
            ],
            streak: 6,
            week: [0.6, 1, 0.8, 1, 0.4, 1, 0.5]
        )
    }()
}

enum DaySnapshot {
    @MainActor
    static func make() -> DayEntry {
        let now = Date.now
        let context = SovaStore.shared.mainContext
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let relevant = tasks.filter { task in
            task.isDone ? (task.completedAt?.isSameDay(as: now) ?? false) : task.isDueTodayOrEarlier
        }
        let routines = RitualStore.all()
        let todays = routines.filter { $0.isScheduled(on: now) }

        let done = relevant.filter(\.isDone).count + todays.filter { $0.isDone(on: now) }.count
        let total = relevant.count + todays.count

        let open = relevant.filter { !$0.isDone }.sorted(by: TaskItem.ordering)
        let upcoming = open.filter { $0.hasTime && ($0.dueDate ?? .distantPast) >= now }
            .min { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        var next: NextItem?
        if let task = upcoming ?? open.first {
            next = NextItem(title: task.title, time: task.hasTime ? task.dueDate : nil)
        } else if let ritual = todays.first(where: { !$0.isDone(on: now) }) {
            next = NextItem(title: ritual.title, time: nil)
        }

        // The next timed task leads, then the rest by urgency, then today's done.
        var ordered = open
        if let upcoming, let index = ordered.firstIndex(where: { $0 === upcoming }) {
            ordered.insert(ordered.remove(at: index), at: 0)
        }
        let finished = relevant.filter(\.isDone)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        let rows = (ordered + finished).prefix(6).map { task in
            TaskRowItem(id: task.alertID, title: task.title, time: task.hasTime ? task.dueDate : nil,
                        priority: task.priority, tone: StickerTone(task.accent), done: task.isDone,
                        overdue: task.isOverdue)
        }

        let rituals = todays.map { routine in
            RitualItem(id: routine.entityID, title: routine.title, symbol: routine.symbol,
                       tone: StickerTone(routine.accent), done: routine.isDone(on: now),
                       entity: RitualEntity(routine), tally: routine.tally(on: now), target: routine.target)
        }

        let week: [Double?] = (0..<7).reversed().map { offset in
            let day = now.startOfDay.adding(days: -offset)
            let scheduled = routines.filter { $0.isScheduled(on: day) && $0.createdAt.startOfDay <= day }
            guard !scheduled.isEmpty else { return nil }
            return Double(scheduled.filter { $0.isDone(on: day) }.count) / Double(scheduled.count)
        }

        return DayEntry(date: now, done: done, total: total, next: next, rituals: rituals,
                        tasks: Array(rows), streak: routines.map(\.streak).max() ?? 0,
                        name: SovaSettings.shared.string(forKey: SovaSettings.Key.userName) ?? "",
                        week: week)
    }
}

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        Task { @MainActor in
            completion(context.isPreview ? .placeholder : DaySnapshot.make())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        Task { @MainActor in
            let entry = DaySnapshot.make()
            // Refresh at midnight, just after the next timed task, and at the
            // top of the next greeting (morning, afternoon, evening).
            var refresh = Date.now.startOfDay.adding(days: 1)
            if let time = entry.next?.time, time > .now, time < refresh {
                refresh = time.addingTimeInterval(60)
            }
            for hour in [5, 12, 17, 22] {
                if let mark = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now),
                   mark > .now, mark < refresh {
                    refresh = mark
                }
            }
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}
