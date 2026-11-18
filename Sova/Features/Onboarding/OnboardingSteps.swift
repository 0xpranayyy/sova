import SwiftUI




private struct StepHeadline: View {
    let text: String
    var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 34

    var body: some View {
        Text(text.replacingOccurrences(of: "\n", with: " "))
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .reveal(index)
    }
}

private struct StepBody: View {
    let text: String
    var index = 1

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Color.inkSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .reveal(index)
    }
}

// MARK: - 1. Hello

struct HelloStep: View {
    var look: CGSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 40

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                OwlMark(size: 96, look: look)
                    .padding(26)
                    .glassEffect(.regular, in: .circle)
                    .padding(.top, 24)
                    .reveal(0)

                VStack(spacing: 6) {
                    Text("Welcome to")
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundStyle(Color.ink)
                    Text("Sova")
                        .font(.system(size: titleSize, weight: .heavy))
                        .foregroundStyle(SovaTheme.ember.swatch)
                }
                .padding(.top, 28)
                .reveal(1)

                VStack(alignment: .leading, spacing: 22) {
                    feature("checklist", .ember, "Tasks for today",
                            "Capture anything in plain words. Swipe it done.")
                        .reveal(2)
                    feature("repeat", .lagoon, "Routines for always",
                            "Small rituals, with streaks that keep you going.")
                        .reveal(3)
                    feature("flag.checkered", .plum, "Goals for someday",
                            "Big ambitions, broken into finishable steps.")
                        .reveal(4)
                }
                .padding(.top, 40)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    private func feature(_ symbol: String, _ accent: Accent, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(accent.gradient)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Color.ink)
                Text(detail).font(.subheadline).foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 2. Pillars

struct PillarsStep: View {
    @State private var taskDone = false
    @State private var streakDays = 0
    @State private var goalProgress = 0.0
    @State private var settled = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                StepHeadline(text: String(localized: "Three kinds\nof intention."))
                    .padding(.top, 8)

                VStack(spacing: -8) {
                    PillarCard(label: String(localized: "Today"), accent: .ember, rotation: -2.2, settled: settled) {
                        HStack(spacing: 6) {
                            CheckButton(isOn: taskDone, color: Accent.ember.color, label: "Send the proposal") {
                                withAnimation(.snappy) { taskDone.toggle() }
                            }
                            .padding(.leading, -11)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Send the proposal")
                                    .font(.body.weight(.medium))
                                    .strikethrough(taskDone, color: Color.inkTertiary)
                                    .foregroundStyle(taskDone ? Color.inkSecondary : Color.ink)
                                Text("10:00 AM").font(.footnote).foregroundStyle(Color.inkSecondary)
                            }
                            Spacer()
                            if !taskDone {
                                Text("Try it")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Accent.ember.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Accent.ember.soft, in: .capsule)
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }
                    }
                    .zIndex(3)
                    .reveal(1)

                    PillarCard(label: String(localized: "Always"), accent: .lagoon, rotation: 1.6, offsetX: 10, settled: settled) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Morning pages").font(.body.weight(.medium)).foregroundStyle(Color.ink)
                                Spacer()
                                Text("\(streakDays) day streak")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(Color.inkSecondary)
                                    .contentTransition(.numericText())
                            }
                            HStack(spacing: 6) {
                                ForEach(0..<7, id: \.self) { day in
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(day < streakDays ? Accent.lagoon.color : Color.well)
                                        .frame(height: 22)
                                }
                            }
                        }
                    }
                    .zIndex(2)
                    .reveal(2)

                    PillarCard(label: String(localized: "Someday"), accent: .plum, rotation: -1.1, offsetX: -6, settled: settled) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Run a half marathon").font(.body.weight(.medium)).foregroundStyle(Color.ink)
                                Spacer()
                                Text(goalProgress, format: .percent.precision(.fractionLength(0)))
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(Color.inkSecondary)
                                    .contentTransition(.numericText(value: goalProgress))
                            }
                            ProgressLine(progress: goalProgress, color: Accent.plum.color, height: 6)
                        }
                    }
                    .zIndex(1)
                    .reveal(3)
                }

                Text("**Tasks** are for today. **Routines** are for always. **Goals** are for someday.")
                    .font(.body)
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .reveal(4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .task { await play() }
    }

    private func play() async {
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.25)) { settled = true }
        if reduceMotion {
            streakDays = 5; goalProgress = 0.62
            return
        }
        try? await Task.sleep(for: .milliseconds(650))
        withAnimation(.spring(response: 1.1, dampingFraction: 0.9)) { goalProgress = 0.62 }
        for day in 1...5 {
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { streakDays = day }
        }
    }
}

