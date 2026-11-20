import Foundation

// What the iPhone tells the Watch about today, and what the Watch asks the
// iPhone to do. Plain Codable values only: this file is compiled into the
// iPhone app, the Watch app and the Watch complications.

/// Today, as the Watch shows it. The iPhone is the source of truth and
/// sends a fresh one after every change.
struct WatchDay: Codable, Equatable {
    var date: Date
    var name: String
    var done: Int
    var total: Int
    var streak: Int
    var next: WatchNext?
    var rituals: [WatchRitual]
    var tasks: [WatchTask]

    var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    var allDone: Bool { total > 0 && done == total }
    /// The snapshot is from an earlier day: show it as stale, not as today.
    var isFromToday: Bool { Calendar.current.isDateInToday(date) }

    static let empty = WatchDay(date: .distantPast, name: "", done: 0, total: 0, streak: 0,
                                next: nil, rituals: [], tasks: [])

    /// Recounts done and total after the Watch ticks something itself.
    mutating func recount() {
        done = tasks.filter(\.done).count + rituals.filter(\.done).count
        total = tasks.count + rituals.count
    }
}

struct WatchNext: Codable, Equatable {
    var title: String
    var time: Date?
}

struct WatchTask: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var time: Date?
    /// "", "!!" or "!!!".
    var marks: String
    /// A sticker tone name, e.g. "pink".
    var tone: String
    var done: Bool
    var overdue: Bool
}

struct WatchRitual: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var symbol: String
    var tone: String
    var tally: Int
    var target: Int
    var done: Bool

    var isCounted: Bool { target > 1 }

    /// One tap, the same rule as on the iPhone: count up to the target, or
    /// toggle a simple ritual.
    mutating func advance() {
        if isCounted {
            tally = tally >= target ? 0 : tally + 1
            done = tally >= target
        } else {
            done.toggle()
            tally = done ? 1 : 0
        }
    }
}

/// Something the Watch asks the iPhone to do.
enum WatchAction: Codable, Equatable {
    case toggleTask(id: String)
    case tapRitual(id: String)
    case addTask(text: String)
}

enum WatchKeys {
    /// Application context and messages carry one JSON blob under this key.
    static let day = "sova.day"
    static let action = "sova.action"
    /// Where the Watch keeps the last day it got, for the app and complications.
    static let appGroup = "group.app.sova.Sova"
    static let storedDay = "watch.day"
}

extension WatchDay {
    func encoded() -> Data? { try? JSONEncoder().encode(self) }
    static func decode(_ data: Data?) -> WatchDay? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(WatchDay.self, from: data)
    }
}

extension WatchAction {
    func encoded() -> Data? { try? JSONEncoder().encode(self) }
    static func decode(_ data: Data?) -> WatchAction? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(WatchAction.self, from: data)
    }
}
