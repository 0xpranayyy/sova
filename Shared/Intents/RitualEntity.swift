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

    init(_ routine: Routine) {
        id = routine.entityID
        title = routine.title
        symbol = routine.symbol
    }
}

struct RitualQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [RitualEntity.ID]) async throws -> [RitualEntity] {
        RitualStore.all().filter { identifiers.contains($0.entityID) }.map(RitualEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [RitualEntity] {
        RitualStore.all().filter { $0.isScheduled(on: .now) }.map(RitualEntity.init)
    }
}

extension Routine {
    /// Stable across launches (the creation time in milliseconds).
    var entityID: String { "ritual-\(Int(createdAt.timeIntervalSinceReferenceDate * 1000))" }
}

@MainActor
enum RitualStore {
    static var context: ModelContext { SovaStore.shared.mainContext }

    static func all() -> [Routine] {
        (try? context.fetch(FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.order)]))) ?? []
    }

    static func find(_ id: String) -> Routine? {
        all().first { $0.entityID == id }
    }
}
