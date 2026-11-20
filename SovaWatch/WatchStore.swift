import SwiftUI
import Observation
import WatchConnectivity
import WatchKit
import WidgetKit

/// The Watch's side of Sova. It shows the last day the iPhone sent, ticks
/// things right away on the wrist, and asks the iPhone to do the real work.
/// Whatever the iPhone sends back always wins.
@MainActor
@Observable
final class WatchStore: NSObject {
    static let shared = WatchStore()

    private(set) var day: WatchDay
    /// False until the iPhone has sent anything at all.
    private(set) var hasData: Bool
    /// Shows the "Day done!" owl. Set when this Watch finishes the day.
    var celebrating = false

    override init() {
        let stored = WatchDayStore.load()
        day = stored ?? .empty
        hasData = stored != nil
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// A new day from the iPhone.
    func apply(_ newDay: WatchDay) {
        hasData = true
        guard newDay != day else { return }
        day = newDay
        WatchDayStore.save(newDay)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Taps

    func toggleTask(_ id: String) {
        guard let index = day.tasks.firstIndex(where: { $0.id == id }) else { return }
        day.tasks[index].done.toggle()
        WKInterfaceDevice.current().play(day.tasks[index].done ? .success : .click)
        changedLocally()
        send(.toggleTask(id: id))
    }

    func tapRitual(_ id: String) {
        guard let index = day.rituals.firstIndex(where: { $0.id == id }) else { return }
        day.rituals[index].advance()
        WKInterfaceDevice.current().play(day.rituals[index].done ? .success : .click)
        changedLocally()
        send(.tapRitual(id: id))
    }

    func addTask(_ text: String) {
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        // Shows straight away; the iPhone's answer brings the real task,
        // with the date and time it read from the words.
        day.tasks.insert(WatchTask(id: "pending-\(UUID().uuidString)", title: title, time: nil, marks: "",
                                   tone: "yellow", done: false, overdue: false), at: 0)
        WKInterfaceDevice.current().play(.success)
        changedLocally()
        send(.addTask(text: title))
    }

    private func changedLocally() {
        let wasDone = day.allDone
        day.recount()
        if day.allDone && !wasDone { celebrating = true }
        WatchDayStore.save(day)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Straight to the iPhone if it's reachable; otherwise queued, and
    /// delivered as soon as it's back.
    private func send(_ action: WatchAction) {
        guard WCSession.isSupported(), let data = action.encoded() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let payload: [String: Any] = [WatchKeys.action: data]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: { reply in
                let fresh = WatchDay.decode(reply[WatchKeys.day] as? Data)
                Task { @MainActor in
                    if let fresh { WatchStore.shared.apply(fresh) }
                }
            }, errorHandler: { _ in
                WCSession.default.transferUserInfo(payload)
            })
        } else {
            session.transferUserInfo(payload)
        }
    }
}

// MARK: - WCSessionDelegate (called on a background queue)

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        let fresh = WatchDay.decode(session.receivedApplicationContext[WatchKeys.day] as? Data)
        Task { @MainActor in
            if let fresh { WatchStore.shared.apply(fresh) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let fresh = WatchDay.decode(applicationContext[WatchKeys.day] as? Data)
        Task { @MainActor in
            if let fresh { WatchStore.shared.apply(fresh) }
        }
    }
}
