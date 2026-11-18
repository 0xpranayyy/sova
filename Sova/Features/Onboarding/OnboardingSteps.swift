import SwiftUI

// Each step: a big, tight, left-aligned headline, one quiet supporting
// line, and a single interactive idea. Lime only marks what's chosen.

private struct StepHeadline: View {
    let text: String
    var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 32

    var body: some View {
        Text(text)
            .font(.hero(size, weight: .bold))
            .tracking(-0.8)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
            .reveal(index)
    }
}

private struct StepBody: View {
    let text: String
    var index = 1

    var body: some View {
        Text(text)
            .font(.allo(.body))
            .foregroundStyle(Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .reveal(index)
    }
}

private var accent: Color { SovaTheme.current.accent.color }

// MARK: - 1. Welcome

struct HelloStep: View {
    var look: CGSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OwlMark(size: 112, look: look)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .reveal(0)

            Text("Sova")
                .font(.hero(titleSize, weight: .bold))
                .tracking(-1.6)
                .foregroundStyle(Color.ink)
                .reveal(1)
            Text("A day planner for your tasks, rituals and goals.")
                .font(.allo(.title3))
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .reveal(2)
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - 2. How it works

struct PillarsStep: View {
    @State private var taskDone = false
    @State private var streakDays = 0
    @State private var goalProgress = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepHeadline(text: String(localized: "Three kinds of things"))
                StepBody(text: String(localized: "Tap the first one to check it off."))
                    .padding(.top, 10)

                VStack(spacing: 10) {
                    PillarCard(label: String(localized: "Tasks")) {
                        HStack(spacing: 4) {
                            CheckButton(isOn: taskDone, label: "Send the proposal") {
                                withAnimation(.snappy) { taskDone.toggle() }
                            }
                            .padding(.leading, -11)
                            Text("Send the proposal")
                                .font(.allo(.body, .medium))
                                .foregroundStyle(taskDone ? Color.inkTertiary : Color.ink)
                            Spacer()
                            Text("10:00").font(.mono(11.5)).foregroundStyle(Color.inkTertiary)
                        }
                    }
                    .reveal(2)

                    PillarCard(label: String(localized: "Rituals")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Morning pages").font(.allo(.body, .medium)).foregroundStyle(Color.ink)
                                Spacer()
                                Text("\(streakDays)d streak")
                                    .font(.mono(11.5))
                                    .foregroundStyle(Color.inkTertiary)
                                    .contentTransition(.numericText())
                            }
                            HStack(spacing: 5) {
                                ForEach(0..<7, id: \.self) { day in
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(day < streakDays ? accent : Color.well)
                                        .frame(height: 20)
                                }
                            }
                        }
                    }
                    .reveal(3)

                    PillarCard(label: String(localized: "Goals")) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Run a half marathon").font(.allo(.body, .medium)).foregroundStyle(Color.ink)
                                Spacer()
                                Text(goalProgress, format: .percent.precision(.fractionLength(0)))
                                    .font(.hero(22))
                                    .foregroundStyle(Color.ink)
                                    .contentTransition(.numericText(value: goalProgress))
                            }
                            ProgressLine(progress: goalProgress, color: accent, milestones: [true, true, false, false])
                        }
                    }
                    .reveal(4)
                }
                .padding(.top, 26)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .task { await play() }
    }

    private func play() async {
        if reduceMotion { streakDays = 5; goalProgress = 0.5; return }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.spring(response: 1.1, dampingFraction: 0.9)) { goalProgress = 0.5 }
        for day in 1...5 {
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { streakDays = day }
        }
    }
}

private struct PillarCard<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MonoCaps(label, size: 10.5)
            content
        }
        .surface(cornerRadius: 22, padding: 18)
    }
}

// MARK: - Shared field

