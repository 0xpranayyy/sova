import Foundation

/// What a line of natural language means: "Call Mom tomorrow at 6pm !!"
struct ParsedTask: Equatable {
    var title: String
    var dueDate: Date?
    var hasTime: Bool
    var priority: Priority
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
        var text = input
        var priority: Priority = .low
        if let range = text.range(of: "!!!") {
            priority = .high
            text.removeSubrange(range)
        } else if let range = text.range(of: "!!") {
            priority = .medium
            text.removeSubrange(range)
        }

        var dueDate: Date?
        var hasTime = false
        let ns = text as NSString
        if let match = detector?.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           let date = match.date {
            let phrase = ns.substring(with: match.range)
            let phraseRange = NSRange(location: 0, length: (phrase as NSString).length)
            hasTime = timePattern?.firstMatch(in: phrase, range: phraseRange) != nil
            dueDate = hasTime ? date : date.startOfDay
            text = ns.replacingCharacters(in: match.range, with: " ")
        }

        var words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        while let last = words.last, danglingWords.contains(last.lowercased()) { words.removeLast() }
        let title = words.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,;-"))

        return ParsedTask(title: title, dueDate: dueDate, hasTime: hasTime, priority: priority)
    }
}