private struct PillarCard<Content: View>: View {
    let label: String
    let accent: Accent
    var rotation: Double
    var offsetX: CGFloat = 0
    var settled: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle().fill(accent.color).frame(width: 7, height: 7)
                Text(label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accent.color)
            }
            content
        }
        .surface(cornerRadius: 24, padding: 18, tint: accent.color)
        .rotationEffect(.degrees(settled ? rotation : 0))
        .offset(x: settled ? offsetX : 0)
    }
}

// MARK: - 3. Name

/// A large text field on a Liquid Glass capsule that lights up on focus.
struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var autofocus = true
    var onSubmit: () -> Void
    @FocusState private var focused: Bool
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.inkTertiary), axis: .vertical)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .lineLimit(1...3)
                .textContentType(contentType)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.continue)
                .focused($focused)
                .onChange(of: text) { _, newValue in
                    // A vertical field inserts newlines; treat Return as submit.
                    if newValue.contains("\n") {
                        text = newValue.replacingOccurrences(of: "\n", with: "")
                        onSubmit()
                    }
                }

        }
        .padding(.horizontal, 20)
        .frame(minHeight: 64)
        .glassEffect(Glass.card(tint: focused ? Color.accentColor : nil, interactive: true),
                     in: .rect(cornerRadius: 22, style: .continuous))
        .animation(.smooth(duration: 0.3), value: focused)
        .task {
            guard autofocus else { return }
            try? await Task.sleep(for: .milliseconds(550))
            focused = true
        }
    }
}

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
        VStack(alignment: .leading, spacing: 28) {
            StepHeadline(text: String(localized: "What should\nwe call you?"))
                .padding(.top, 8)

            GlassField(placeholder: String(localized: "Your name"), text: $name,
                       contentType: .givenName, onSubmit: onSubmit)
                .reveal(1)

            Group {
                if trimmed.isEmpty {
                    Text("Just for your greeting. It never leaves this device.")
                } else {
                    Text("\(greeting), \(Text(trimmed).foregroundStyle(Color.ink)).")
                }
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.inkSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .contentTransition(.opacity)
            .animation(.smooth(duration: 0.3), value: trimmed.isEmpty)
            .reveal(2)

            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - 4. Rituals

struct RitualsStep: View {
    @Binding var selection: Set<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    StepHeadline(text: String(localized: "Pick a few\nrituals."))
                    StepBody(text: String(localized: "Small things, done often. You can change these anytime."))
                }
                .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(RitualOption.all.enumerated()), id: \.element.id) { index, ritual in
                        RitualTile(ritual: ritual, selected: selection.contains(ritual.id)) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                if selection.contains(ritual.id) { selection.remove(ritual.id) }
                                else { selection.insert(ritual.id) }
                            }
                        }
                        .reveal(2 + index / 2)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct RitualTile: View {
    let ritual: RitualOption
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: ritual.symbol)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(selected ? Color.white : ritual.accent.color)
                    Spacer()
                    ZStack {
                        Circle()
                            .strokeBorder(Color.inkTertiary, lineWidth: 1.5)
                            .opacity(selected ? 0 : 1)
                        Circle()
                            .fill(Color.white)
                            .scaleEffect(selected ? 1 : 0.3)
                            .opacity(selected ? 1 : 0)
                        CheckmarkShape()
                            .trim(from: 0, to: selected ? 1 : 0)
                            .stroke(ritual.accent.color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .padding(6)
                    }
                    .frame(width: 22, height: 22)
                }
                Spacer(minLength: 20)
                Text(ritual.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selected ? Color.white : Color.ink)
                    .multilineTextAlignment(.leading)
                Text(ritual.period.name)
                    .font(.caption)
                    .foregroundStyle(selected ? Color.white.opacity(0.75) : Color.inkSecondary)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ritual.accent.gradient)
                    .opacity(selected ? 1 : 0)
            }
            .glassEffect(Glass.card(tint: selected ? ritual.accent.color : nil, interactive: true),
                         in: .rect(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(ritual.title)
        .accessibilityValue(ritual.period.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - 5. Goal

struct GoalStep: View {
    @Binding var title: String
    var onSubmit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 12) {
                    StepHeadline(text: String(localized: "One thing for\nthis season."))
                    StepBody(text: String(localized: "Something you’d be proud of in three months. Pick one or write your own."))
                }
                .padding(.top, 8)

                GlassField(placeholder: String(localized: "My goal is to…"), text: $title,
                           autofocus: false, onSubmit: onSubmit)
                    .reveal(2)

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
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(selected ? Color.white : suggestion.accent.color)
                                Text(suggestion.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(selected ? Color.white : Color.ink)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .background { Capsule().fill(suggestion.accent.gradient).opacity(selected ? 1 : 0) }
                            .glassEffect(Glass.card(tint: selected ? suggestion.accent.color : nil, interactive: true),
                                         in: .capsule)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .reveal(3)

                Label("We’ll give it 90 days. You can change that anytime.", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
                    .reveal(4)
            }
            .padding(.horizontal, 28)
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

// MARK: - 6. Rhythm (reminders)

struct RhythmStep: View {
    var name: String
    @Binding var morningOn: Bool
    @Binding var morning: Date
    @Binding var eveningOn: Bool
    @Binding var evening: Date

    @State private var dropped = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 12) {
                    StepHeadline(text: String(localized: "A gentle nudge,\ntwice a day."))
                    StepBody(text: String(localized: "A note to plan in the morning, and one to look back at night. Nothing else, ever."))
                }
                .padding(.top, 8)

                NotificationPreview(name: name)
                    .offset(y: dropped ? 0 : -24)
                    .opacity(dropped ? 1 : 0)
                    .scaleEffect(dropped ? 1 : 0.96)

                VStack(spacing: 0) {
                    reminderRow(title: String(localized: "Morning plan"), symbol: "sun.max", accent: .marigold,
                                isOn: $morningOn, time: $morning)
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 64)
                    reminderRow(title: String(localized: "Evening review"), symbol: "moon", accent: .plum,
                                isOn: $eveningOn, time: $evening)
                }
                .surface(cornerRadius: 22, padding: 0)
                .reveal(3)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) { dropped = true }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: dropped)
    }

    private func reminderRow(title: String, symbol: String, accent: Accent,
                             isOn: Binding<Bool>, time: Binding<Date>) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: symbol, accent: accent, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(Color.ink)
                DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .scaleEffect(0.92, anchor: .leading)
                    .disabled(!isOn.wrappedValue)
                    .opacity(isOn.wrappedValue ? 1 : 0.35)
            }
            Spacer(minLength: 0)
            Toggle(title, isOn: isOn.animation(.smooth))
                .labelsHidden()
                .tint(accent.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

/// What the morning notification will actually look like.
private struct NotificationPreview: View {
    var name: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OwlMark(size: 22, blinks: false)
                .frame(width: 38, height: 38)
                .background(Color.canvas, in: .rect(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Sova").font(.footnote.weight(.semibold)).foregroundStyle(Color.inkSecondary)
                    Spacer()
                    Text("now").font(.footnote).foregroundStyle(Color.inkSecondary)
                }
                Text("Good morning")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text("Your day is ready. Take a minute to plan it.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example notification: Good morning. Your day is ready. Take a minute to plan it.")
    }
}

// MARK: - 7. Theme

struct ThemeStep: View {
    @Binding var themeRaw: String
    var name: String
    var rituals: [RitualOption]
    var goalTitle: String

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    StepHeadline(text: String(localized: "Make it\nyours."))
                    StepBody(text: String(localized: "One color, used with restraint. Here’s your day so far."))
                }
                .padding(.top, 8)

                YourDayPreview(accent: theme.accent, name: name, rituals: rituals, goalTitle: goalTitle)
                    .reveal(2)

                ThemeSwatches(themeRaw: $themeRaw)
                    .reveal(3)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }
}

