import Foundation
import SwiftData

/// The one SwiftData store, kept in the App Group so the app, its widgets and
/// Siri all see the same tasks. Syncs with iCloud for Sova Plus members who
/// turn sync on.
enum SovaStore {
    static let schema = Schema([TaskItem.self, Goal.self, Milestone.self, Routine.self])

    /// True inside the widget extension, which reads the store but never
    /// runs iCloud mirroring itself.
    static let isExtension = Bundle.main.bundlePath.hasSuffix(".appex")

    /// One container per process, shared by the app, Siri and widgets.
    static let shared: ModelContainer = makeContainer(allowSync: !isExtension)

    /// The context to read and write with right now. In the app, the main
    /// context the screens use. In the widget extension, which lives on while
    /// the app changes the store, a fresh one each time, so it never shows
    /// stale objects.
    @MainActor
    static func workContext() -> ModelContext {
        isExtension ? ModelContext(shared) : shared.mainContext
    }

    /// Where the store lives: the shared App Group if it's available,
    /// otherwise the app's own Application Support folder.
    static var storeURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SovaSettings.appGroup)?
            .appending(path: "Library/Application Support", directoryHint: .isDirectory)
            ?? URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appending(path: "Sova.store")
    }

    /// - Parameter allowSync: false for extensions, which never run CloudKit mirroring.
    static func makeContainer(allowSync: Bool = true) -> ModelContainer {
        if allowSync { SovaSettings.moveSettingsToAppGroup() }
        migrateLegacyStoreIfNeeded()
        let sync = allowSync && SovaSettings.isPlus && SovaSettings.iCloudSyncOn
        let attempts: [ModelConfiguration] = [
            ModelConfiguration(schema: schema, url: storeURL,
                               cloudKitDatabase: sync ? .private(SovaSettings.cloudContainer) : .none),
            ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none),
        ]
        for config in attempts {
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                return container
            }
        }
        // Last resort: the default on-device store.
        return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)])
    }

    /// Before the App Group existed, the store was SwiftData's `default.store`
    /// in Application Support. Copy it over once so nothing is lost.
    private static func migrateLegacyStoreIfNeeded() {
        let fm = FileManager.default
        let target = storeURL
        guard !fm.fileExists(atPath: target.path(percentEncoded: false)) else { return }
        let legacy = URL.applicationSupportDirectory.appending(path: "default.store")
        guard fm.fileExists(atPath: legacy.path(percentEncoded: false)), legacy != target else { return }
        for suffix in ["", "-shm", "-wal"] {
            let from = URL(filePath: legacy.path(percentEncoded: false) + suffix)
            let to = URL(filePath: target.path(percentEncoded: false) + suffix)
            if fm.fileExists(atPath: from.path(percentEncoded: false)) { try? fm.copyItem(at: from, to: to) }
        }
    }
}
