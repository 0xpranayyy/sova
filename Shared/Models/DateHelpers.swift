import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? self }
    var weekday: Int { Calendar.current.component(.weekday, from: self) }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// "Today", "Tomorrow", "Nov 21" — optionally with a time.
    func relativeDayText(includingTime: Bool) -> String {
        let cal = Calendar.current
        var text: String
        if cal.isDateInToday(self) { text = String(localized: "Today") }
        else if cal.isDateInTomorrow(self) { text = String(localized: "Tomorrow") }
        else if cal.isDateInYesterday(self) { text = String(localized: "Yesterday") }
        else { text = formatted(.dateTime.month(.abbreviated).day()) }
        if includingTime {
            text += " · " + formatted(date: .omitted, time: .shortened)
        }
        return text
    }
}

extension Calendar {
    /// The user's calendar with the week-start setting applied.
    static var sova: Calendar {
        var cal = Calendar.current
        switch SovaSettings.weekStart {
        case 1: cal.firstWeekday = 1   // Sunday
        case 2: cal.firstWeekday = 2   // Monday
        default: break
        }
        return cal
    }
}

enum Weekdays {
    /// Calendar weekday numbers (1 = Sunday) ordered by the user's locale.
    static var ordered: [Int] {
        let first = Calendar.sova.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    static func shortSymbol(_ weekday: Int) -> String {
        Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    static func letter(_ weekday: Int) -> String {
        Calendar.current.veryShortWeekdaySymbols[weekday - 1]
    }

    static func summary(for days: [Int]) -> String {
        let set = Set(days)
        switch set {
        case Set(1...7): return String(localized: "Every day")
        case [2, 3, 4, 5, 6]: return String(localized: "Weekdays")
        case [1, 7]: return String(localized: "Weekends")
        case []: return String(localized: "Never")
        default: return ordered.filter(set.contains).map(shortSymbol).joined(separator: " ")
        }
    }
}