/// A large text field on a quiet card, edged with the accent on focus.
struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var autofocus = true
    var onSubmit: () -> Void
    @FocusState private var focused: Bool
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 26

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.inkTertiary), axis: .vertical)
            .font(.hero(size))
            .tracking(-0.6)
            .foregroundStyle(Color.ink)
            .tint(accent)
            .lineLimit(1...3)
            .textContentType(contentType)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.continue)
            .focused($focused)
            .onChange(of: text) { _, newValue in
                if newValue.contains("\n") {
                    text = newValue.replacingOccurrences(of: "\n", with: "")
                    onSubmit()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color.surface, in: .rect(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(focused ? accent.opacity(0.6) : Color.white.opacity(0.07), lineWidth: 1)
            }
            .animation(.smooth(duration: 0.25), value: focused)
            .task {
                guard autofocus else { return }
                try? await Task.sleep(for: .milliseconds(550))
                focused = true
            }
    }
}

// MARK: - 3. Name

struct NameStep: View {
    @Binding var name: String
    var onSubmit: () -> Void

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        default: String(localized: "Good evening")
        }
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeadline(text: String(localized: "What should we call you?"))
            StepBody(text: String(localized: "Used for your greeting. Stored only on this iPhone."))
                .padding(.top, 10)

            GlassField(placeholder: String(localized: "Your name"), text: $name,
                       contentType: .givenName, onSubmit: onSubmit)
                .padding(.top, 28)
                .reveal(2)

            HStack(spacing: 8) {
                MonoCaps(String(localized: "Preview"), size: 10)
                Text(trimmed.isEmpty ? greeting : "\(greeting), \(trimmed)")
                    .font(.allo(.callout))
                    .foregroundStyle(Color.inkSecondary)
                    .contentTransition(.opacity)
            }
            .padding(.top, 14)
            .padding(.leading, 4)
            .animation(.smooth(duration: 0.25), value: trimmed)
            .reveal(3)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

// MARK: - 4. Rituals

struct RitualsStep: View {
    @Binding var selection: Set<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepHeadline(text: String(localized: "Pick a few rituals"))
                StepBody(text: String(localized: "Things you want to do regularly. You can change these later."))
                    .padding(.top, 10)

                ForEach(Array([DayPeriod.morning, .afternoon, .anytime, .evening].enumerated()), id: \.element) { index, period in
                    let items = RitualOption.all.filter { $0.period == period }
                    if !items.isEmpty {
                        MonoCaps(period.name)
                            .padding(.top, 22)
                            .padding(.bottom, 8)
                            .padding(.leading, 4)
                            .reveal(2 + index)
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { i, ritual in
                                if i > 0 { Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 66) }
                                RitualRow(ritual: ritual, selected: selection.contains(ritual.id)) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        if selection.contains(ritual.id) { selection.remove(ritual.id) }
                                        else { selection.insert(ritual.id) }
                                    }
                                }
                            }
                        }
                        .surface(cornerRadius: 20, padding: 0)
                        .reveal(2 + index)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct RitualRow: View {
    let ritual: RitualOption
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconTile(symbol: ritual.symbol, size: 36, active: selected)
                Text(ritual.title)
                    .font(.allo(.body, .medium))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text(Weekdays.summary(for: ritual.weekdays))
                    .font(.allo(.footnote))
                    .foregroundStyle(Color.inkTertiary)
                ZStack {
                    Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5).opacity(selected ? 0 : 1)
                    Circle().fill(accent).scaleEffect(selected ? 1 : 0.3).opacity(selected ? 1 : 0)
                    CheckmarkShape()
                        .trim(from: 0, to: selected ? 1 : 0)
                        .stroke(Color.inkInverse, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .padding(6.5)
                }
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.pressable)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selected)
        .accessibilityLabel(ritual.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - 5. Goal

struct GoalStep: View {
    @Binding var title: String
    var onSubmit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepHeadline(text: String(localized: "Set a goal"))
                StepBody(text: String(localized: "Something to work toward over the next few months. Optional."))
                    .padding(.top, 10)

                GlassField(placeholder: String(localized: "My goal is to…"), text: $title,
                           autofocus: false, onSubmit: onSubmit)
                    .padding(.top, 28)
                    .reveal(2)

                MonoCaps(String(localized: "Suggestions"))
                    .padding(.top, 24)
                    .padding(.bottom, 10)
                    .padding(.leading, 4)
                    .reveal(3)

                FlowLayout(spacing: 8) {
                    ForEach(GoalSuggestion.all) { suggestion in
                        let selected = title == suggestion.title
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                title = selected ? "" : suggestion.title
                            }
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: suggestion.symbol)
                                    .font(.allo(.footnote, .semibold))
                                Text(suggestion.title)
                                    .font(.allo(.subheadline, .medium))
                            }
                            .foregroundStyle(selected ? Color.inkInverse : Color.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .background(selected ? accent : Color.surface, in: .capsule)
                            .overlay(Capsule().strokeBorder(Color.white.opacity(selected ? 0 : 0.07)))
                        }
                        .buttonStyle(.pressable)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .reveal(3)

                MonoCaps(String(localized: "Due in 90 days. You can change this later."), size: 10)
                    .padding(.top, 22)
                    .padding(.leading, 4)
                    .reveal(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.selection, trigger: title)
    }
}

