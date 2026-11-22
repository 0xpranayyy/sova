import SwiftUI
import SwiftData

/// Make or edit a goal. The card up top is the goal as it will look on the
/// Goals tab, and fills in as you go.
struct GoalEditor: View {
    let goal: Goal?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var title: String
    @State private var symbol: String
    @State private var notes: String
    @State private var deadlineChoice: DeadlineChoice
    @State private var deadline: Date
    @State private var accent: Accent
    @State private var stepDraft = ""
    @State private var newSteps: [String] = []
    @State private var wiggle = 0
    @State private var suggesting = false
    @FocusState private var focus: Field?

    private enum Field: Hashable { case title, step, notes }

    /// Quick deadlines, or a date you pick.
    enum DeadlineChoice: Hashable, CaseIterable {
        case none, month, threeMonths, sixMonths, custom

        var label: String {
            switch self {
            case .none: String(localized: "None")
            case .month: String(localized: "1 month")
            case .threeMonths: String(localized: "3 months")
            case .sixMonths: String(localized: "6 months")
            case .custom: String(localized: "Pick a date")
            }
        }

        var months: Int? {
            switch self {
            case .month: 1
            case .threeMonths: 3
            case .sixMonths: 6
            default: nil
            }
        }
    }

    init(goal: Goal?) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "")
        _symbol = State(initialValue: goal?.symbol ?? "flag.checkered")
        _notes = State(initialValue: goal?.notes ?? "")
        _deadlineChoice = State(initialValue: goal == nil ? .threeMonths : (goal?.deadline == nil ? .none : .custom))
        _deadline = State(initialValue: goal?.deadline
                          ?? Calendar.current.date(byAdding: .month, value: 3, to: Date.now.startOfDay) ?? .now)
        _accent = State(initialValue: goal?.accent ?? .tide)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var tone: StickerTone { StickerTone(accent) }
    private var hasDeadline: Bool { deadlineChoice != .none }
    private var trimmedDraft: String { stepDraft.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var draftSteps: [String] { trimmedDraft.isEmpty ? newSteps : newSteps + [trimmedDraft] }

    private static let ideas: [SuggestionChips.Idea] = [
        .init(title: String(localized: "Run a 5K"), symbol: "figure.run", accent: .ember),
        .init(title: String(localized: "Read 12 books"), symbol: "book.closed", accent: .marigold),
        .init(title: String(localized: "Learn Spanish"), symbol: "globe.europe.africa", accent: .lagoon),
        .init(title: String(localized: "Save $1,000"), symbol: "dollarsign", accent: .lime),
        .init(title: String(localized: "Launch my side project"), symbol: "paperplane", accent: .plum),
        .init(title: String(localized: "Get fit"), symbol: "dumbbell", accent: .rose),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    preview

                    VStack(alignment: .leading, spacing: 12) {
                        TextField(String(localized: "What do you want to achieve?"), text: $title, axis: .vertical)
                            .font(.allo(size: 24, weight: .heavy, relativeTo: .title2))
                            .tracking(-0.6)
                            .foregroundStyle(Color.ink)
                            .lineLimit(1...3)
                            .focused($focus, equals: .title)
                            .submitLabel(.done)
                            .surface(cornerRadius: 26, padding: 18)

                        if goal == nil {
                            SuggestionChips(ideas: Self.ideas) { idea in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    title = idea.title
                                    symbol = idea.symbol
                                    accent = idea.accent
                                }
                                wiggle += 1
                                Haptics.pop()
                            }
                        }
                    }

                    EditorCard(title: String(localized: "Deadline"), footer: deadlineFooter) {
                        VStack(alignment: .leading, spacing: 12) {
                            FlowChips(choices: DeadlineChoice.allCases, selection: $deadlineChoice, tone: tone) { $0.label }
                                .onChange(of: deadlineChoice) { _, choice in
                                    if let months = choice.months,
                                       let date = Calendar.current.date(byAdding: .month, value: months, to: Date.now.startOfDay) {
                                        deadline = date
                                    }
                                }
                            if deadlineChoice == .custom {
                                DatePicker(String(localized: "Date"), selection: $deadline,
                                           in: Date.now.startOfDay..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(tone == .yellow || tone == .lime ? tone.deep : tone.fill)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    if goal == nil {
                        EditorCard(title: String(localized: "Steps"),
                                   footer: String(localized: "Optional. Your progress follows the steps you finish.")) {
                            steps
                        }
                    }

                    EditorCard(title: String(localized: "Why it matters")) {
                        TextField(String(localized: "A note to future you"), text: $notes, axis: .vertical)
                            .font(.allo(size: 16, weight: .semibold, relativeTo: .body))
                            .lineLimit(2...6)
                            .focused($focus, equals: .notes)
                    }

                    EditorCard(title: String(localized: "Color")) {
                        TonePicker(selection: $accent)
                    }

                    EditorCard(title: String(localized: "Icon")) {
                        ToneSymbolGrid(selection: $symbol, tone: tone, symbols: SymbolPicker.goalSymbols)
                    }
                }
                .readableColumn()
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: deadlineChoice)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background { CanvasBackground() }
            .safeAreaInset(edge: .bottom) {
                EditorSaveBar(title: goal == nil ? String(localized: "Create goal") : String(localized: "Save changes"),
                              tone: tone, enabled: !trimmedTitle.isEmpty,
                              hint: String(localized: "Name your goal first"), action: save)
            }
            .navigationTitle(goal == nil ? String(localized: "New Goal") : String(localized: "Edit Goal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EditorCloseButton { dismiss() } }
            .onAppear {
                if goal == nil { focus = .title }
            }
        }
        .tint(Color.ink)
    }

    private var deadlineFooter: String {
        guard hasDeadline else { return String(localized: "No rush. You can add one later.") }
        let days = Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: deadline.startOfDay).day ?? 0
        return deadline.formatted(.dateTime.weekday(.abbreviated).day().month(.wide).year())
            + " · " + String(localized: "\(days) days from today")
    }

    // MARK: Steps

    private var steps: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(newSteps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.allo(size: 13, weight: .heavy).monospacedDigit())
                        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                        .frame(width: 26, height: 26)
                        .background(tone.fill, in: .circle)
                    Text(step)
                        .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                        .foregroundStyle(Color.ink)
                    Spacer(minLength: 4)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { _ = newSteps.remove(at: index) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Color.inkSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color.well, in: .circle)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(String(localized: "Remove \(step)"))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 26, height: 26)
                    .background(Color.well, in: .circle)
                TextField(newSteps.isEmpty ? String(localized: "First step") : String(localized: "Next step"),
                          text: $stepDraft)
                    .font(.allo(size: 16, weight: .semibold, relativeTo: .body))
                    .focused($focus, equals: .step)
                    .submitLabel(.next)
                    .onSubmit(addStep)
                if !trimmedDraft.isEmpty {
                    Button(String(localized: "Add"), action: addStep)
                        .font(.allo(size: 14, weight: .heavy))
                        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(tone.fill, in: .capsule)
                        .buttonStyle(.pressable)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(minHeight: 34)

            if StepSuggester.isAvailable && !trimmedTitle.isEmpty {
                Button(action: suggestSteps) {
                    HStack(spacing: 8) {
                        if suggesting {
                            ProgressView().tint(StickerTone.indigo.deep)
                        } else {
                            Image(systemName: "sparkles").font(.system(size: 14, weight: .heavy))
                        }
                        Text(suggesting ? String(localized: "Thinking…") : String(localized: "Suggest steps"))
                            .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                    }
                    .foregroundStyle(StickerTone.indigo.deep)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(StickerTone.indigo.fill, in: .capsule)
                }
                .buttonStyle(.pressable)
                .disabled(suggesting)
                .padding(.top, 6)
                .accessibilityHint(String(localized: "Uses Apple Intelligence on your iPhone"))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: trimmedDraft.isEmpty)
    }

    /// Asks the on-device model for first steps and adds them.
    private func suggestSteps() {
        guard !suggesting, !trimmedTitle.isEmpty else { return }
        suggesting = true
        Haptics.soft(0.5)
        Task {
            let steps = (try? await StepSuggester.suggest(for: trimmedTitle, notes: notes)) ?? []
            suggesting = false
            guard !steps.isEmpty else {
                router.show(Toast(message: String(localized: "Couldn't think of steps right now. Try a clearer goal.")))
                return
            }
            let existing = Set(newSteps.map { $0.lowercased() })
            for (i, step) in steps.enumerated() where !existing.contains(step.lowercased()) {
                try? await Task.sleep(for: .milliseconds(i == 0 ? 0 : 120))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { newSteps.append(step) }
                Haptics.pop(0.4)
            }
            Sounds.play(.pop)
        }
    }

    private func addStep() {
        guard !trimmedDraft.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { newSteps.append(trimmedDraft) }
        stepDraft = ""
        focus = .step
        Haptics.pop()
    }

    // MARK: The live card

    private var preview: some View {
        let ink = tone == .indigo ? Color.white : tone.deep
        let count = goal?.steps.count ?? draftSteps.count
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(tone == .indigo ? tone.deep : tone.fill)
                    .frame(width: 46, height: 46)
                    .background(tone == .indigo ? Color.white.opacity(0.15) : tone.deep,
                                in: .rect(cornerRadius: 15, style: .continuous))
                    .rotationEffect(.degrees(-5))
                    .contentTransition(.symbolEffect(.replace))
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Int(((goal?.progress ?? 0) * 100).rounded()), format: .number)
                        .font(.hero(46, weight: .heavy))
                        .tracking(-2)
                    Text("%").font(.hero(22, weight: .heavy)).opacity(0.5)
                }
            }
            Text(trimmedTitle.isEmpty ? String(localized: "Your goal") : trimmedTitle)
                .font(.allo(size: 22, weight: .heavy, relativeTo: .title3))
                .tracking(-0.6)
                .lineLimit(2)
                .opacity(trimmedTitle.isEmpty ? 0.45 : 1)
                .padding(.top, 8)
            MonoCaps(previewCaption, color: ink.opacity(0.75))
                .padding(.top, 4)
            HStack(spacing: 4) {
                ForEach(0..<max(count, 1), id: \.self) { _ in
                    Capsule().fill(ink.opacity(0.18)).frame(height: 8)
                }
            }
            .padding(.top, 12)
        }
        .foregroundStyle(ink)
        .block(tone, cornerRadius: 30)
        .rotationEffect(.degrees(-1.5))
        .phaseAnimator([0, 1], trigger: wiggle) { view, phase in
            view.rotationEffect(.degrees(phase == 1 ? 2.5 : 0)).scaleEffect(phase == 1 ? 1.03 : 1)
        } animation: { _ in .spring(response: 0.3, dampingFraction: 0.5) }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Preview: \(trimmedTitle.isEmpty ? String(localized: "Your goal") : trimmedTitle)"))
    }

    private var previewCaption: String {
        var parts: [String] = []
        if hasDeadline {
            let days = Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: deadline.startOfDay).day ?? 0
            parts.append(String(localized: "\(days) days left"))
        } else {
            parts.append(String(localized: "No deadline"))
        }
        let count = goal?.steps.count ?? draftSteps.count
        if count > 0 { parts.append(String(localized: "\(count) steps")) }
        return parts.joined(separator: " · ")
    }

    // MARK: Saving

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        let target: Goal
        if let goal {
            target = goal
        } else {
            target = Goal(title: trimmedTitle)
            context.insert(target)
        }
        target.title = trimmedTitle
        target.symbol = symbol
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.deadline = hasDeadline ? deadline.startOfDay : nil
        target.accent = accent

        if goal == nil {
            let start = (target.steps.map(\.order).max() ?? -1) + 1
            for (i, step) in draftSteps.enumerated() {
                target.addStep(Milestone(title: step, order: start + i))
            }
        }
        try? context.save()
        SovaRefresh.changed(context)
        Haptics.success()
        if goal == nil {
            router.show(Toast(message: String(localized: "Goal created. You've got this.")))
        }
        dismiss()
    }
}

/// Choices as wrapping capsules; the chosen one in the goal's color.
struct FlowChips<Choice: Hashable>: View {
    let choices: [Choice]
    @Binding var selection: Choice
    let tone: StickerTone
    let label: (Choice) -> String

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(choices, id: \.self) { choice in
                let on = selection == choice
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selection = choice }
                } label: {
                    Text(label(choice))
                        .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                        .foregroundStyle(on ? (tone == .indigo ? Color.white : tone.deep) : Color.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(on ? tone.fill : Color.well, in: .capsule)
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }
}
