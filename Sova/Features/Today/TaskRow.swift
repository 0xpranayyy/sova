import SwiftUI
import SwiftData

/// A task row, Things-style: a checkbox that draws itself, the title, and
/// quiet metadata.
struct TaskRow: View {
    let task: TaskItem
    var showGoal = true
    var onOpen: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            CheckButton(isOn: task.isDone, label: task.title) {
                TaskActions.toggle(task, router: router)
            }
            .padding(.top, -2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if !task.priority.marks.isEmpty && !task.isDone {
                        Text(task.priority.marks)
                            .font(.allo(.body, .bold))
                            .foregroundStyle(Color.danger)
                    }
                    Text(task.title)
                        .font(.allo(.body))
                        .foregroundStyle(task.isDone ? Color.inkTertiary : Color.ink)
                        .lineLimit(2)
                }
                if !meta.isEmpty {
                    MetaLine(parts: meta)
                }
            }
            .padding(.vertical, 11)

            Spacer(minLength: 8)
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .contextMenu {
            Button(task.isDone ? "Mark as Not Done" : "Mark as Done",
                   systemImage: task.isDone ? "circle" : "checkmark.circle") {
                TaskActions.toggle(task, router: router)
            }
            if !task.isDone {
                Button("Move to Tomorrow", systemImage: "arrow.turn.up.right") {
                    TaskActions.moveToTomorrow(task, router: router)
                }
            }
            Button("Edit", systemImage: "pencil", action: onOpen)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                TaskActions.delete(task, context: context, router: router)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: task.isDone ? "Mark as not done" : "Mark as done") {
            TaskActions.toggle(task, router: router)
        }
        .accessibilityAction(named: "Delete") {
            TaskActions.delete(task, context: context, router: router)
        }
    }

    private var meta: [MetaLine.Part] {
        var parts: [MetaLine.Part] = []
        if let due = task.dueDate, !(Calendar.current.isDateInToday(due) && !task.hasTime) {
            parts.append(.init(text: due.relativeDayText(includingTime: task.hasTime),
                               color: task.isOverdue ? Color.danger : .inkTertiary))
        }
        if showGoal, let goal = task.goal {
            parts.append(.init(text: goal.title))
        }
        if !task.notes.isEmpty && parts.isEmpty {
            parts.append(.init(text: task.notes))
        }
        return parts
    }
}

/// Native swipe actions for a task in a List.
struct TaskSwipeActions: ViewModifier {
    let task: TaskItem
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    TaskActions.toggle(task, router: router)
                } label: {
                    Label(task.isDone ? "Not Done" : "Done", systemImage: task.isDone ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(SovaTheme.current.accent.color)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    TaskActions.delete(task, context: context, router: router)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                if !task.isDone {
                    Button {
                        TaskActions.moveToTomorrow(task, router: router)
                    } label: {
                        Label("Tomorrow", systemImage: "arrow.turn.up.right")
                    }
                    .tint(Color(hex: 0x3A3A40))
                }
            }
    }
}

extension View {
    func taskSwipeActions(_ task: TaskItem) -> some View { modifier(TaskSwipeActions(task: task)) }

    /// A row with no chrome, for timeline rows, headings and cards in a List.
    func bareListRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
