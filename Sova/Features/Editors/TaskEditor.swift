import SwiftUI
import SwiftData

/// Make or edit a task, in the same sticker style as rituals and goals: a
/// live card up top, quick choices instead of form rows, and a big button
/// docked at the bottom. Typing "tomorrow 6pm !!" offers to fill it all in.
struct TaskEditor: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let task: TaskItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt) private var goals: [Goal]

    @State private var title: String
    @State private var notes: String
    @State private var day: DayChoice
    @State private var date: Date
    @State private var time: TimeChoice
    @State private var clock: Date
    @State private var priority: Priority
    @State private var accent: Accent
    @State private var goal: Goal?
    @State private var repeatRule: RepeatRule
    @State private var checklist: [ChecklistItem]
    @State private var checklistDraft = ""
    @State private var confirmDelete = false
    @State private var wiggle = 0
    @State private var breakingDown = false
    @FocusState private var focus: Field?

    private enum Field: Hashable { case title, notes, checklist }

    enum DayChoice: Hashable, CaseIterable {
        case today, tomorrow, weekend, nextWeek, custom, none

        var label: String {
            switch self {
            case .today: String(localized: "Today")
            case .tomorrow: String(localized: "Tomorrow")
            case .weekend: String(localized: "This weekend")
            case .nextWeek: String(localized: "Next week")
            case .custom: String(localized: "Pick a date")
            case .none: String(localized: "Someday")
            }
        }

        /// The day this choice means, from today.
        var day: Date? {
            let cal = Calendar.current
            let today = Date.now.startOfDay
            switch self {
            case .today: return today
            case .tomorrow: return today.adding(days: 1)
            case .weekend:
                if cal.isDateInWeekend(today) { return today }
                return cal.nextDate(after: today, matching: DateComponents(weekday: 7), matchingPolicy: .nextTime)
            case .nextWeek:
                return cal.nextDate(after: today, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)
            case .custom, .none: return nil
            }
        }
    }

    enum TimeChoice: Hashable, CaseIterable {
        case none, morning, noon, evening, night, custom

        var label: String {
            switch self {
            case .none: String(localized: "Anytime")
            case .morning: String(localized: "9 AM")
            case .noon: String(localized: "Noon")
            case .evening: String(localized: "6 PM")
            case .night: String(localized: "9 PM")
            case .custom: String(localized: "Other time")
            }
        }

        var hour: Int? {
            switch self {
            case .morning: 9
            case .noon: 12
            case .evening: 18
            case .night: 21
            default: nil
            }
        }

        static func matching(_ date: Date) -> TimeChoice {
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            guard c.minute == 0 else { return .custom }
            return [.morning, .noon, .evening, .night].first { $0.hour == c.hour } ?? .custom
        }
    }

    init(task: TaskItem?, defaultGoal: Goal? = nil) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        let due = task?.dueDate
        let initialDay: DayChoice = if task == nil {
            .today
        } else if let due {
            Calendar.current.isDateInToday(due) ? .today : Calendar.current.isDateInTomorrow(due) ? .tomorrow : .custom
        } else {
            .none
        }
        _day = State(initialValue: initialDay)
        _date = State(initialValue: due?.startOfDay ?? Date.now.startOfDay)
        _time = State(initialValue: (task?.hasTime ?? false) ? TimeChoice.matching(due ?? .now) : .none)
        _clock = State(initialValue: (task?.hasTime ?? false) ? (due ?? .now)
                       : Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now)
        _priority = State(initialValue: task?.priority ?? .low)
        _accent = State(initialValue: task?.accent ?? defaultGoal?.accent ?? .ember)
        _goal = State(initialValue: task?.goal ?? defaultGoal)
        _repeatRule = State(initialValue: task?.repeatRule ?? .none)
        _checklist = State(initialValue: task?.checklist ?? [])
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var tone: StickerTone { StickerTone(accent) }

    /// The day picked, or nil for someday.
    private var chosenDay: Date? {
        switch day {
        case .none: nil
        case .custom: date.startOfDay
        default: day.day ?? date.startOfDay
        }
    }

    /// The full due date, with the time if one was picked.
    private var chosenDue: Date? {
        guard let base = chosenDay else { return nil }
        let cal = Calendar.current
        if let hour = time.hour {
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: base)
        }
        if time == .custom {
            let c = cal.dateComponents([.hour, .minute], from: clock)
            return cal.date(bySettingHour: c.hour ?? 18, minute: c.minute ?? 0, second: 0, of: base)
        }
        return base
    }

    private var hasTime: Bool { chosenDay != nil && time != .none }

    /// What typing "tomorrow 6pm !!" understood, if anything, for a new task.
    /// Parsed once per edit of the title, not on every render.
    @State private var parsed: ParsedTask? = nil

    private func parse() -> ParsedTask? {
        guard task == nil, !trimmedTitle.isEmpty else { return nil }
        let result = QuickParse.parse(title, goals: goals.map(\.title))
        guard result.dateRange != nil || result.priorityRange != nil || result.repeatRange != nil
                || result.goalRange != nil,
              !result.title.isEmpty else { return nil }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    preview

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField(String(localized: "What needs doing?"), text: $title, axis: .vertical)
                                .font(.allo(size: 24, weight: .heavy, relativeTo: .title2))
                                .tracking(-0.6)
                                .foregroundStyle(Color.ink)
                                .lineLimit(1...3)
                                .focused($focus, equals: .title)
                                .submitLabel(.done)
                            Divider().overlay(Color.hairline)
                            TextField(String(localized: "Add a note"), text: $notes, axis: .vertical)
                                .font(.allo(size: 16, weight: .semibold, relativeTo: .body))
                                .foregroundStyle(Color.ink)
                                .lineLimit(1...6)
                                .focused($focus, equals: .notes)
                        }
                        .surface(cornerRadius: 26, padding: 18)

                        if let parsed { understood(parsed) }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: parsed)

                    EditorCard(title: String(localized: "Checklist"),
                               footer: checklist.isEmpty ? String(localized: "Optional. Small steps inside this task.")
                                                         : String(localized: "\(checklist.filter(\.done).count) of \(checklist.count) done")) {
                        checklistEditor
                    }

                    EditorCard(title: String(localized: "When"), footer: whenFooter) {
                        VStack(alignment: .leading, spacing: 14) {
                            FlowChips(choices: DayChoice.allCases, selection: $day, tone: tone) { $0.label }
                            if day == .custom {
                                DatePicker(String(localized: "Date"), selection: $date,
                                           in: Date.now.startOfDay..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(tone == .yellow || tone == .lime ? tone.deep : tone.fill)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            if day != .none {
                                Divider().overlay(Color.hairline)
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.inkSecondary)
                                    MonoCaps(String(localized: "Time"))
                                }
                                FlowChips(choices: TimeChoice.allCases, selection: $time, tone: tone) { $0.label }
                                if time == .custom {
                                    DatePicker(String(localized: "Time"), selection: $clock, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 150)
                                        .clipped()
                                        .transition(.opacity)
                                }
                            }
                        }
                    }

                    if day != .none {
                        EditorCard(title: String(localized: "Repeat")) {
                            FlowChips(choices: RepeatRule.allCases, selection: $repeatRule, tone: tone) { $0.label }
                        }
                        .transition(.opacity)
                    }

                    EditorCard(title: String(localized: "Priority")) {
                        priorityTiles
                    }

                    if !goals.isEmpty {
                        EditorCard(title: String(localized: "Goal"),
                                   footer: String(localized: "Finishing it counts toward the goal.")) {
                            goalChips
                        }
                    }

                    EditorCard(title: String(localized: "Color")) {
                        TonePicker(selection: $accent)
                    }

                    if task != nil {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label(String(localized: "Delete task"), systemImage: "trash")
                                .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                                .foregroundStyle(Color.ember)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(Color.ember.opacity(0.1), in: .capsule)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .readableColumn()
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: day)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: time)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background { CanvasBackground() }
            .safeAreaInset(edge: .bottom) {
                EditorSaveBar(title: task == nil ? String(localized: "Add task") : String(localized: "Save changes"),
                              tone: tone, enabled: !trimmedTitle.isEmpty,
                              hint: String(localized: "Write what needs doing first"), action: save)
            }
            .navigationTitle(task == nil ? String(localized: "New Task") : String(localized: "Edit Task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EditorCloseButton { dismiss() } }
            .confirmationDialog(String(localized: "Delete this task?"), isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button(String(localized: "Delete Task"), role: .destructive, action: delete)
            }
            .onChange(of: day) { _, choice in
                if let picked = choice.day { date = picked }
                if choice == .none { repeatRule = .none }
            }
            .onAppear { if task == nil { focus = .title } }
            .onChange(of: title, initial: true) { parsed = parse() }
        }
        .tint(Color.ink)
    }

    private var checklistEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let task, task.keepsSlipping, checklist.isEmpty {
                slippingNudge(task)
            }
            ForEach($checklist) { $item in
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { item.done.toggle() }
                        Sounds.play(item.done ? .check : .uncheck)
                        Haptics.pop(0.5)
                    } label: {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(item.done ? (tone == .yellow || tone == .lime ? tone.deep : tone.fill) : Color.inkTertiary)
                            .contentTransition(.symbolEffect(.replace))
                            .contentShape(Circle().inset(by: -11))
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(item.done ? String(localized: "Mark step not done") : String(localized: "Mark step done"))
                    TextField(String(localized: "Step"), text: $item.title)
                        .font(.allo(size: 16, weight: .semibold, relativeTo: .body))
                        .strikethrough(item.done, color: Color.inkTertiary)
                        .foregroundStyle(item.done ? Color.inkTertiary : Color.ink)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            checklist.removeAll { $0.id == item.id }
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color.inkTertiary)
                            .frame(width: 26, height: 26)
                            .background(Color.well, in: .circle)
                            .contentShape(Circle().inset(by: -9))
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(String(localized: "Remove step"))
                }
                .frame(minHeight: 36)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.inkTertiary)
                TextField(checklist.isEmpty ? String(localized: "Add a step") : String(localized: "Next step"),
                          text: $checklistDraft)
                    .font(.allo(size: 16, weight: .semibold, relativeTo: .body))
                    .focused($focus, equals: .checklist)
                    .submitLabel(.next)
                    .onSubmit(addChecklistItem)
            }
            .frame(minHeight: 36)

            if StepSuggester.isAvailable && !trimmedTitle.isEmpty && checklist.count < 3 {
                Button(action: breakItDown) {
                    HStack(spacing: 8) {
                        if breakingDown {
                            ProgressView().tint(StickerTone.indigo.deep)
                        } else {
                            Image(systemName: "sparkles").font(.system(size: 14, weight: .heavy))
                        }
                        Text(breakingDown ? String(localized: "Thinking…") : String(localized: "Break it down"))
                            .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                    }
                    .foregroundStyle(StickerTone.indigo.deep)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(StickerTone.indigo.fill, in: .capsule)
                }
                .buttonStyle(.pressable)
                .disabled(breakingDown)
                .padding(.top, 6)
                .accessibilityHint(String(localized: "Uses Apple Intelligence on your iPhone"))
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    /// A gentle word when a task keeps getting pushed back.
    private func slippingNudge(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.uturn.right")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(StickerTone.orange.deep)
                .frame(width: 28, height: 28)
                .background(StickerTone.orange.fill, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Moved \(task.deferCount) times")
                    .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                    .foregroundStyle(Color.ink)
                Text(StepSuggester.isAvailable
                     ? String(localized: "Big tasks hide. Break it into small steps and start with the first.")
                     : String(localized: "Big tasks hide. Add the first small step below."))
                    .font(.allo(size: 13, weight: .medium, relativeTo: .footnote))
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    /// Asks the on-device model for small steps and adds them to the checklist.
    private func breakItDown() {
        guard !breakingDown, !trimmedTitle.isEmpty else { return }
        breakingDown = true
        Haptics.soft(0.5)
        Task {
            let steps = (try? await StepSuggester.suggest(for: trimmedTitle, notes: notes)) ?? []
            breakingDown = false
            guard !steps.isEmpty else {
                focus = .checklist
                router.show(Toast(message: String(localized: "Couldn't think of steps right now. Add the first one yourself.")))
                return
            }
            let existing = Set(checklist.map { $0.title.lowercased() })
            for (i, step) in steps.enumerated() where !existing.contains(step.lowercased()) {
                try? await Task.sleep(for: .milliseconds(i == 0 ? 0 : 120))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { checklist.append(ChecklistItem(title: step)) }
                Haptics.pop(0.4)
            }
            Sounds.play(.pop)
        }
    }

    private func addChecklistItem() {
        let title = checklistDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { checklist.append(ChecklistItem(title: title)) }
        checklistDraft = ""
        focus = .checklist
        Haptics.pop(0.4)
    }

    private var whenFooter: String? {
        guard let due = chosenDue else { return String(localized: "It'll wait on Today until you get to it.") }
        return due.formatted(.dateTime.weekday(.wide).day().month(.wide))
            + (hasTime ? " · " + due.formatted(date: .omitted, time: .shortened) : "")
    }

    // MARK: Understood from the title

    private func understood(_ parsed: ParsedTask) -> some View {
        var parts: [String] = []
        if let date = parsed.dueDate { parts.append(date.relativeDayText(includingTime: parsed.hasTime)) }
        if parsed.repeatRule != .none { parts.append(parsed.repeatRule.label) }
        if parsed.priority != .low { parts.append(parsed.priority == .high ? String(localized: "High priority") : String(localized: "Medium priority")) }
        if let i = parsed.goalIndex, goals.indices.contains(i) { parts.append(goals[i].title) }
        return Button { apply(parsed) } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "Use “\(parsed.title)”"))
                        .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                        .lineLimit(1)
                    Text(parts.joined(separator: " · "))
                        .font(.allo(size: 13, weight: .bold, relativeTo: .footnote))
                        .opacity(0.75)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(StickerTone.indigo.deep)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.pressable)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityHint(String(localized: "Fills in the date, time and priority from what you typed"))
    }

    private func apply(_ parsed: ParsedTask) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            title = parsed.title
            if let due = parsed.dueDate {
                date = due.startOfDay
                if Calendar.current.isDateInToday(due) { day = .today }
                else if Calendar.current.isDateInTomorrow(due) { day = .tomorrow }
                else { day = .custom }
                if parsed.hasTime {
                    time = TimeChoice.matching(due)
                    clock = due
                }
            }
            if parsed.priority != .low { priority = parsed.priority }
            if parsed.repeatRule != .none { repeatRule = parsed.repeatRule }
            if let i = parsed.goalIndex, goals.indices.contains(i) { goal = goals[i] }
        }
        wiggle += 1
        Haptics.pop()
    }

    // MARK: Priority and goal

    private var priorityTiles: some View {
        HStack(spacing: 8) {
            ForEach(Priority.allCases) { level in
                let on = priority == level
                let sticker: StickerTone = switch level {
                case .low: .mint
                case .medium: .orange
                case .high: .pink
                }
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { priority = level }
                } label: {
                    VStack(spacing: 4) {
                        Text(level.marks.isEmpty ? "·" : level.marks)
                            .font(.allo(size: 20, weight: .heavy))
                        Text(level.label)
                            .font(.allo(size: 13, weight: .heavy, relativeTo: .caption))
                    }
                    .foregroundStyle(on ? sticker.deep : Color.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(on ? sticker.fill : Color.well, in: .rect(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(sticker.deep.opacity(on ? 0.9 : 0), lineWidth: 2)
                    }
                    .rotationEffect(.degrees(on ? -2 : 0))
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: priority)
    }

    private var goalChips: some View {
        FlowLayout(spacing: 8) {
            goalChip(nil)
            ForEach(goals) { goalChip($0) }
        }
        .sovaFeedback(.selection, trigger: goal?.persistentModelID)
    }

    private func goalChip(_ option: Goal?) -> some View {
        let on = goal?.persistentModelID == option?.persistentModelID
        let sticker = option.map { StickerTone($0.accent) } ?? .indigo
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                goal = option
                if let option { accent = option.accent }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: option?.symbol ?? "circle.slash")
                    .font(.system(size: 13, weight: .bold))
                Text(option?.title ?? String(localized: "None"))
                    .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                    .lineLimit(1)
            }
            .foregroundStyle(on ? (sticker == .indigo ? Color.white : sticker.deep) : Color.ink)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(on ? sticker.fill : Color.well, in: .capsule)
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: The live card

    private var preview: some View {
        let ink = tone == .indigo ? Color.white : tone.deep
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .strokeBorder(ink.opacity(0.55), lineWidth: 2.5)
                    .frame(width: 28, height: 28)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    MonoCaps(task == nil ? String(localized: "New task") : String(localized: "Task"), color: ink.opacity(0.7))
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if !priority.marks.isEmpty {
                            Text(priority.marks)
                                .font(.allo(size: 22, weight: .heavy))
                                .foregroundStyle(tone == .pink ? Color.ember : StickerTone.pink.deep)
                                .transition(.scale.combined(with: .opacity))
                        }
                        Text(trimmedTitle.isEmpty ? String(localized: "Your task") : (parsed?.title ?? trimmedTitle))
                            .font(.allo(size: 22, weight: .heavy, relativeTo: .title3))
                            .tracking(-0.6)
                            .lineLimit(2)
                            .opacity(trimmedTitle.isEmpty ? 0.45 : 1)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                if let due = chosenDue {
                    previewChip(symbol: hasTime ? "clock.fill" : "calendar",
                                text: due.relativeDayText(includingTime: hasTime), ink: ink)
                } else {
                    previewChip(symbol: "tray", text: String(localized: "Someday"), ink: ink)
                }
                if repeatRule != .none && day != .none {
                    previewChip(symbol: "repeat", text: repeatRule.label, ink: ink)
                }
                if let goal {
                    previewChip(symbol: goal.symbol, text: goal.title, ink: ink)
                }
            }
            .lineLimit(1)
        }
        .foregroundStyle(ink)
        .block(tone, cornerRadius: 30)
        .rotationEffect(.degrees(-1.5))
        .phaseAnimator(reduceMotion ? [0] : [0, 1], trigger: wiggle) { view, phase in
            view.rotationEffect(.degrees(phase == 1 ? 2.5 : 0)).scaleEffect(phase == 1 ? 1.03 : 1)
        } animation: { _ in .open(0.28) }
        .padding(6)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: accent)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: priority)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Preview: \(trimmedTitle.isEmpty ? String(localized: "Your task") : trimmedTitle)"))
    }

    private func previewChip(symbol: String, text: String, ink: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 11, weight: .bold))
            Text(text).font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Color.white.opacity(tone == .indigo ? 0.14 : 0.5), in: .capsule)
        .contentTransition(.opacity)
    }

    // MARK: Saving

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        let isNew = task == nil
        let target: TaskItem
        if let task {
            target = task
        } else {
            target = TaskItem(title: trimmedTitle)
            context.insert(target)
        }
        target.title = trimmedTitle
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.hasTime = hasTime
        target.dueDate = chosenDue
        target.priority = priority
        target.accent = accent
        target.goal = goal
        target.repeatRule = chosenDay == nil ? .none : repeatRule
        var steps = checklist.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        let draft = checklistDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !draft.isEmpty { steps.append(ChecklistItem(title: draft)) }
        target.checklist = steps
        TaskAlerts.schedule(target)
        SovaRefresh.changed(context)
        Haptics.success()
        if target.hasTime { Task { await TaskAlerts.requestPermissionIfNeeded() } }
        if isNew {
            let when = chosenDue.map { $0.relativeDayText(includingTime: hasTime) } ?? String(localized: "someday")
            let laterOn = chosenDue.map { $0 >= Date.now.endOfDay } ?? false
            router.show(Toast(message: laterOn ? String(localized: "Added for \(when). It's in Tasks.")
                                               : String(localized: "Added for \(when)")))
        }
        dismiss()
    }

    private func delete() {
        guard let task else { return }
        TaskAlerts.cancel(task)
        context.delete(task)
        SovaRefresh.changed(context)
        dismiss()
    }
}
