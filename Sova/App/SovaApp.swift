import SwiftUI
import SwiftData

@main
struct SovaApp: App {
    private let container = SovaStore.makeContainer()
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
    }
}
