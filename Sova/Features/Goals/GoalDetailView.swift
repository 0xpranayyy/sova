import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newMilestone = ""
    @State private var confirmDelete = false
    @State private var cheers = 0
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
            .readableColumn()
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
        .onChange(of: goal.progress >= 1) { _, finished in
            // The whole goal, done: sparkles and the full flourish.
            if finished {
                cheers += 1
                Haptics.celebrate()
            }
        }
        .onDisappear { SovaRefresh.changed(context) }
    }

    private var hero: some View {
        let tone = StickerTone(goal.accent)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                MonoCaps(goal.deadlineText ?? String(localized: "No deadline"),
                         color: tone == .indigo ? tone.deep : tone.deep)
                if goal.isBehindPace { BehindPacePill(ink: tone.deep) }
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
            HStack(spacing: 8) {
                if let deadline = goal.deadline {
                    TiltPill(text: "📅 " + deadline.formatted(.dateTime.month(.abbreviated).day()),
                             tone: tone == .yellow ? .indigo : .yellow, tilt: -3, size: 12)
                }
                if !goal.steps.isEmpty {
                    TiltPill(text: String(localized: "\(goal.completedMilestones) of \(goal.steps.count) steps"),
                             tone: tone == .mint ? .pink : .mint, tilt: 3, size: 12)
                }
                if goal.progress >= 1 {
                    TiltPill(text: String(localized: "Achieved 🏆"), tone: .pink, tilt: -2, size: 12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 14)
            if goal.isBehindPace {
                Text(paceHint)
                    .font(.allo(size: 14, weight: .bold, relativeTo: .footnote))
                    .opacity(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
        }
        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
        .block(tone, cornerRadius: 32, padding: 22)
        .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 170, height: 140), count: 16) }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: goal.progress >= 1)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    /// What to do about a goal that's behind: the next step, or a nudge.
    private var paceHint: String {
        if let step = goal.sortedMilestones.first(where: { !$0.isDone }) {
            return String(localized: "Time's moving faster than progress. Try \"\(step.title)\" this week.")
        }
        if goal.steps.isEmpty {
            return String(localized: "Time's moving faster than progress. Add a few small steps to get going.")
        }
        return String(localized: "Time's moving faster than progress.")
    }

    private var manualProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(String(localized: "Progress"))
            VStack(alignment: .leading, spacing: 10) {
                Slider(value: $goal.manualProgress, in: 0...1, step: 0.01) {
                    Text("Progress")
                }
                .tint(StickerTone(goal.accent) == .yellow ? StickerTone.yellow.deep : StickerTone(goal.accent).fill)
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
                ForEach(Array(goal.sortedMilestones.enumerated()), id: \.element.id) { index, milestone in
                    let tone = StickerTone(goal.accent)
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { milestone.isDone.toggle() }
                            if milestone.isDone { Haptics.success(); Sounds.play(.check) } else { Sounds.play(.uncheck) }
                        } label: {
                            ZStack {
                                Circle().fill(milestone.isDone ? tone.fill : Color.well)
                                if milestone.isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text("\(index + 1)")
                                        .font(.allo(size: 14, weight: .heavy, relativeTo: .footnote).monospacedDigit())
                                        .foregroundStyle(Color.inkSecondary)
                                }
                            }
                            .frame(width: 34, height: 34)
                            .contentShape(Circle().inset(by: -5))
                            .scaleEffect(milestone.isDone ? 1.05 : 1)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel(milestone.isDone ? String(localized: "Mark \(milestone.title) not done")
                                                             : String(localized: "Mark \(milestone.title) done"))
                        Text(milestone.title)
                            .font(.allo(size: 17, weight: .heavy, relativeTo: .body))
                            .tracking(-0.3)
                            .strikethrough(milestone.isDone, color: Color.inkTertiary)
                            .foregroundStyle(milestone.isDone ? Color.inkTertiary : Color.ink)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(.rect)
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                goal.milestones?.removeAll { $0 == milestone }
                                context.delete(milestone)
                            }
                        }
                    }
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 60)
                }

                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().strokeBorder(Color.inkTertiary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                    TextField(goal.steps.isEmpty ? String(localized: "Add the first step") : String(localized: "Add a step"),
                              text: $newMilestone)
                        .font(.allo(size: 17, weight: .semibold, relativeTo: .body))
                        .focused($addFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(addMilestone)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
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
        Haptics.pop(0.5, sound: true)
    }
}
