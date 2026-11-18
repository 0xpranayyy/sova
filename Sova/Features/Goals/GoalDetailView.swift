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
    @ScaledMetric(relativeTo: .largeTitle) private var percentSize: CGFloat = 88

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                hero
                if goal.steps.isEmpty { manualProgress }
                milestones
                tasks
                if !goal.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(String(localized: "Why it matters"))
                        Text(goal.notes)
                            .font(.allo(.body))
                            .foregroundStyle(Color.inkSecondary)
                            .surface(cornerRadius: 20, padding: 18)
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
        .sovaFeedback(.success, trigger: goal.progress >= 1)
    }

    private var hero: some View {
        let tone = StickerTone(goal.accent)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                MonoCaps(goal.deadlineText ?? String(localized: "No deadline"),
                         color: tone == .indigo ? tone.deep : tone.deep)
                Spacer()
                Image(systemName: goal.symbol).font(.system(size: 22, weight: .semibold))
            }
            Text(goal.title)
                .font(.hero(34, weight: .heavy))
                .tracking(-1.2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(Int((goal.progress * 100).rounded()), format: .number)
                    .font(.hero(percentSize, weight: .heavy))
                    .tracking(-4)
                    .contentTransition(.numericText(value: goal.progress))
                Text("%").font(.hero(36, weight: .heavy)).opacity(0.5)
            }
            .padding(.top, 6)
            StepBar(progress: goal.progress, steps: goal.sortedMilestones.map(\.isDone), color: tone.deep, height: 16)
                .padding(.top, 10)
        }
        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
        .block(tone, cornerRadius: 32, padding: 22)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var manualProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Progress"))
            VStack(alignment: .leading, spacing: 10) {
                Slider(value: $goal.manualProgress, in: 0...1, step: 0.01) {
                    Text("Progress")
                }
                .tint(SovaTheme.current.accent.color)
                Text("No steps yet. Set progress here, or add steps below.")
                    .font(.allo(.footnote))
                    .foregroundStyle(Color.inkSecondary)
            }
            .surface(cornerRadius: 22, padding: 18)
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Steps"),
                         trailing: goal.steps.isEmpty ? nil : "\(goal.completedMilestones) of \(goal.steps.count)")
            VStack(spacing: 0) {
                ForEach(goal.sortedMilestones) { milestone in
                    HStack(spacing: 4) {
                        CheckButton(isOn: milestone.isDone, color: StickerTone(goal.accent).deep, round: true,
                                    checkColor: StickerTone(goal.accent).fill, label: milestone.title) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { milestone.isDone.toggle() }
                        }
                        Text(milestone.title)
                            .foregroundStyle(milestone.isDone ? Color.inkTertiary : Color.ink)
                        Spacer()
                    }
                    .padding(.leading, 8)
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                goal.milestones?.removeAll { $0 == milestone }
                                context.delete(milestone)
                            }
                        }
                    }
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 52)
                }

                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.allo(.body, .medium))
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
            let linked = goal.linkedTasks.sorted { a, b in
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
        let next = (goal.steps.map(\.order).max() ?? -1) + 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            goal.addStep(Milestone(title: title, order: next))
        }
        newMilestone = ""
        addFieldFocused = true
    }
}
