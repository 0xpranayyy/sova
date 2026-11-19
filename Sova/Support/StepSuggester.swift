import Foundation
import FoundationModels

/// Breaks a goal into a few first steps with Apple Intelligence, on the
/// device. Nothing leaves the phone. Hidden where the model isn't available.
enum StepSuggester {
    @Generable
    struct Plan {
        @Guide(description: "Between three and six short, concrete first steps toward the goal, each under seven words, in the order to do them")
        var steps: [String]
    }

    static var isAvailable: Bool { SystemLanguageModel.default.isAvailable }

    static func suggest(for goal: String, notes: String = "") async throws -> [String] {
        let session = LanguageModelSession(instructions: """
            You help someone plan a personal goal in a friendly to-do app. \
            Reply with small, concrete, doable steps. No numbering, no emoji, no extra words.
            """)
        var prompt = "Goal: \(goal)"
        if !notes.isEmpty { prompt += "\nWhy it matters: \(notes)" }
        let response = try await session.respond(to: prompt, generating: Plan.self)
        return response.content.steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(6)
            .map { $0 }
    }
}
