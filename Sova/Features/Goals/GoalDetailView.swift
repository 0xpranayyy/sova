import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newMilestone = ""
    @State private var confirmDelete = false
    @State private var celebrate = 0
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                if goal.milestones.isEmpty { manualProgressCard }
                milestonesSection
                tasksSection
                if !goal.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: String(localized: "Notes"), symbol: "note.text")
                        Text(goal.notes)
                            .font(.body)
                            .card(cornerRadius: 22)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background { AuroraBackground() }
        .navigationTitle(goal.title)
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
            Text("Its milestones will be deleted. Linked tasks are kept.")
        }
        .sensoryFeedback(.success, trigger: celebrate)
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: goal.progress, lineWidth: 14,
                             colors: [goal.accent.color, goal.accent.partner, goal.accent.color])
                Text(goal.emoji).font(.system(size: 56))
            }
            .frame(width: 170, height: 170)
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text(goal.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(goal.accent.gradient)
                    .contentTransition(.numericText(value: goal.progress))
                if let text = goal.deadlineText {
                    MetaChip(text: text, symbol: "hourglass", tint: goal.accent.color)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .card(tint: goal.accent.color, cornerRadius: 34, padding: 22)
        .accessibilityElement(children: .combine)
    }

    private var manualProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Progress"), symbol: "slider.horizontal.3")
            VStack(alignment: .leading, spacing: 8) {
                Slider(value: $goal.manualProgress, in: 0...1, step: 0.01) {
                    Text("Progress")
                } minimumValueLabel: {
                    Text("0%").font(.caption)
                } maximumValueLabel: {
                    Text("100%").font(.caption)
                }
                .tint(goal.accent.color)
                Text("No milestones yet — slide to track progress, or add milestones below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .card(cornerRadius: 22)
        }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Milestones"), symbol: "flag.checkered",
                          trailing: goal.milestones.isEmpty ? nil : "\(goal.completedMilestones)/\(goal.milestones.count)")
            VStack(spacing: 0) {
                ForEach(goal.sortedMilestones) { milestone in
                    HStack(spacing: 12) {
                        CheckButton(isOn: milestone.isDone, accent: goal.accent) {
                            withAnimation(.snappy) { milestone.isDone.toggle() }
                            if goal.progress >= 1 { celebrate += 1 }
                        }
                        Text(milestone.title)
                            .strikethrough(milestone.isDone, color: .secondary)
                            .foregroundStyle(milestone.isDone ? Color.secondary : Color.primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                goal.milestones.removeAll { $0 == milestone }
                                context.delete(milestone)
                            }
                        }
                    }
                    Divider().padding(.leading, 56)
                }

                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(goal.accent.color)
                        .frame(width: 44, height: 44)
                    TextField("Add a milestone", text: $newMilestone)
                        .focused($addFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(addMilestone)
                }
            }
            .card(cornerRadius: 22, padding: 10)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Tasks"), symbol: "checklist")
            let linked = goal.tasks.sorted { a, b in
                a.isDone != b.isDone ? !a.isDone : TaskItem.ordering(a, b)
            }
            ForEach(linked) { task in
                TaskRow(task: task, showGoal: false) { router.sheet = .task(task) }
            }
            Button {
                router.sheet = .newTask(goal)
            } label: {
                Label("Add Task for This Goal", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glass)
            .tint(goal.accent.color)
        }
    }

    private func addMilestone() {
        let title = newMilestone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let next = (goal.milestones.map(\.order).max() ?? -1) + 1
        withAnimation(.snappy) {
            goal.milestones.append(Milestone(title: title, order: next))
        }
        newMilestone = ""
        addFieldFocused = true
    }
}
