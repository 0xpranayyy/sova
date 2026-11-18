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
}

enum QuickParse {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    /// Phrases that mean the user named a time of day, not just a day.
    private static let timePattern = try? NSRegularExpression(
        pattern: #"(\d{1,2}(:\d{2})?\s*(am|pm|a\.m\.|p\.m\.))|(\d{1,2}:\d{2})|\b(noon|midnight|tonight|morning|afternoon|evening)\b"#,
        options: [.caseInsensitive]
    )

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

        var dueDate: Date?
        var hasTime = false
        var dateRange: Range<String.Index>?
        let ns = input as NSString
        if let match = detector?.firstMatch(in: input, range: NSRange(location: 0, length: ns.length)),
           let date = match.date,
           let range = Range(match.range, in: input) {
            let phrase = String(input[range])
            let phraseRange = NSRange(location: 0, length: (phrase as NSString).length)
            hasTime = timePattern?.firstMatch(in: phrase, range: phraseRange) != nil
            dueDate = hasTime ? date : date.startOfDay
            dateRange = range
        }

        var title = input
        let removals = [dateRange, priorityRange].compactMap { $0 }.sorted { $0.lowerBound > $1.lowerBound }
        for range in removals where range.upperBound <= title.endIndex {
            title.replaceSubrange(range, with: " ")
        }
        var words = title.split(whereSeparator: \.isWhitespace).map(String.init)
        while let last = words.last, danglingWords.contains(last.lowercased()) { words.removeLast() }
        let cleaned = words.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,;-"))

        return ParsedTask(title: cleaned, dueDate: dueDate, hasTime: hasTime, priority: priority,
                          dateRange: dateRange, priorityRange: priorityRange)
    }
}
