import SwiftUI
import Observation

enum AppTab: Hashable {
    case today, goals, routines, insights
}

/// Which editor sheet is presented. Lives at the root so any screen
/// (and the bottom accessory) can open an editor.
enum EditorSheet: Identifiable {
    case newTask(Goal?)
    case newGoal
    case newRoutine
    case task(TaskItem)
    case goal(Goal)
    case routine(Routine)

    var id: String {
        switch self {
        case .newTask(let goal): "new-task-" + (goal.map { String(ObjectIdentifier($0).hashValue) } ?? "none")
        case .newGoal: "new-goal"
        case .newRoutine: "new-routine"
        case .task(let t): "task-\(ObjectIdentifier(t).hashValue)"
        case .goal(let g): "goal-\(ObjectIdentifier(g).hashValue)"
        case .routine(let r): "routine-\(ObjectIdentifier(r).hashValue)"
        }
    }
}

@Observable
final class AppRouter {
    var tab: AppTab = .today
    var sheet: EditorSheet?

    /// The "create" action that makes sense for the current tab.
    var primaryCreateAction: EditorSheet {
        switch tab {
        case .goals: .newGoal
        case .routines: .newRoutine
        default: .newTask(nil)
        }
    }

    var primaryCreateTitle: String {
        switch tab {
        case .goals: "New Goal"
        case .routines: "New Routine"
        default: "New Task"
        }
    }
}
