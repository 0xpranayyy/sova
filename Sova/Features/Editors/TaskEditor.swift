import SwiftUI
import SwiftData

struct TaskEditor: View {
    let task: TaskItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt) private var goals: [Goal]

    @State private var title: String
    @State private var notes: String
    @State private var hasDue: Bool
    @State private var hasTime: Bool
    @State private var due: Date
    @State private var priority: Priority
    @State private var accent: Accent
    @State private var goal: Goal?
    @State private var confirmDelete = false
    @FocusState private var titleFocused: Bool

    init(task: TaskItem?, defaultGoal: Goal? = nil) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _hasDue = State(initialValue: task == nil ? true : task?.dueDate != nil)
        _hasTime = State(initialValue: task?.hasTime ?? false)
        _due = State(initialValue: task?.dueDate ?? .now)
        _priority = State(initialValue: task?.priority ?? .low)
        _accent = State(initialValue: task?.accent ?? defaultGoal?.accent ?? SovaTheme.current.accent)
        _goal = State(initialValue: task?.goal ?? defaultGoal)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs doing?", text: $title, axis: .vertical)
                        .font(.display(.title3))
                        .focused($titleFocused)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("When") {
                    Toggle(isOn: $hasDue.animation(.snappy)) {
                        Label("Due Date", systemImage: "calendar")
                    }
                    if hasDue {
                        DatePicker("Date", selection: $due,
                                   displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date])
                        Toggle(isOn: $hasTime.animation(.snappy)) {
                            Label("Time", systemImage: "clock")
                        }
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if !goals.isEmpty {
                    Section("Goal") {
                        Picker(selection: $goal) {
                            Text("None").tag(Goal?.none)
                            ForEach(goals) { goal in
                                Label(goal.title, systemImage: goal.symbol).tag(Optional(goal))
                            }
                        } label: {
                            Label("Linked Goal", systemImage: "target")
                        }
                    }
                }

                if task != nil {
                    Section {
                        Button("Delete Task", systemImage: "trash", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { CanvasBackground() }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { save() }
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog("Delete this task?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete Task", role: .destructive) {
                    if let task { context.delete(task) }
                    dismiss()
                }
            }
            .onAppear { if task == nil { titleFocused = true } }
        }
        .tint(SovaTheme.current.accent.color)
    }

    private func save() {
        let target = task ?? {
            let new = TaskItem(title: trimmedTitle)
            context.insert(new)
            return new
        }()
        target.title = trimmedTitle
        target.notes = notes
        target.hasTime = hasDue && hasTime
        target.dueDate = hasDue ? (hasTime ? due : due.startOfDay) : nil
        target.priority = priority
        target.accent = accent
        target.goal = goal
        dismiss()
    }
}
