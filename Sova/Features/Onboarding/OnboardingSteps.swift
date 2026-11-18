import SwiftUI

// Each step: a big, tight, left-aligned headline, one quiet supporting
// line, and a single interactive idea. Lime only marks what's chosen.

private struct StepHeadline: View {
    let text: String
    var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 44

    var body: some View {
        Text(text)
            .font(.hero(size, weight: .heavy))
            .tracking(-2)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reveal(index)
    }
}

private struct StepBody: View {
    let text: String
    var index = 1

    var body: some View {
        Text(text)
            .font(.allo(size: 17, weight: .bold, relativeTo: .body))
            .foregroundStyle(Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reveal(index)
    }
}

private var accent: Color { SovaTheme.current.accent.color }

// MARK: - 1. Welcome

struct HelloStep: View {
    var look: CGSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 92

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WelcomeBlocks(look: look)
                .padding(.top, 6)

            Spacer(minLength: 20)

            Text("Sova.")
                .font(.hero(titleSize, weight: .heavy))
                .tracking(-4.5)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .reveal(7)
            Text("Your day, your rituals, your goals.\nPlanned in a minute.")
                .font(.allo(size: 20, weight: .bold, relativeTo: .title3))
                .tracking(-0.3)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 8)
                .padding(.bottom, 22)
                .reveal(8)
        }
        .padding(.horizontal, 20)
    }
}

/// A taste of the app, as blocks that pop in one by one.
private struct WelcomeBlocks: View {
    var look: CGSize

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    MonoCaps(String(localized: "Today"), color: StickerTone.yellow.deep)
                    Text("3/8")
                        .font(.hero(56, weight: .heavy))
                        .tracking(-2.4)
                    Spacer(minLength: 0)
                    DaySegments(done: 3, total: 8, color: StickerTone.yellow.deep, height: 8)
                }
                .foregroundStyle(StickerTone.yellow.deep)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
                .background(StickerTone.yellow.fill, in: .rect(cornerRadius: 28, style: .continuous))
                .pop(0)

                VStack(spacing: 8) {
                    Label("Meditate", systemImage: "checkmark")
                        .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                        .foregroundStyle(StickerTone.mint.deep)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .background(StickerTone.mint.fill, in: .rect(cornerRadius: 28, style: .continuous))
                        .pop(1)
                    VStack(alignment: .leading, spacing: 2) {
                        MonoCaps(String(localized: "Goal"), color: StickerTone.pink.deep, size: 10)
                        Text("Read 12 books")
                            .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(StickerTone.pink.deep)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .background(StickerTone.pink.fill, in: .rect(cornerRadius: 28, style: .continuous))
                    .pop(2)
                }
            }
            .frame(height: 150)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    MonoCaps(String(localized: "Up next"), color: StickerTone.indigo.deep)
                    Text("Call Mom\nat 6 PM")
                        .font(.allo(size: 24, weight: .heavy, relativeTo: .title2))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                Spacer()
                OwlMark(size: 76, look: look, bodyColor: Color.canvas,
                        eyeColor: StickerTone.indigo.fill)
            }
            .padding(18)
            .frame(height: 150)
            .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 28, style: .continuous))
            .pop(3)

            HStack(spacing: 8) {
                pill(String(localized: "Rituals"), .lilac).pop(4)
                pill(String(localized: "12 days"), .orange).pop(5)
                pill(String(localized: "Goals"), .cyan).pop(6)
            }
        }
        .accessibilityHidden(true)
    }

    private func pill(_ text: String, _ tone: StickerTone) -> some View {
        Text(text)
            .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
            .foregroundStyle(tone.deep)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(tone.fill, in: .capsule)
    }
}

/// Springs a block in from slightly smaller, a beat after the one before.
private struct Pop: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown || reduceMotion ? 1 : 0.85)
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.08 + Double(index) * 0.06)) {
                    shown = true
                }
            }
    }
}

private extension View {
    func pop(_ index: Int) -> some View { modifier(Pop(index: index)) }
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

