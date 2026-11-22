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
    /// Which of the goals passed in the text named ("for Marathon", "#marathon").
    var goalIndex: Int?
    var goalRange: Range<String.Index>?
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

    /// "in 2 hours", "in 30 min", "in 2h", "in an hour", "in half an hour".
    private static let relativePattern = try? NSRegularExpression(
        pattern: #"\bin\s+(\d{1,3}|an?|half an)\s*(h|hr|hrs|hours?|m|mins?|minutes?)\b"#,
        options: [.caseInsensitive]
    )

    private static let weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    private static let danglingWords = ["on", "at", "by", "due", "for", "before"]

    /// Finds a goal named in the text: "#word" matching the start of a goal's
    /// name (spaces ignored), or "for <goal name>".
    private static func findGoal(in input: String, goals: [String]) -> (Int, Range<String.Index>)? {
        guard !goals.isEmpty else { return nil }
        let squashed = goals.map { $0.lowercased().filter { !$0.isWhitespace } }
        if let tag = try? NSRegularExpression(pattern: #"#([\p{L}\p{N}_-]+)"#),
           let m = tag.firstMatch(in: input, range: NSRange(location: 0, length: (input as NSString).length)),
           let whole = Range(m.range, in: input), let word = Range(m.range(at: 1), in: input) {
            let key = input[word].lowercased()
            if let i = squashed.firstIndex(of: key) ?? squashed.firstIndex(where: { $0.hasPrefix(key) }) {
                return (i, whole)
            }
        }
        // Longest names first, so "Run a marathon" beats "Run".
        for i in goals.indices.sorted(by: { goals[$0].count > goals[$1].count }) {
            let name = goals[i].trimmingCharacters(in: .whitespaces)
            guard name.count >= 2,
                  let r = input.range(of: "for " + name, options: [.caseInsensitive, .diacriticInsensitive]) else { continue }
            // Only whole words: the name must end at a word boundary.
            if r.upperBound < input.endIndex, input[r.upperBound].isLetter || input[r.upperBound].isNumber { continue }
            return (i, r)
        }
        return nil
    }

    /// Blanks a phrase out of `scan` with spaces, keeping every UTF-16
    /// offset the same so ranges found in `scan` still fit `input`.
    private static func blank(_ range: Range<String.Index>, of input: String, in scan: inout String) {
        let ns = NSRange(range, in: input)
        scan = (scan as NSString).replacingCharacters(in: ns, with: String(repeating: " ", count: ns.length))
    }

    static func parse(_ input: String, goals: [String] = []) -> ParsedTask {
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

        // A goal named in the text, blanked so "for Friday drinks" isn't a date.
        let goalMatch = findGoal(in: input, goals: goals)
        if let r = goalMatch?.1 { blank(r, of: input, in: &scan) }
        if let m = repeatPattern?.firstMatch(in: scan, range: NSRange(location: 0, length: (scan as NSString).length)),
           let r = Range(m.range, in: input) {
            let phrase = input[r].lowercased()
            repeatRange = r
            if phrase.contains("weekday") { repeatRule = .weekdays }
            else if let i = weekdayNames.firstIndex(where: { phrase.contains($0) }) { repeatRule = .weekly; repeatWeekday = i + 1 }
            else if phrase.contains("day") || phrase == "daily" { repeatRule = .daily }
            else if phrase.contains("week") { repeatRule = .weekly }
            else if phrase.contains("month") { repeatRule = .monthly }
            else if phrase.contains("year") { repeatRule = .yearly }
            blank(r, of: input, in: &scan)
        }

        var dueDate: Date?
        var hasTime = false
        var dateRange: Range<String.Index>?
        let ns = scan as NSString
        if let m = relativePattern?.firstMatch(in: scan, range: NSRange(location: 0, length: ns.length)),
           let range = Range(m.range, in: input),
           let amountRange = Range(m.range(at: 1), in: input), let unitRange = Range(m.range(at: 2), in: input) {
            let amountText = input[amountRange].lowercased()
            let amount: Double = amountText == "half an" ? 0.5 : (Double(amountText) ?? 1)
            let minutes = input[unitRange].lowercased().hasPrefix("h") ? amount * 60 : amount
            // Rounded up to the next 5 minutes: "in 2 hours" at 3:12 is 5:15.
            let raw = Date.now.addingTimeInterval(minutes * 60)
            let step = 5.0 * 60
            dueDate = Date(timeIntervalSinceReferenceDate: (raw.timeIntervalSinceReferenceDate / step).rounded(.up) * step)
            hasTime = true
            dateRange = range
        } else if let match = detector?.firstMatch(in: scan, range: NSRange(location: 0, length: ns.length)),
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
        let removals = [dateRange, priorityRange, repeatRange, goalMatch?.1].compactMap { $0 }.sorted { $0.lowerBound > $1.lowerBound }
        var floor = title.endIndex
        for range in removals where range.upperBound <= floor {  // skip any that overlap
            title.replaceSubrange(range, with: " ")
            floor = range.lowerBound
        }
        var words = title.split(whereSeparator: \.isWhitespace).map(String.init)
        while let last = words.last, danglingWords.contains(last.lowercased()) { words.removeLast() }
        let cleaned = words.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,;-"))

        return ParsedTask(title: cleaned, dueDate: dueDate, hasTime: hasTime, priority: priority,
                          dateRange: dateRange, priorityRange: priorityRange,
                          repeatRule: repeatRule, repeatRange: repeatRange,
                          goalIndex: goalMatch?.0, goalRange: goalMatch?.1)
    }
}