/// Wraps its children onto new lines, like words in a paragraph.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - 6. Reminders

struct RhythmStep: View {
    var name: String
    @Binding var morningOn: Bool
    @Binding var morning: Date
    @Binding var eveningOn: Bool
    @Binding var evening: Date

    @State private var dropped = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepHeadline(text: String(localized: "Want reminders?"))
                StepBody(text: String(localized: "One in the morning to plan the day, one in the evening to check it off. That's all Sova will ever send."))
                    .padding(.top, 10)

                NotificationPreview()
                    .padding(.top, 28)
                    .offset(y: dropped ? 0 : -20)
                    .opacity(dropped ? 1 : 0)
                    .scaleEffect(dropped ? 1 : 0.96)

                VStack(spacing: 0) {
                    reminderRow(title: String(localized: "Morning plan"), symbol: "sunrise",
                                isOn: $morningOn, time: $morning)
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 48)
                    reminderRow(title: String(localized: "Evening review"), symbol: "moon",
                                isOn: $eveningOn, time: $evening)
                }
                .surface(cornerRadius: 20, padding: 0)
                .padding(.top, 16)
                .reveal(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { dropped = true }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: dropped)
    }

    private func reminderRow(title: String, symbol: String, isOn: Binding<Bool>, time: Binding<Date>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.allo(.callout, .medium))
                .foregroundStyle(isOn.wrappedValue ? accent : Color.inkTertiary)
                .frame(width: 22)
            Text(title).font(.allo(.callout, .medium)).foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!isOn.wrappedValue)
                .opacity(isOn.wrappedValue ? 1 : 0.35)
            Toggle(title, isOn: isOn.animation(.smooth))
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// What the morning notification will look like.
private struct NotificationPreview: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OwlMark(size: 22, blinks: false)
                .frame(width: 38, height: 38)
                .background(Color(hex: 0x0B0B0D), in: .rect(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Color.hairline))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Sova").font(.allo(.footnote, .semibold)).foregroundStyle(Color.inkSecondary)
                    Spacer()
                    Text("now").font(.allo(.footnote)).foregroundStyle(Color.inkTertiary)
                }
                Text("Good morning").font(.allo(.subheadline, .semibold)).foregroundStyle(Color.ink)
                Text("Your day is ready. Take a minute to plan it.")
                    .font(.allo(.subheadline))
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example notification: Good morning. Your day is ready. Take a minute to plan it.")
    }
}

// MARK: - 7. Accent

struct ThemeStep: View {
    @Binding var themeRaw: String
    var name: String
    var rituals: [RitualOption]
    var goalTitle: String

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .lime }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepHeadline(text: String(localized: "Choose an accent"))
                StepBody(text: String(localized: "This is how your first day will look."))
                    .padding(.top, 10)

                YourDayPreview(accent: theme.accent.color, name: name, rituals: rituals, goalTitle: goalTitle)
                    .padding(.top, 26)
                    .reveal(2)

                ThemeSwatches(themeRaw: $themeRaw)
                    .padding(.top, 22)
                    .reveal(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }
}

