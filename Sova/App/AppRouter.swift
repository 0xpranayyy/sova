import SwiftUI
import Observation

enum AppTab: Hashable {
    case today, goals, routines, insights
    /// The separated "+" button in the tab bar. Selecting it opens the
    /// right creator for the tab you were on, then snaps back.
    case create
}

/// Which sheet is presented. Lives at the root so any screen, and the
/// bottom accessory, can open one.
enum EditorSheet: Identifiable {
    case quickTask
    case newTask(Goal?)
    case newGoal
    case newRoutine
    case task(TaskItem)
    case goal(Goal)
    case routine(Routine)

    var id: String {
        switch self {
        case .quickTask: "quick-task"
        case .newTask(let goal): "new-task-" + (goal.map { String(ObjectIdentifier($0).hashValue) } ?? "none")
        case .newGoal: "new-goal"
        case .newRoutine: "new-routine"
        case .task(let t): "task-\(ObjectIdentifier(t).hashValue)"
        case .goal(let g): "goal-\(ObjectIdentifier(g).hashValue)"
        case .routine(let r): "routine-\(ObjectIdentifier(r).hashValue)"
        }
    }
}

/// A short message with an optional Undo, shown in the bottom accessory.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let undo: (() -> Void)?

    init(message: String, undo: (() -> Void)? = nil) {
        self.message = message
        self.undo = undo
    }

    static func == (a: Toast, b: Toast) -> Bool { a.id == b.id }
}

@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .today
    var sheet: EditorSheet?
    private(set) var toast: Toast?

    func createAction(from tab: AppTab) -> EditorSheet {
        switch tab {
        case .goals: .newGoal
        case .routines: .newRoutine
        default: .quickTask
        }
    }

    var primaryCreateAction: EditorSheet {
        switch tab {
        case .goals: .newGoal
        case .routines: .newRoutine
        default: .quickTask
        }
    }

    var primaryCreateTitle: String {
        switch tab {
        case .goals: String(localized: "New Goal")
        case .routines: String(localized: "New Routine")
        default: String(localized: "New Task")
        }
    }

    func show(_ toast: Toast) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { self.toast = toast }
        let id = toast.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if self.toast?.id == id { self.dismissToast() }
        }
    }

    func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { toast = nil }
    }
}
