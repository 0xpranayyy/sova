import Foundation

/// Keys and defaults for every preference, shared by the app, its widgets
/// and its intents.
enum SovaSettings {
    static let appGroup = "group.app.sova.Sova"
    static let cloudContainer = "iCloud.app.sova.Sova"

    enum Key {
        static let weekStart = "weekStart"              // 0 system, 1 Sunday, 2 Monday
        static let alertOffset = "alertOffsetMinutes"   // minutes before a timed task
        static let badgeOverdue = "badgeOverdue"
        static let haptics = "hapticsOn"
        static let sounds = "soundsOn"
        static let iCloudSync = "iCloudSync"
        static let isPlus = "isPlusCached"
        static let lastReviewPrompt = "lastReviewPrompt"
        static let activeDays = "activeDays"
        static let dayCompleteShown = "dayCompleteShown"
        static let pendingAction = "pendingAction"     // a LaunchAction to run on open
        static let pendingTask = "pendingTask"         // a task's alertID to open
        static let userName = "userName"           // mirrored to the App Group for widgets
    }

    /// Defaults the widget and intents can read too.
    static let shared: UserDefaults = UserDefaults(suiteName: appGroup) ?? .standard

    static func bool(_ key: String, default value: Bool, in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: key) as? Bool ?? value
    }

    /// Settings the widgets and intents act on, kept in the App Group.
    static let sharedKeys = [Key.alertOffset, Key.badgeOverdue, Key.iCloudSync]

    /// Earlier versions kept these in the app's own defaults, where the widget
    /// can't see them. Copy them over once.
    static func moveSettingsToAppGroup() {
        for key in sharedKeys where shared.object(forKey: key) == nil {
            if let value = UserDefaults.standard.object(forKey: key) { shared.set(value, forKey: key) }
        }
    }

    static var hapticsOn: Bool { bool(Key.haptics, default: true) }
    static var badgeOverdue: Bool { bool(Key.badgeOverdue, default: true, in: shared) }
    static var alertOffset: Int { shared.integer(forKey: Key.alertOffset) }
    static var weekStart: Int { shared.integer(forKey: Key.weekStart) }

    /// Plus status, cached so launch and the widget know it before StoreKit answers.
    static var isPlus: Bool {
        get { shared.bool(forKey: Key.isPlus) }
        set { shared.set(newValue, forKey: Key.isPlus) }
    }

    static var iCloudSyncOn: Bool { bool(Key.iCloudSync, default: false, in: shared) }
}
