import Foundation
import SwiftData

/// Rituals offered during onboarding, and how they become routines.
struct RitualOption: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let accent: Accent
    let period: DayPeriod
    var weekdays: [Int] = Array(1...7)

    static let all: [RitualOption] = [
        RitualOption(id: "pages", title: "Morning pages", symbol: "pencil.and.scribble", accent: .plum, period: .morning),
        RitualOption(id: "meditate", title: "Meditate", symbol: "wind", accent: .lagoon, period: .morning),
        RitualOption(id: "move", title: "Move your body", symbol: "figure.walk", accent: .ember, period: .morning),
        RitualOption(id: "water", title: "Drink water", symbol: "drop", accent: .tide, period: .anytime),
        RitualOption(id: "deep", title: "Deep work", symbol: "scope", accent: .graphite, period: .afternoon,
                     weekdays: [2, 3, 4, 5, 6]),
        RitualOption(id: "read", title: "Read", symbol: "book.closed", accent: .marigold, period: .evening),
        RitualOption(id: "plan", title: "Plan tomorrow", symbol: "checklist", accent: .clay, period: .evening),
        RitualOption(id: "unplug", title: "Screens off by ten", symbol: "moon", accent: .moss, period: .evening),
    ]
}

/// Goal ideas offered during onboarding.
struct GoalSuggestion: Identifiable, Hashable {
    let title: String
    let symbol: String
    let accent: Accent
    var id: String { title }
    var tone: StickerTone { StickerTone(accent) }

    static let all: [GoalSuggestion] = [
        GoalSuggestion(title: "Run a 10K", symbol: "figure.run", accent: .ember),
        GoalSuggestion(title: "Read 12 books", symbol: "book.closed", accent: .marigold),
        GoalSuggestion(title: "Learn to cook five dishes", symbol: "fork.knife", accent: .clay),
        GoalSuggestion(title: "Save for a trip", symbol: "airplane", accent: .tide),
        GoalSuggestion(title: "Ship a side project", symbol: "paperplane", accent: .plum),
        GoalSuggestion(title: "Sleep before midnight", symbol: "moon", accent: .moss),
    ]
}

/// Turns onboarding choices into real data. Nothing else is created: no
/// placeholder tasks, no sample content.
enum StarterContent {
    @MainActor
    static func install(rituals: [RitualOption], goalTitle: String, theme: SovaTheme, in context: ModelContext) {
        defer { SovaRefresh.changed(context) }
        let existingRoutines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        let existingTitles = Set(existingRoutines.map(\.title))
        var order = (existingRoutines.map(\.order).max() ?? -1) + 1
        var total = existingRoutines.count
        for ritual in rituals where !existingTitles.contains(ritual.title) && PlusGate.canAddRitual(existing: total) {
            total += 1
            context.insert(Routine(title: ritual.title, symbol: ritual.symbol, accent: ritual.accent,
                                   period: ritual.period, weekdays: ritual.weekdays, order: order))
            order += 1
        }

        let title = goalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let existingGoals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        guard !existingGoals.contains(where: { $0.title == title }) else { return }
        let suggestion = GoalSuggestion.all.first { $0.title == title }
        context.insert(Goal(
            title: title,
            symbol: suggestion?.symbol ?? "flag.checkered",
            deadline: Date.now.startOfDay.adding(days: 90),
            accent: suggestion?.accent ?? theme.accent
        ))
    }
}
