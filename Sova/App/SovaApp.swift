import SwiftUI
import SwiftData

@main
struct SovaApp: App {
    private let container = SovaStore.makeContainer()

    init() {
        Allo.register()
        Allo.applyToUIKit()
        SovaTips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
