import SwiftUI
import SwiftData

struct TaskRow: View {
    let task: TaskItem
    var showGoal = true
    var onOpen: () -> Void

    @Environment(\.modelContext) private var context
    @State private var completions = 0

    var body: some View {
        HStack(spacing: 14) {
            CheckButton(isOn: task.isDone, accent: task.accent) {
                withAnimation(.snappy) { task.toggle() }
                if task.isDone { completions += 1 }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(task.isDone, color: .secondary)
                    .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                    .lineLimit(2)

                if hasMeta {
                    HStack(spacing: 6) {
                        if let due = task.dueDate {
                            MetaChip(
                                text: due.relativeDayText(includingTime: task.hasTime),
                                symbol: task.hasTime ? "clock" : "calendar",
                                tint: task.isOverdue ? Accent.rose.color : .secondary
                            )
                        }
                        if showGoal, let goal = task.goal {
                            MetaChip(text: "\(goal.emoji) \(goal.title)", tint: goal.accent.color)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            if task.priority != .low && !task.isDone {
                Image(systemName: "flag.fill")
                    .font(.footnote)
                    .foregroundStyle(task.priority.color)
                    .accessibilityLabel("\(Text(task.priority.label)) priority")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .card(tint: task.accent.color, cornerRadius: 22, padding: 0)
        .contentShape(.rect(cornerRadius: 22))
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
        .sensoryFeedback(.success, trigger: completions)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(task.isDone ? .isSelected : [])
        .accessibilityAction(named: task.isDone ? "Mark as not done" : "Mark as done") {
            withAnimation(.snappy) { task.toggle() }
        }
    }

    private var hasMeta: Bool { task.dueDate != nil || (showGoal && task.goal != nil) }
}

/// A Liquid Glass checkbox: a real control, so it gets interactive glass.
struct CheckButton: View {
    var isOn: Bool
    var accent: Accent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.heavy))
                .foregroundStyle(.white)
                .opacity(isOn ? 1 : 0)
                .scaleEffect(isOn ? 1 : 0.4)
                .frame(width: 30, height: 30)
                .background {
                    Circle()
                        .fill(accent.gradient)
                        .opacity(isOn ? 1 : 0)
                }
                .glassEffect(.control(tint: isOn ? accent.color.opacity(0.4) : nil), in: .circle)
                .overlay {
                    Circle()
                        .strokeBorder(accent.color.opacity(isOn ? 0 : 0.7), lineWidth: 1.5)
                }
                .frame(width: 44, height: 44) // HIG minimum hit target
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .animation(.bouncy(duration: 0.35), value: isOn)
        .accessibilityLabel(isOn ? "Completed" : "Not completed")
    }
}