/// The user's real first day, built from their choices.
private struct YourDayPreview: View {
    var accent: Color
    var name: String
    var rituals: [RitualOption]
    var goalTitle: String

    var body: some View {
        let total = rituals.count
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()), size: 10)
            HStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    Text("0").foregroundStyle(Color.ink)
                    Text("/\(total)").foregroundStyle(Color.ink.opacity(0.2))
                }
                .font(.hero(52))
                .tracking(-2.4)
                Spacer()
                Text(name.isEmpty ? String(localized: "Day one") : String(localized: "Day one, \(name)"))
                    .font(.allo(.footnote))
                    .foregroundStyle(Color.inkTertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 8)
            DaySegments(done: 0, total: max(total, 1), color: accent)
                .padding(.top, 10)

            if rituals.isEmpty && goalTitle.isEmpty {
                Text("Your tasks and rituals will line up here.")
                    .font(.allo(.subheadline))
                    .foregroundStyle(Color.inkTertiary)
                    .padding(.top, 16)
            }
            ForEach(Array(rituals.prefix(3).enumerated()), id: \.element.id) { index, ritual in
                HStack(spacing: 12) {
                    Checkbox(isOn: false, color: accent, round: true, size: 20, emphasized: index == 0)
                    Text(ritual.title).font(.allo(.subheadline, .medium)).foregroundStyle(Color.ink)
                    Spacer()
                    MonoCaps(ritual.period.name, size: 9.5)
                }
                .padding(.top, index == 0 ? 16 : 12)
            }
            if !goalTitle.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(goalTitle).font(.allo(.subheadline, .medium)).foregroundStyle(Color.ink)
                        Spacer()
                        Text("0%").font(.mono(11)).foregroundStyle(Color.inkTertiary)
                    }
                    ProgressLine(progress: 0.02, color: accent, height: 3)
                }
                .padding(.top, 18)
            }
        }
        .surface(cornerRadius: 22, padding: 18)
        .animation(.smooth(duration: 0.5), value: accent)
    }
}

// MARK: - 8. Finish

struct FinishStep: View {
    var name: String
    var ritualCount: Int
    var goalTitle: String
    var remindersOn: Bool
    var theme: SovaTheme
    @State private var hop = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                OwlMark(size: 112, happy: true, blinks: false)
                    .keyframeAnimator(initialValue: 0.0, trigger: hop) { view, y in
                        view.offset(y: y)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(-22, duration: 0.22)
                            SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .reveal(0)

            Text(name.isEmpty ? String(localized: "You're all set.") : String(localized: "You're all set, \(name)."))
                .font(.hero(size, weight: .bold))
                .tracking(-2)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(1)

            VStack(alignment: .leading, spacing: 0) {
                summaryRow(String(localized: "Rituals"), ritualCount == 0 ? String(localized: "None yet") : "\(ritualCount)")
                summaryRow(String(localized: "Goal"), goalTitle.isEmpty ? String(localized: "None yet") : goalTitle)
                summaryRow(String(localized: "Reminders"), remindersOn ? String(localized: "On") : String(localized: "Off"))
                summaryRow(String(localized: "Accent"), theme.name, swatch: theme.accent.color, last: true)
            }
            .padding(.top, 22)
            .padding(.bottom, 20)
            .reveal(2)
        }
        .padding(.horizontal, 28)
        .sensoryFeedback(.success, trigger: hop)
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            hop += 1
        }
    }

    private func summaryRow(_ label: String, _ value: String, swatch: Color? = nil, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                MonoCaps(label, size: 10.5)
                Spacer()
                if let swatch { Circle().fill(swatch).frame(width: 8, height: 8) }
                Text(value)
                    .font(.allo(.subheadline, .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
            }
            .padding(.vertical, 11)
            if !last { Rectangle().fill(Color.hairline).frame(height: 1) }
        }
    }
}