                    PillarCard(label: String(localized: "Rituals"), tone: .mint) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Morning pages").font(.allo(size: 18, weight: .heavy, relativeTo: .headline)).foregroundStyle(StickerTone.mint.deep)
                                Spacer()
                                Text("\(streakDays)d streak")
                                    .font(.mono(11.5))
                                    .foregroundStyle(Color.inkTertiary)
                                    .contentTransition(.numericText())
                            }
                            HStack(spacing: 5) {
                                ForEach(0..<7, id: \.self) { day in
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(day < streakDays ? StickerTone.mint.deep : StickerTone.mint.deep.opacity(0.15))
                                        .frame(height: 20)
                                }
                            }
                        }
                    }
                    .reveal(3)

                    PillarCard(label: String(localized: "Goals"), tone: .pink) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Run a half marathon").font(.allo(size: 18, weight: .heavy, relativeTo: .headline)).foregroundStyle(StickerTone.pink.deep)
                                Spacer()
                                Text(goalProgress, format: .percent.precision(.fractionLength(0)))
                                    .font(.hero(26, weight: .heavy))
                                    .foregroundStyle(StickerTone.pink.deep)
                                    .contentTransition(.numericText(value: goalProgress))
                            }
                            StepBar(progress: goalProgress, steps: [goalProgress > 0.1, goalProgress > 0.3, false, false], color: StickerTone.pink.deep)
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
    var tone: StickerTone? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MonoCaps(label, color: tone?.deep ?? .inkSecondary)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone?.fill ?? Color.white, in: .rect(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.hairline, lineWidth: tone == nil ? 1.5 : 0))
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
            .font(.hero(size, weight: .heavy))
            .tracking(-0.6)
            .foregroundStyle(Color.ink)
            .tint(StickerTone.indigo.fill)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.white, in: .rect(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(focused ? StickerTone.indigo.fill : Color.hairline, lineWidth: focused ? 2.5 : 1.5)
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
                StepHeadline(text: String(localized: "Pick your\nrituals."))
                StepBody(text: String(localized: "Small things you want to do regularly."))
                    .padding(.top, 10)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(RitualOption.all.enumerated()), id: \.element.id) { index, ritual in
                        RitualTile(ritual: ritual, selected: selection.contains(ritual.id)) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                if selection.contains(ritual.id) { selection.remove(ritual.id) }
                                else { selection.insert(ritual.id) }
                            }
                        }
                        .reveal(2 + index / 2)
                    }
                }
                .padding(.top, 22)
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

/// A ritual tile: white with a colored dot until chosen, then a full block
/// of its color.
private struct RitualTile: View {
    let ritual: RitualOption
    let selected: Bool
    let action: () -> Void

    private var tone: StickerTone { StickerTone(ritual.accent) }
    private var ink: Color { tone == .indigo ? .white : tone.deep }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: ritual.symbol)
                        .font(.system(size: selected ? 24 : 19, weight: .semibold))
                        .foregroundStyle(selected ? ink : ink)
                        .frame(width: 40, height: 40)
                        .background(selected ? Color.clear : tone.fill, in: .circle)
                        .padding(selected ? -8 : 0)
                    Spacer()
                    ZStack {
                        Circle()
                            .strokeBorder(Color.ink.opacity(0.15), lineWidth: 2.5)
                            .opacity(selected ? 0 : 1)
                        Circle()
                            .fill(tone.deep)
                            .scaleEffect(selected ? 1 : 0.3)
                            .opacity(selected ? 1 : 0)
                        CheckmarkShape()
                            .trim(from: 0, to: selected ? 1 : 0)
                            .stroke(tone.fill, style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))
                            .padding(7.5)
                    }
                    .frame(width: 28, height: 28)
                }
                Spacer(minLength: 16)
                Text(ritual.title)
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                    .foregroundStyle(selected ? ink : Color.ink)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background(selected ? tone.fill : Color.white, in: .rect(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.ink.opacity(0.08), lineWidth: 1.5)
                    .opacity(selected ? 0 : 1)
            }
        }
        .buttonStyle(.pressable)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
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
                                    .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                            }
                            .foregroundStyle(selected ? StickerTone.indigo.deep : suggestion.tone.deep)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(selected ? StickerTone.indigo.fill : suggestion.tone.fill, in: .capsule)
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

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }

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
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                OwlMark(size: 96, happy: true, blinks: false, bodyColor: Color.canvas, eyeColor: StickerTone.indigo.fill)
                    .keyframeAnimator(initialValue: 0.0, trigger: hop) { view, y in
                        view.offset(y: y)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(-18, duration: 0.22)
                            SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 30, style: .continuous))
                VStack(spacing: 8) {
                    summary(ritualCount == 0 ? String(localized: "No rituals") :
                            ritualCount == 1 ? String(localized: "1 ritual") : String(localized: "\(ritualCount) rituals"),
                            label: String(localized: "Set up"), tone: .mint)
                    summary(remindersOn ? String(localized: "On") : String(localized: "Off"),
                            label: String(localized: "Reminders"), tone: .yellow)
                }
            }
            .frame(height: 176)
            .padding(.top, 10)
            .reveal(0)

            if !goalTitle.isEmpty {
                summary(goalTitle, label: String(localized: "Your goal · 90 days"), tone: .pink)
                    .frame(height: 84)
                    .reveal(1)
            }

            Spacer(minLength: 16)

            Text(name.isEmpty ? String(localized: "You're all set.") : String(localized: "You're all set,\n\(name)."))
                .font(.hero(size, weight: .heavy))
                .tracking(-2.4)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(2)
            Text("Your first day starts now.")
                .font(.allo(size: 20, weight: .bold, relativeTo: .title3))
                .foregroundStyle(Color.inkSecondary)
                .padding(.bottom, 20)
                .reveal(3)
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.success, trigger: hop)
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            hop += 1
        }
    }

    private func summary(_ value: String, label: String, tone: StickerTone) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            MonoCaps(label, color: tone.deep, size: 10)
            Text(value)
                .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                .tracking(-0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(tone.deep)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .background(tone.fill, in: .rect(cornerRadius: 30, style: .continuous))
    }
}
