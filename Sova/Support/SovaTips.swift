import SwiftUI
import TipKit

// Onboarding continues inside the app with a few well-timed TipKit tips,
// one at a time.

struct QuickCaptureTip: Tip {
    var title: Text { Text("Just type it") }
    var message: Text? {
        Text("Tap New Task below and write naturally: “Call Mom tomorrow 6pm !!” sets the date, time and priority for you.")
    }
    var image: Image? { Image(systemName: "text.cursor") }
}

struct SwipeTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text { Text("Swipe to move fast") }
    var message: Text? {
        Text("Swipe right to finish a task. Swipe left to push it to tomorrow or delete it.")
    }
    var image: Image? { Image(systemName: "hand.draw") }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}

struct TasksTabTip: Tip {
    var title: Text { Text("Every task lives here") }
    var message: Text? {
        Text("Tomorrow, next week or someday. Tap a day up top to see just that day, and pull down for an owl fact.")
    }
    var image: Image? { Image(systemName: "checklist") }
}

struct RitualCountTip: Tip {
    var title: Text { Text("Count it up") }
    var message: Text? {
        Text("Rituals can have a daily goal, like 8 glasses of water. Open a ritual and choose how many times.")
    }
    var image: Image? { Image(systemName: "drop.fill") }
}

enum SovaTips {
    static func configure() {
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}
