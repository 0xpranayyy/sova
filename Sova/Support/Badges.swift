import Foundation

/// A badge: a sticker of the owl in a costume, earned by doing things in
/// Sova. Locked badges know how close you are.
struct Badge: Identifiable, Equatable {
    let id: String
    /// The sticker art in the asset catalog: "badge-<art>" and "badge-<art>-art".
    let art: String
    let title: String
    let howTo: String
    /// One line for the unlock moment: what you did.
    let story: String
    let tone: StickerTone
    let earned: Bool
    /// 0…1 toward earning it.
    let progress: Double
    /// "34 / 100", "5 / 7 days", "after 11 PM".
    let progressText: String

    var sticker: String { "badge-\(art)" }
    var silhouette: String { "badge-\(art)-art" }

    static func all(index: ActivityIndex, routines: [Routine], goals: [Goal], weekKept: Double) -> [Badge] {
        let streak = routines.map(\.streak).max() ?? 0
        let done = index.tasksDone
        let bestGoal = goals.map(\.progress).max() ?? 0
        func count(_ value: Int, of target: Int, unit: String = "") -> (Double, String) {
            (min(Double(value) / Double(target), 1), "\(min(value, target)) / \(target)\(unit)")
        }
        let ten = count(done, of: 10), hundred = count(done, of: 100)
        let week = count(streak, of: 7, unit: String(localized: " days"))
        let month = count(streak, of: 30, unit: String(localized: " days"))
        let keptDays = Int((weekKept * 7).rounded(.down))
        return [
            Badge(id: "first", art: "first", title: String(localized: "First tick"),
                  howTo: String(localized: "Finish your first task."),
                  story: String(localized: "Your very first task, done. Every streak starts here."),
                  tone: .mint, earned: done >= 1, progress: done >= 1 ? 1 : 0,
                  progressText: done >= 1 ? "1 / 1" : "0 / 1"),
            Badge(id: "ten", art: "ten", title: String(localized: "Ten down"),
                  howTo: String(localized: "Finish 10 tasks."),
                  story: String(localized: "Ten tasks finished. The owl brought a balloon."),
                  tone: .yellow, earned: done >= 10, progress: ten.0, progressText: ten.1),
            Badge(id: "hundred", art: "hundred", title: String(localized: "Centurion"),
                  howTo: String(localized: "Finish 100 tasks."),
                  story: String(localized: "A hundred tasks. Wear the crown."),
                  tone: .pink, earned: done >= 100, progress: hundred.0, progressText: hundred.1),
            Badge(id: "week", art: "fire", title: String(localized: "On fire"),
                  howTo: String(localized: "Keep a 7-day streak."),
                  story: String(localized: "7 days in a row. The owl is genuinely impressed."),
                  tone: .orange, earned: streak >= 7, progress: week.0, progressText: week.1),
            Badge(id: "month", art: "moon", title: String(localized: "Moon cycle"),
                  howTo: String(localized: "Keep a 30-day streak."),
                  story: String(localized: "A whole moon of showing up. Rest easy."),
                  tone: .lilac, earned: streak >= 30, progress: month.0, progressText: month.1),
            Badge(id: "perfect", art: "perfect", title: String(localized: "Perfect week"),
                  howTo: String(localized: "Keep every ritual for 7 days."),
                  story: String(localized: "Every ritual, every day, all week. Too cool."),
                  tone: .cyan, earned: !routines.isEmpty && weekKept >= 1,
                  progress: routines.isEmpty ? 0 : min(weekKept, 1),
                  progressText: "\(min(keptDays, 7)) / 7" + String(localized: " days")),
            Badge(id: "goal", art: "goal", title: String(localized: "Goal getter"),
                  howTo: String(localized: "Reach 100% on a goal."),
                  story: String(localized: "A goal, all the way to 100%. Trophy time."),
                  tone: .lime, earned: bestGoal >= 1, progress: bestGoal,
                  progressText: "\(Int((bestGoal * 100).rounded()))%"),
            Badge(id: "night", art: "night", title: String(localized: "Night owl"),
                  howTo: String(localized: "Finish a task after 11 PM."),
                  story: String(localized: "Done after 11 PM. A true night owl, like me."),
                  tone: .indigo, earned: index.nightOwl, progress: 0,
                  progressText: String(localized: "after 11 PM")),
            Badge(id: "early", art: "early", title: String(localized: "Early bird"),
                  howTo: String(localized: "Finish a task before 7 AM."),
                  story: String(localized: "Done before 7 AM. Coffee's on the owl."),
                  tone: .orange, earned: index.earlyBird, progress: 0,
                  progressText: String(localized: "before 7 AM")),
        ]
    }

    /// The share of scheduled ritual days kept over the last 7 days.
    static func weekKept(_ routines: [Routine]) -> Double {
        let today = Date.now.startOfDay
        var scheduled = 0, done = 0
        for routine in routines {
            let start = routine.createdAt.startOfDay
            for offset in 0..<7 {
                let day = today.adding(days: -offset)
                guard day >= start, routine.isScheduled(on: day) else { continue }
                scheduled += 1
                if routine.isDone(on: day) { done += 1 }
            }
        }
        return scheduled == 0 ? 0 : Double(done) / Double(scheduled)
    }

    /// The closest badge you haven't earned yet.
    static func next(in badges: [Badge]) -> Badge? {
        badges.filter { !$0.earned && $0.progress > 0 }.max { $0.progress < $1.progress }
    }
}

/// Which badges you've earned and which you haven't looked at yet, so a new
/// one gets its moment exactly once.
enum BadgeBook {
    private static let earnedKey = "badges.earned"
    private static let unseenKey = "badges.unseen"
    private static var defaults: UserDefaults { .standard }

    static var unseen: [String] { defaults.stringArray(forKey: unseenKey) ?? [] }

    /// Records what's earned now and returns the badges that are new since
    /// last time. The first time it runs it only records, so people who had
    /// badges before this update don't get a flood of celebrations.
    static func sync(_ earned: Set<String>) -> [String] {
        guard let known = defaults.stringArray(forKey: earnedKey) else {
            defaults.set(Array(earned), forKey: earnedKey)
            return []
        }
        let fresh = earned.subtracting(known)
        guard !fresh.isEmpty else { return [] }
        defaults.set(Array(earned.union(known)), forKey: earnedKey)
        defaults.set(Array(Set(unseen).union(fresh)), forKey: unseenKey)
        return Array(fresh)
    }

    static func markSeen() { defaults.removeObject(forKey: unseenKey) }
}
