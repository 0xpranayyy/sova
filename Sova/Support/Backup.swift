import Foundation
import SwiftData

/// Everything in Sova as one readable JSON file, for safekeeping or moving.
enum Backup {
    private struct File: Encodable {
        let app = "Sova"
        let version = 1
        let exportedAt: Date
        let tasks: [TaskRecord]
        let rituals: [RitualRecord]
        let goals: [GoalRecord]
    }

    private struct TaskRecord: Encodable {
        let title: String, notes: String, due: Date?, hasTime: Bool, priority: Int
        let done: Bool, completedAt: Date?, repeats: String, goal: String?, checklist: [ChecklistItem]
    }

    private struct RitualRecord: Encodable {
        let title: String, symbol: String, period: String, weekdays: [Int]
        let target: Int, completions: [Date], createdAt: Date
    }

    private struct GoalRecord: Encodable {
        let title: String, notes: String, deadline: Date?, progress: Double, archived: Bool
        let steps: [Step]
        struct Step: Encodable { let title: String; let done: Bool }
    }

    /// Writes the backup to a temporary file and returns where it is.
    @MainActor
    static func write(from context: ModelContext) throws -> URL {
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let routines = (try? context.fetch(FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.order)]))) ?? []
        let goals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        let file = File(
            exportedAt: .now,
            tasks: tasks.map {
                TaskRecord(title: $0.title, notes: $0.notes, due: $0.dueDate, hasTime: $0.hasTime,
                           priority: $0.priorityRaw, done: $0.isDone, completedAt: $0.completedAt,
                           repeats: $0.repeatRaw, goal: $0.goal?.title, checklist: $0.checklist)
            },
            rituals: routines.map {
                RitualRecord(title: $0.title, symbol: $0.symbol, period: $0.periodRaw, weekdays: $0.weekdays,
                             target: $0.target, completions: $0.completions, createdAt: $0.createdAt)
            },
            goals: goals.map {
                GoalRecord(title: $0.title, notes: $0.notes, deadline: $0.deadline, progress: $0.progress,
                           archived: $0.isArchived,
                           steps: $0.sortedMilestones.map { .init(title: $0.title, done: $0.isDone) })
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(file)
        let name = "Sova Backup " + Date.now.formatted(.iso8601.year().month().day()) + ".json"
        let url = URL.temporaryDirectory.appending(path: name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
