import SwiftUI
import SwiftData

@main
struct SovaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container = SovaStore.shared
    @State private var store = PlusStore()

    init() {
        Allo.register()
        Allo.applyToUIKit()
        SovaTips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
        .modelContainer(container)
        // iPad with a keyboard: hold ⌘ to see these.
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") { QuickActions.run(LaunchAction.quickTask.rawValue) }
                    .keyboardShortcut("n")
                Button("New Ritual") { QuickActions.run(LaunchAction.newRitual.rawValue) }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandMenu("Go") {
                Button("Today") { QuickActions.run(LaunchAction.today.rawValue) }
                    .keyboardShortcut("1")
                Button("Tasks") { QuickActions.run(LaunchAction.tasks.rawValue) }
                    .keyboardShortcut("2")
            }
        }
    }
}
