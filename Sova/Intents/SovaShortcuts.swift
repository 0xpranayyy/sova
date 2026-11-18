import AppIntents

/// Opens Sova on Today.
struct OpenTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Show My Day"
    static let description = IntentDescription("Opens Sova on today's plan.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult { .result() }
}

/// Phrases that work with Siri and show up in Spotlight and Shortcuts
/// without any setup.
struct SovaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddTaskIntent(),
                    phrases: ["Add a task in \(.applicationName)",
                              "Add to \(.applicationName)",
                              "New \(.applicationName) task"],
                    shortTitle: "Add Task",
                    systemImageName: "plus.circle.fill")
        AppShortcut(intent: ToggleRitualIntent(),
                    phrases: ["Tick off a ritual in \(.applicationName)",
                              "Complete \(\.$ritual) in \(.applicationName)",
                              "I did \(\.$ritual) in \(.applicationName)"],
                    shortTitle: "Tick Ritual",
                    systemImageName: "checkmark.circle.fill")
        AppShortcut(intent: OpenTodayIntent(),
                    phrases: ["Show my day in \(.applicationName)",
                              "What's on today in \(.applicationName)"],
                    shortTitle: "My Day",
                    systemImageName: "sun.max.fill")
    }
}
