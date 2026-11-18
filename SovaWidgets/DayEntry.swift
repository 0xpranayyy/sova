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

    var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    var allDone: Bool { total > 0 && done == total }
    var ritualsDone: Int { rituals.filter(\.done).count }

    static let placeholder = DayEntry(
        date: .now, done: 3, total: 5,
        next: NextItem(title: String(localized: "Call Mom"), time: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: .now)),
        rituals: []
    )
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
        let todays = RitualStore.all().filter { $0.isScheduled(on: now) }

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

        let rituals = todays.map { routine in
            RitualItem(id: routine.entityID, title: routine.title, symbol: routine.symbol,
                       tone: StickerTone(routine.accent), done: routine.isDone(on: now),
                       entity: RitualEntity(routine))
        }
        return DayEntry(date: now, done: done, total: total, next: next, rituals: rituals)
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
            // Refresh at midnight, or just after the next timed task.
            var refresh = Date.now.startOfDay.adding(days: 1)
            if let time = entry.next?.time, time > .now, time < refresh {
                refresh = time.addingTimeInterval(60)
            }
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}
