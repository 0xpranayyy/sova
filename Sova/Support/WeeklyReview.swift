import Foundation
import FoundationModels

/// A look back at the last seven days: the wins, one slip, and one small
/// suggestion for the week ahead. Worked out on the device from your own
/// history; Apple Intelligence, where it's on, words it in the owl's voice.
struct WeeklyReview: Equatable {
    var tasksDone: Int
    var checkIns: Int
    var bestStreak: Int
    var bestStreakRitual: String?
    /// The ritual kept least often this week, if it slipped below 60%.
    var slip: String?
    var slipKept: Int = 0
    var slipScheduled: Int = 0
    var suggestion: String

    /// The review shows on Sundays and Mondays, between one week and the next.
    static var isReviewTime: Bool { [1, 2].contains(Date.now.weekday) }

    /// One key per week, so a dismissed review stays away until next week.
    static var weekKey: Int {
        let today = Date.now.startOfDay
        let sunday = today.weekday == 1 ? today : today.adding(days: -(today.weekday - 1))
        return Int(sunday.timeIntervalSinceReferenceDate / 86_400)
    }

    init(tasks: [TaskItem], routines: [Routine], goals: [Goal]) {
        let since = Date.now.startOfDay.adding(days: -6)
        let finished = tasks.filter { $0.isDone && ($0.completedAt ?? .distantPast) >= since }.count
        let kept = routines.reduce(0) { total, routine in total + routine.completions.filter { $0 >= since }.count }
        tasksDone = finished
        checkIns = kept
        let best = routines.max { $0.streak < $1.streak }
        let streak = best?.streak ?? 0
        bestStreak = streak
        bestStreakRitual = streak > 1 ? best?.title : nil

        // The weakest ritual this week, counted on the days it was due.
        var weakest: (title: String, kept: Int, scheduled: Int, share: Double)?
        for routine in routines {
            var scheduled = 0, keptDays = 0
            for offset in 1...7 {
                let day = Date.now.startOfDay.adding(days: -offset)
                guard day >= routine.createdAt.startOfDay, routine.isScheduled(on: day) else { continue }
                scheduled += 1
                if routine.isDone(on: day) { keptDays += 1 }
            }
            guard scheduled >= 2 else { continue }
            let share = Double(keptDays) / Double(scheduled)
            guard share < 0.6, share < (weakest?.share ?? 1) else { continue }
            weakest = (routine.title, keptDays, scheduled, share)
        }
        slip = weakest?.title
        slipKept = weakest?.kept ?? 0
        slipScheduled = weakest?.scheduled ?? 0

        let stuck = tasks.filter(\.keepsSlipping).max { $0.deferCount < $1.deferCount }
        let behind = goals.first { $0.isBehindPace }
        let done = finished + kept
        if let weak = weakest?.title {
            suggestion = String(localized: "Make \(weak) easier this week: a smaller version, or fewer days.")
        } else if let stuck {
            suggestion = String(localized: "“\(stuck.title)” keeps moving. Break it into small steps and do the first.")
        } else if let behind {
            suggestion = String(localized: "Give \(behind.title) one step this week.")
        } else if done == 0 {
            suggestion = String(localized: "Start small: one task and one ritual a day.")
        } else {
            suggestion = String(localized: "Keep the rhythm. Same again this week.")
        }
    }

    var hasAnything: Bool { tasksDone + checkIns > 0 || slip != nil }

    /// The plain version, used when Apple Intelligence isn't available.
    var template: String {
        var lines: [String] = []
        if tasksDone + checkIns > 0 {
            lines.append(String(localized: "You finished \(tasksDone) tasks and kept \(checkIns) rituals this week."))
        }
        if let ritual = bestStreakRitual {
            lines.append(String(localized: "\(ritual) is on a \(bestStreak) day streak."))
        }
        lines.append(suggestion)
        return lines.joined(separator: " ")
    }

    // MARK: Apple Intelligence

    @Generable
    struct Note {
        @Guide(description: "Two or three short, warm sentences: celebrate the wins with the real numbers, mention the slip kindly if there is one, end with the suggestion")
        var text: String
    }

    /// The owl's version of the review. Falls back to the template.
    func phrased() async -> String {
        guard SystemLanguageModel.default.isAvailable else { return template }
        let session = LanguageModelSession(instructions: """
            You are Sova, a kind owl in a personal planner app, writing a short weekly review. \
            Use only the facts given. Plain words, no emoji, no lists, no headings, under 50 words.
            """)
        var facts = ["Tasks finished this week: \(tasksDone)", "Ritual check-ins this week: \(checkIns)"]
        if let ritual = bestStreakRitual { facts.append("Longest streak: \(ritual), \(bestStreak) days") }
        if let slip { facts.append("Slipped: \(slip), kept \(slipKept) of \(slipScheduled) days") }
        facts.append("Suggestion for next week: \(suggestion)")
        do {
            let response = try await session.respond(to: facts.joined(separator: "\n"), generating: Note.self)
            let text = response.content.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? template : text
        } catch {
            return template
        }
    }
}
