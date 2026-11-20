import Foundation
import SwiftData
import WatchConnectivity

/// The iPhone's side of the Apple Watch app. It sends the Watch a picture of
/// today after every change, and does what the Watch asks: tick a task, tap
/// a ritual, add a task. The iPhone stays the one source of truth.
@MainActor
final class WatchLink: NSObject {
    static let shared = WatchLink()

    private var pendingPush: Task<Void, Never>?
    private var saveObserver: NSObjectProtocol?

    /// Call once at launch.
    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        // Any save, from any screen, Siri or a notification button: tell the
        // Watch a moment later (several quick saves become one update).
        saveObserver = NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil,
                                                              queue: .main) { _ in
            Task { @MainActor in WatchLink.shared.schedulePush() }
        }
    }

    /// Sends today soon, folding bursts of changes into one update.
    func schedulePush() {
        pendingPush?.cancel()
        pendingPush = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            push()
        }
    }

    /// Sends today now, if there's a Watch with Sova on it.
    func push() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled,
              let data = Self.makeDay().encoded() else { return }
        // The latest context always replaces the last one, and reaches the
        // Watch even if its app isn't open.
        try? session.updateApplicationContext([WatchKeys.day: data])
    }

    // MARK: Actions from the Watch

    func handle(_ action: WatchAction) async {
        let context = SovaStore.workContext()
        switch action {
        case .toggleTask(let id):
            _ = try? await ToggleTaskIntent(taskID: id).perform()
        case .tapRitual(let id):
            if let routine = RitualStore.find(id, in: context) {
                routine.advance(on: .now)
                SovaRefresh.changed(context)
            }
        case .addTask(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            _ = try? await AddTaskIntent(text: trimmed).perform()
        }
    }

    // MARK: Today, for the Watch

    /// The same picture of today as the widgets (`DaySnapshot` in the widget
    /// extension): today's and overdue tasks, today's rituals, Up Next.
    static func makeDay() -> WatchDay {
        let now = Date.now
        let context = SovaStore.workContext()
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let relevant = tasks.filter { task in
            task.isDone ? (task.completedAt?.isSameDay(as: now) ?? false) : task.isDueTodayOrEarlier
        }
        let routines = RitualStore.all(in: context)
        let todays = routines.filter { $0.isScheduled(on: now) }

        let open = relevant.filter { !$0.isDone }.sorted(by: TaskItem.ordering)
        let upcoming = open.filter { $0.hasTime && ($0.dueDate ?? .distantPast) >= now }
            .min { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        var next: WatchNext?
        if let task = upcoming ?? open.first {
            next = WatchNext(title: task.title, time: task.hasTime ? task.dueDate : nil)
        } else if let ritual = todays.first(where: { !$0.isDone(on: now) }) {
            next = WatchNext(title: ritual.title, time: nil)
        }

        // The next timed task leads, then the rest by urgency, then today's done.
        var ordered = open
        if let upcoming, let index = ordered.firstIndex(where: { $0 === upcoming }) {
            ordered.insert(ordered.remove(at: index), at: 0)
        }
        let finished = relevant.filter(\.isDone)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        let rows = (ordered + finished).prefix(20).map { task in
            WatchTask(id: task.alertID, title: task.title, time: task.hasTime ? task.dueDate : nil,
                      marks: task.priority.marks, tone: StickerTone(task.accent).rawValue,
                      done: task.isDone, overdue: task.isOverdue)
        }
        let rituals = todays.map { routine in
            WatchRitual(id: routine.entityID, title: routine.title, symbol: routine.symbol,
                        tone: StickerTone(routine.accent).rawValue, tally: routine.tally(on: now),
                        target: routine.target, done: routine.isDone(on: now))
        }

        var day = WatchDay(date: now,
                           name: SovaSettings.shared.string(forKey: SovaSettings.Key.userName) ?? "",
                           done: 0, total: 0, streak: routines.map(\.streak).max() ?? 0,
                           next: next, rituals: rituals, tasks: Array(rows))
        // Done and total count everything today, even past the 20 rows sent.
        day.done = relevant.filter(\.isDone).count + todays.filter { $0.isDone(on: now) }.count
        day.total = relevant.count + todays.count
        return day
    }
}

// MARK: - WCSessionDelegate (called on a background queue)

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        guard activationState == .activated else { return }
        Task { @MainActor in WatchLink.shared.push() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Switching to another Watch: start again with the new one.
        WCSession.default.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in WatchLink.shared.push() }
    }

    /// A tap on the Watch while the iPhone is reachable: do it, then answer
    /// with the new day so the Watch updates at once.
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        let action = WatchAction.decode(message[WatchKeys.action] as? Data)
        Task { @MainActor in
            if let action { await WatchLink.shared.handle(action) }
            let reply = WatchLink.makeDay().encoded().map { [WatchKeys.day: $0] } ?? [:]
            replyHandler(reply)
            WatchLink.shared.push()
        }
    }

    /// A tap the Watch queued while the iPhone was away.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        let action = WatchAction.decode(userInfo[WatchKeys.action] as? Data)
        Task { @MainActor in
            if let action { await WatchLink.shared.handle(action) }
            WatchLink.shared.push()
        }
    }
}
