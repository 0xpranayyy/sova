import Foundation

/// What a line of natural language means: "Call Mom tomorrow at 6pm !!"
struct ParsedTask: Equatable {
    var title: String
    var dueDate: Date?
    var hasTime: Bool
    var priority: Priority
    /// Where the date phrase and priority marks sit in the original text,
    /// so the field can highlight what it understood.
    var dateRange: Range<String.Index>?
    var priorityRange: Range<String.Index>?
    var repeatRule: RepeatRule = .none
    var repeatRange: Range<String.Index>?
}

enum QuickParse {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    /// Phrases that mean the user named a time of day, not just a day.
    private static let timePattern = try? NSRegularExpression(
        pattern: #"(\d{1,2}(:\d{2})?\s*(am|pm|a\.m\.|p\.m\.))|(\d{1,2}:\d{2})|\b(noon|midnight|tonight|morning|afternoon|evening)\b"#,
        options: [.caseInsensitive]
    )

    /// "every day", "every Monday", "weekly"…
    private static let repeatPattern = try? NSRegularExpression(
        pattern: #"\b(every\s+(day|weekday|week|month|year|sunday|monday|tuesday|wednesday|thursday|friday|saturday)|daily|weekly|monthly|yearly|on weekdays)\b"#,
        options: [.caseInsensitive]
    )

    private static let weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    private static let danglingWords = ["on", "at", "by", "due", "for", "before"]

    static func parse(_ input: String) -> ParsedTask {
        var priority: Priority = .low
        var priorityRange: Range<String.Index>?
        if let range = input.range(of: "!!!") {
            priority = .high
            priorityRange = range
        } else if let range = input.range(of: "!!") {
            priority = .medium
            priorityRange = range
        }

        // Repeats first, blanked out so the date detector doesn't read
        // "every Monday" as a single Monday.
        var repeatRule: RepeatRule = .none
        var repeatRange: Range<String.Index>?
        var repeatWeekday: Int?
        var scan = input
        if let m = repeatPattern?.firstMatch(in: input, range: NSRange(location: 0, length: (input as NSString).length)),
           let r = Range(m.range, in: input) {
            let phrase = input[r].lowercased()
            repeatRange = r
            if phrase.contains("weekday") { repeatRule = .weekdays }
            else if let i = weekdayNames.firstIndex(where: { phrase.contains($0) }) { repeatRule = .weekly; repeatWeekday = i + 1 }
            else if phrase.contains("day") || phrase == "daily" { repeatRule = .daily }
            else if phrase.contains("week") { repeatRule = .weekly }
            else if phrase.contains("month") { repeatRule = .monthly }
            else if phrase.contains("year") { repeatRule = .yearly }
            scan.replaceSubrange(r, with: String(repeating: " ", count: input[r].count))
        }

        var dueDate: Date?
        var hasTime = false
        var dateRange: Range<String.Index>?
        let ns = scan as NSString
        if let match = detector?.firstMatch(in: scan, range: NSRange(location: 0, length: ns.length)),
           let date = match.date,
           let range = Range(match.range, in: input) {  // same UTF-16 offsets: the blanked phrase is ASCII
            let phrase = String(input[range])
            let phraseRange = NSRange(location: 0, length: (phrase as NSString).length)
            hasTime = timePattern?.firstMatch(in: phrase, range: phraseRange) != nil
            dueDate = hasTime ? date : date.startOfDay
            dateRange = range
        }

        // A repeat with no date starts today; "every Monday" starts on the
        // next Monday, keeping any time that was typed ("every Monday 9am").
        if repeatRule != .none {
            var day = dueDate ?? Date.now.startOfDay
            if let wd = repeatWeekday {
                while day.weekday != wd { day = day.adding(days: 1) }
            }
            dueDate = day
        }

        var title = input
        let removals = [dateRange, priorityRange, repeatRange].compactMap { $0 }.sorted { $0.lowerBound > $1.lowerBound }
        for range in removals where range.upperBound <= title.endIndex {
            title.replaceSubrange(range, with: " ")
        }
        var words = title.split(whereSeparator: \.isWhitespace).map(String.init)
        while let last = words.last, danglingWords.contains(last.lowercased()) { words.removeLast() }
        let cleaned = words.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,;-"))

        return ParsedTask(title: cleaned, dueDate: dueDate, hasTime: hasTime, priority: priority,
                          dateRange: dateRange, priorityRange: priorityRange,
                          repeatRule: repeatRule, repeatRange: repeatRange)
    }
}
