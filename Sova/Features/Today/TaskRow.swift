import SwiftUI
import SwiftData

/// A task as a row in a grouped list, Things-style: a checkbox, the title,
/// and quiet metadata.
struct TaskRow: View {
    let task: TaskItem
    var showGoal = true
    var onOpen: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            CheckButton(isOn: task.isDone, color: task.accent.color, label: task.title) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { task.toggle() }
            }
            .padding(.top, -2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if !task.priority.marks.isEmpty && !task.isDone {
                        Text(task.priority.marks)
                            .font(.body.weight(.bold))
                            .foregroundStyle(task.priority.color)
                    }
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(task.isDone ? Color.inkSecondary : Color.ink)
                        .strikethrough(task.isDone, color: Color.inkTertiary)
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
                withAnimation(.snappy) { task.toggle() }
            }
            Button("Edit", systemImage: "pencil", action: onOpen)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                withAnimation { context.delete(task) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: task.isDone ? "Mark as not done" : "Mark as done") {
            withAnimation(.snappy) { task.toggle() }
        }
    }

    private var meta: [MetaLine.Part] {
        var parts: [MetaLine.Part] = []
        if let due = task.dueDate, !(Calendar.current.isDateInToday(due) && !task.hasTime) {
            parts.append(.init(text: due.relativeDayText(includingTime: task.hasTime),
                               color: task.isOverdue ? Accent.ember.color : .inkSecondary))
        }
        if showGoal, let goal = task.goal {
            parts.append(.init(text: goal.title, color: goal.accent.color))
        }
        if !task.notes.isEmpty && parts.isEmpty {
            parts.append(.init(text: task.notes))
        }
        return parts
    }
}
