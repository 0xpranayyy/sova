import SwiftUI
import SwiftData

@main
struct SovaApp: App {
    init() {
        Allo.register()
        Allo.applyToUIKit()
        SovaTips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self])
    }
}
