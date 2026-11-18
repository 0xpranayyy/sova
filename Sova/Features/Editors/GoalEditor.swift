import SwiftUI
import SwiftData

struct GoalEditor: View {
    let goal: Goal?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var symbol: String
    @State private var notes: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var accent: Accent
    @State private var milestoneDraft = ""
    @State private var newMilestones: [String] = []

    init(goal: Goal?) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "")
        _symbol = State(initialValue: goal?.symbol ?? "flag.checkered")
        _notes = State(initialValue: goal?.notes ?? "")
        _hasDeadline = State(initialValue: goal?.deadline != nil)
        _deadline = State(initialValue: goal?.deadline ?? Date.now.adding(days: 30))
        _accent = State(initialValue: goal?.accent ?? SovaTheme.current.accent)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        IconTile(symbol: symbol, accent: accent, size: 56, filled: true)
                            .contentTransition(.symbolEffect(.replace))
                        TextField("What do you want to achieve?", text: $title, axis: .vertical)
                            .font(.display(.title3))
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    SymbolPicker(selection: $symbol, accent: accent, symbols: SymbolPicker.goalSymbols)
                }

                Section("Color") {
                    AccentPicker(selection: $accent)
                }

                Section("Deadline") {
                    Toggle(isOn: $hasDeadline.animation(.snappy)) {
                        Label("Target Date", systemImage: "flag.checkered")
                    }
                    if hasDeadline {
                        DatePicker("Date", selection: $deadline, in: Date.now.startOfDay..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }

                if goal == nil {
                    Section {
                        ForEach(newMilestones.indices, id: \.self) { index in
                            Label(newMilestones[index], systemImage: "circle")
                        }
                        .onDelete { newMilestones.remove(atOffsets: $0) }
                        TextField("Add a step", text: $milestoneDraft)
                            .submitLabel(.next)
                            .onSubmit {
                                let t = milestoneDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !t.isEmpty else { return }
                                withAnimation { newMilestones.append(t) }
                                milestoneDraft = ""
                            }
                    } header: {
                        Text("Steps")
                    } footer: {
                        Text("Optional. Progress follows the steps you finish.")
                    }
                }

                Section("Notes") {
                    TextField("Why does this matter?", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .scrollContentBackground(.hidden)
            .background { CanvasBackground() }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
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
        }
        .tint(accent.color)
    }

    private func save() {
        let target = goal ?? {
            let new = Goal(title: trimmedTitle)
            context.insert(new)
            return new
        }()
        target.title = trimmedTitle
        target.symbol = symbol
        target.notes = notes
        target.deadline = hasDeadline ? deadline.startOfDay : nil
        target.accent = accent

        var pending = newMilestones
        let draft = milestoneDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !draft.isEmpty { pending.append(draft) }
        let start = (target.milestones.map(\.order).max() ?? -1) + 1
        for (i, title) in pending.enumerated() {
            target.milestones.append(Milestone(title: title, order: start + i))
        }
        dismiss()
    }
}
