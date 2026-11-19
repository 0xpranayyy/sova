import AppIntents
import SwiftData

/// A ritual as Siri, Shortcuts and widgets see it.
struct RitualEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Ritual")
    static let defaultQuery = RitualQuery()

    let id: String
    let title: String
    let symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: symbol))
    }

    init(id: String, title: String, symbol: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
    }

    init(_ routine: Routine) {
        id = routine.entityID
        title = routine.title
        symbol = routine.symbol
    }
}

struct RitualQuery: EntityQuery {
    func entities(for identifiers: [RitualEntity.ID]) async throws -> [RitualEntity] {
        await MainActor.run {
            RitualStore.all(in: SovaStore.workContext()).filter { identifiers.contains($0.entityID) }.map { RitualEntity($0) }
        }
    }

    func suggestedEntities() async throws -> [RitualEntity] {
        await MainActor.run {
            RitualStore.all(in: SovaStore.workContext()).filter { $0.isScheduled(on: .now) }.map { RitualEntity($0) }
        }
    }
}

extension Routine {
    /// Stable across launches (the creation time in milliseconds).
    var entityID: String { "ritual-\(Int(createdAt.timeIntervalSinceReferenceDate * 1000))" }
}

@MainActor
enum RitualStore {
    static var context: ModelContext { SovaStore.shared.mainContext }

    // Overloads rather than default arguments: a default argument is
    // evaluated outside the main actor, so it can't read `context`.
    static func all() -> [Routine] { all(in: context) }

    static func all(in context: ModelContext) -> [Routine] {
        (try? context.fetch(FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.order)]))) ?? []
    }

    static func find(_ id: String) -> Routine? { find(id, in: context) }

    static func find(_ id: String, in context: ModelContext) -> Routine? {
        all(in: context).first { $0.entityID == id }
    }
}