/// The user's real first day, built from their choices so far. It
/// recolors live as they try themes.
private struct YourDayPreview: View {
    var accent: Accent
    var name: String
    var rituals: [RitualOption]
    var goalTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(.display(.title2))
                    .foregroundStyle(Color.ink)
                Text(name.isEmpty ? String(localized: "Your first day in Sova.") : String(localized: "Your first day, \(name)."))
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
            }
            DaySegments(done: 0, total: max(rituals.count, 1), color: accent.color)

            if rituals.isEmpty && goalTitle.isEmpty {
                Text("Your tasks and routines will live here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rituals.prefix(3).enumerated()), id: \.element.id) { index, ritual in
                        if index > 0 { Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 34) }
                        HStack(spacing: 12) {
                            Checkbox(isOn: false, color: accent.color, round: true, size: 20)
                            Text(ritual.title).font(.subheadline.weight(.medium)).foregroundStyle(Color.ink)
                            Spacer()
                            Text(ritual.period.name).font(.caption).foregroundStyle(Color.inkSecondary)
                        }
                        .padding(.vertical, 10)
                    }
                    if rituals.count > 3 {
                        Text("and \(rituals.count - 3) more")
                            .font(.caption)
                            .foregroundStyle(Color.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 32)
                            .padding(.bottom, 4)
                    }
                }
                if !goalTitle.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goalTitle).font(.subheadline.weight(.medium)).foregroundStyle(Color.ink)
                            Spacer()
                            Text("90 days").font(.caption).foregroundStyle(Color.inkSecondary)
                        }
                        ProgressLine(progress: 0, color: accent.color)
                    }
                    .padding(12)
                    .background(accent.soft, in: .rect(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .surface(cornerRadius: 24, padding: 18)
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
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            OwlMark(size: 96, happy: true, blinks: false)
                .padding(26)
                .glassEffect(Glass.card(tint: theme.accent.color), in: .circle)
                .keyframeAnimator(initialValue: 0.0, trigger: hop) { view, y in
                    view.offset(y: y)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(-22, duration: 0.22)
                        SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                    }
                }
                .reveal(0)
            Spacer().frame(height: 44)
            Text(name.isEmpty ? String(localized: "You’re all set.") : String(localized: "You’re all set,\n\(name)."))
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(1)
            Text("Here’s to good days, and the small things that make them.")
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 14)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(2)

            FlowLayout(spacing: 8) {
                if ritualCount > 0 {
                    summaryChip(ritualCount == 1 ? String(localized: "1 ritual") : String(localized: "\(ritualCount) rituals"),
                                color: Accent.lagoon.color)
                }
                if !goalTitle.isEmpty {
                    summaryChip(goalTitle, color: Accent.plum.color)
                }
                if remindersOn {
                    summaryChip(String(localized: "Reminders on"), color: Accent.marigold.color)
                }
                summaryChip(String(localized: "\(theme.name) theme"), color: theme.accent.color)
            }
            .padding(.top, 24)
            .reveal(3)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.success, trigger: hop)
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            hop += 1
        }
    }

    private func summaryChip(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.footnote.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }
}
