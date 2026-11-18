import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newMilestone = ""
    @State private var confirmDelete = false
    @FocusState private var addFieldFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var percentSize: CGFloat = 64

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                hero
                if goal.milestones.isEmpty { manualProgress }
                milestones
                tasks
                if !goal.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Why it matters"))
                        Text(goal.notes)
                            .font(.display(.body))
                            .foregroundStyle(Color.ink)
                            .surface(cornerRadius: 22, padding: 18)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { CanvasBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Goal", systemImage: "pencil") { router.sheet = .goal(goal) }
                    Button(goal.isArchived ? "Unarchive" : "Archive",
                           systemImage: goal.isArchived ? "tray.and.arrow.up" : "archivebox") {
                        goal.isArchived.toggle()
                    }
                    Divider()
                    Button("Delete Goal", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
        .confirmationDialog("Delete “\(goal.title)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Goal", role: .destructive) {
                dismiss()
                context.delete(goal)
            }
        } message: {
            Text("Its steps are deleted too. Linked tasks are kept.")
        }
        .sensoryFeedback(.success, trigger: goal.progress >= 1)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            IconTile(symbol: goal.symbol, accent: goal.accent, size: 52, filled: true)
            Text(goal.title)
                .font(.display(.largeTitle))
                .tracking(-0.5)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(Int((goal.progress * 100).rounded()), format: .number)
                    .font(.system(size: percentSize, weight: .light, design: .serif))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: goal.progress))
                Text("%")
                    .font(.display(.title2))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                if let text = goal.deadlineText {
                    Text(text)
                        .font(.footnote)
                        .foregroundStyle((goal.daysLeft ?? 1) < 0 ? Accent.ember.color : Color.inkSecondary)
                }
            }
            .foregroundStyle(Color.ink)

            ProgressLine(progress: goal.progress, color: goal.accent.color, height: 6)
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var manualProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Progress"))
            VStack(alignment: .leading, spacing: 10) {
                Slider(value: $goal.manualProgress, in: 0...1, step: 0.01) {
                    Text("Progress")
                }
                .tint(goal.accent.color)
                Text("No steps yet. Slide to track it by feel, or break it down below.")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
            }
            .surface(cornerRadius: 22, padding: 18)
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Steps"),
                         trailing: goal.milestones.isEmpty ? nil : "\(goal.completedMilestones) of \(goal.milestones.count)")
            VStack(spacing: 0) {
                ForEach(goal.sortedMilestones) { milestone in
                    HStack(spacing: 4) {
                        CheckButton(isOn: milestone.isDone, color: goal.accent.color, round: true, label: milestone.title) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { milestone.isDone.toggle() }
                        }
                        Text(milestone.title)
                            .foregroundStyle(milestone.isDone ? Color.inkSecondary : Color.ink)
                            .strikethrough(milestone.isDone, color: Color.inkTertiary)
                        Spacer()
                    }
                    .padding(.leading, 8)
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                goal.milestones.removeAll { $0 == milestone }
                                context.delete(milestone)
                            }
                        }
                    }
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 52)
                }

                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.inkTertiary)
                        .frame(width: 44, height: 44)
                    TextField("Add a step", text: $newMilestone)
                        .focused($addFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(addMilestone)
                }
                .padding(.leading, 8)
                .padding(.vertical, 2)
            }
            .surface(cornerRadius: 22, padding: 0)
        }
    }

    private var tasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Tasks"))
            let linked = goal.tasks.sorted { a, b in
                a.isDone != b.isDone ? !a.isDone : TaskItem.ordering(a, b)
            }
            if !linked.isEmpty {
                GroupedList(items: linked, inset: 52) { task in
                    TaskRow(task: task, showGoal: false) { router.sheet = .task(task) }
                }
            }
            Button {
                router.sheet = .newTask(goal)
            } label: {
                Label("Add a task", systemImage: "plus")
            }
            .buttonStyle(.quiet)
        }
    }

    private func addMilestone() {
        let title = newMilestone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let next = (goal.milestones.map(\.order).max() ?? -1) + 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            goal.milestones.append(Milestone(title: title, order: next))
        }
        newMilestone = ""
        addFieldFocused = true
    }
}
