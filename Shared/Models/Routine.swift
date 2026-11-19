import Foundation
import SwiftData

enum DayPeriod: String, CaseIterable, Identifiable {
    case morning, afternoon, evening, anytime

    var id: String { rawValue }

    var name: String {
        switch self {
        case .morning: String(localized: "Morning")
        case .afternoon: String(localized: "Afternoon")
        case .evening: String(localized: "Evening")
        case .anytime: String(localized: "Anytime")
        }
    }

    var symbol: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        case .anytime: "clock"
        }
    }
}

@Model
final class Routine {
    var title: String = ""
    var symbol: String = "sun.max"
    var accentRaw: String = Accent.lagoon.rawValue
    var periodRaw: String = DayPeriod.morning.rawValue
    /// Calendar weekday numbers, 1 = Sunday … 7 = Saturday.
    var weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    var completions: [Date] = []
    var createdAt: Date = Date.now
    var order: Int = 0
    /// How many times a day it counts as done: 1 for a plain check, 8 for
    /// "Drink water 8 glasses".
    var target: Int = 1
    /// Each tap toward the target, for rituals with a target above 1.
    var taps: [Date] = []
    /// A daily reminder at this many minutes after midnight, or -1 for none.
    var reminderMinutes: Int = -1

    init(
        title: String,
        symbol: String,
        accent: Accent,
        period: DayPeriod,
        weekdays: [Int] = Array(1...7),
        order: Int = 0,
        createdAt: Date = .now
    ) {
        self.title = title
        self.symbol = symbol
        self.accentRaw = accent.rawValue
        self.periodRaw = period.rawValue
        self.weekdays = weekdays
        self.order = order
        self.createdAt = createdAt
    }

    var accent: Accent {
        get { Accent(rawValue: accentRaw) ?? .lagoon }
        set { accentRaw = newValue.rawValue }
    }

    var period: DayPeriod {
        get { DayPeriod(rawValue: periodRaw) ?? .anytime }
        set { periodRaw = newValue.rawValue }
    }

    func isScheduled(on date: Date) -> Bool { weekdays.contains(date.weekday) }

    func isDone(on date: Date) -> Bool { completions.contains { $0.isSameDay(as: date) } }

    /// How far along today's count is: 0…target.
    func tally(on date: Date) -> Int {
        if isDone(on: date) { return max(target, 1) }
        return taps.filter { $0.isSameDay(as: date) }.count
    }

    var isCounted: Bool { target > 1 }

    /// One tap on the ritual's check. Plain rituals flip; counted ones add one
    /// until the target is reached. A tap on a finished ritual undoes the day.
    func advance(on date: Date) {
        if isDone(on: date) {
            completions.removeAll { $0.isSameDay(as: date) }
            taps.removeAll { $0.isSameDay(as: date) }
            return
        }
        guard isCounted else {
            completions.append(date)
            return
        }
        taps.removeAll { !$0.isSameDay(as: date) }
        taps.append(date)
        if taps.filter({ $0.isSameDay(as: date) }).count >= target {
            completions.append(date)
        }
    }

    func toggle(on date: Date) {
        if isDone(on: date) {
            completions.removeAll { $0.isSameDay(as: date) }
        } else {
            completions.append(date)
        }
    }

    /// Consecutive scheduled days completed. Today only counts once it's done,
    /// so an unfinished today never breaks the streak.
    var streak: Int {
        var day = Date.now.startOfDay
        if !isDone(on: day) { day = day.adding(days: -1) }
        let start = createdAt.startOfDay
        var count = 0
        for _ in 0..<400 {
            if day < start { break }
            if isScheduled(on: day) {
                guard isDone(on: day) else { break }
                count += 1
            }
            day = day.adding(days: -1)
        }
        return count
    }

    /// Share of scheduled days completed over the last `days` days (including today).
    func consistency(days: Int) -> Double {
        let today = Date.now.startOfDay
        var scheduled = 0, done = 0
        for offset in 0..<days {
            let day = today.adding(days: -offset)
            if day < createdAt.startOfDay { break }
            guard isScheduled(on: day) else { continue }
            scheduled += 1
            if isDone(on: day) { done += 1 }
        }
        return scheduled == 0 ? 0 : Double(done) / Double(scheduled)
    }
}
