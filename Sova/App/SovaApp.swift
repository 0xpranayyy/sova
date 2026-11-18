import SwiftUI
import SwiftData

@main
struct SovaApp: App {
    init() {
        NavigationBarStyle.apply()
        SovaTips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self])
    }
}
