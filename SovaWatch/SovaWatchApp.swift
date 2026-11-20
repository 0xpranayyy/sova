import SwiftUI

@main
struct SovaWatchApp: App {
    @State private var store = WatchStore.shared

    init() {
        WatchAllo.register()
        WatchStore.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            TodayScreen()
                .environment(store)
        }
    }
}
