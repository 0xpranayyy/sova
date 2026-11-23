import SwiftUI

// Onboarding: big heavy headlines, Allo's colors as blocks and stickers,
// and the owl as a character who greets you, asks your name and celebrates.

private struct StepHeadline: View {
    /// The headline; wrap one phrase in `*stars*` for the highlighter.
    let text: String
    var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 42

    var body: some View {
        Text.marked(text)
            .font(.hero(size, weight: .heavy))
            .tracking(-2)
            .foregroundStyle(Color.ink)
            .textRenderer(MarkerRenderer(color: StickerTone.yellow.fill))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
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

private var accent: Color { StickerTone.indigo.fill }

/// Springs a view in from slightly smaller, a beat after the one before.
private struct Pop: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown || reduceMotion ? 1 : 0.6)
            .opacity(shown ? 1 : 0)
            .onAppear {
                let delay = 0.15 + Double(index) * 0.07
                withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(delay)) {
                    shown = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(Int((delay + 0.08) * 1000)))
                    Haptics.pop(0.35 + Double(index % 3) * 0.08, sound: true)
                }
            }
    }
}

private extension View {
    func pop(_ index: Int) -> some View { modifier(Pop(index: index)) }
}

// MARK: - 1. Welcome

struct HelloStep: View {
    var look: CGSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 54

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OwlFace(look: look)
                .frame(maxHeight: 440)
                .padding(.top, 4)
                .shadow(color: StickerTone.yellow.shadow, radius: 18, y: 10)
                .reveal(0)

            Text("Hi\(Text(".").foregroundStyle(StickerTone.pink.fill)) I'm Sova.")
                .font(.hero(titleSize, weight: .heavy))
                .tracking(-2.4)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 26)
                .padding(.horizontal, 8)
                .reveal(2)
            Text("I'll help you plan your day, keep your rituals and reach your goals.")
                .font(.allo(size: 18, weight: .bold, relativeTo: .title3))
                .tracking(-0.3)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 18)
                .reveal(3)
        }
        .padding(.horizontal, 16)
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
                StepHeadline(text: String(localized: "Three kinds\nof *things*."))
                StepBody(text: String(localized: "Tap the task to tick it off."))
                    .padding(.top, 10)
                VStack(spacing: 12) {
                    taskCard.reveal(2)
                    ritualCard.reveal(3)
                    goalCard.reveal(4)
                }
                .padding(.top, 26)
            }
            .readableColumn()
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .task { await play() }
    }

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoCaps(String(localized: "Task · 10:00"), color: Color.ink.opacity(0.55))
            HStack(spacing: 12) {
                CheckButton(isOn: taskDone, label: String(localized: "Send the proposal")) {
                    withAnimation(.snappy) { taskDone.toggle() }
                }
                .padding(.leading, -11)
                Text("Send the proposal")
                    .font(.allo(size: 19, weight: .heavy, relativeTo: .headline))
                    .strikethrough(taskDone, color: Color.inkTertiary)
                    .foregroundStyle(taskDone ? Color.inkTertiary : Color.ink)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var ritualCard: some View {
        let tone = StickerTone.mint
        return VStack(alignment: .leading, spacing: 8) {
            MonoCaps(String(localized: "Ritual · every morning"), color: tone.deep.opacity(0.7))
            HStack {
                Text("Morning pages").font(.allo(size: 19, weight: .heavy, relativeTo: .headline))
                Spacer()
                Text("🔥 \(streakDays)")
                    .font(.allo(size: 14, weight: .heavy, relativeTo: .footnote))
                    .contentTransition(.numericText())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.45), in: .capsule)
            }
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(day < streakDays ? tone.deep : tone.deep.opacity(0.16))
                        .frame(height: 14)
                }
            }
            .padding(.top, 4)
        }
        .foregroundStyle(tone.deep)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(tone.fill, in: .rect(cornerRadius: Radius.card, style: .continuous))
    }

    private var goalCard: some View {
        let tone = StickerTone.pink
        return VStack(alignment: .leading, spacing: 6) {
            MonoCaps(String(localized: "Goal · 90 days"), color: tone.deep.opacity(0.7))
            HStack(alignment: .firstTextBaseline) {
                Text("Run a half marathon").font(.allo(size: 19, weight: .heavy, relativeTo: .headline))
                Spacer()
                Text(goalProgress, format: .percent.precision(.fractionLength(0)))
                    .font(.hero(32, weight: .heavy))
                    .tracking(-1.2)
                    .contentTransition(.numericText(value: goalProgress))
            }
            StepBar(progress: goalProgress, steps: [goalProgress > 0.1, goalProgress > 0.3, false, false], color: tone.deep)
        }
        .foregroundStyle(tone.deep)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(tone.fill, in: .rect(cornerRadius: Radius.card, style: .continuous))
    }

    private func play() async {
        if reduceMotion { streakDays = 5; goalProgress = 0.5; return }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.spring(response: 1.1, dampingFraction: 0.9)) { goalProgress = 0.5 }
        for day in 1...5 {
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { streakDays = day }
        }
    }
}

// MARK: - Shared field

/// A big white field with a soft ring that turns indigo on focus.
struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var autofocus = true
    var onSubmit: () -> Void
    @FocusState private var focused: Bool
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 28

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.inkTertiary), axis: .vertical)
            .font(.hero(size, weight: .heavy))
            .tracking(-0.8)
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
            .padding(22)
            .background(Color.surface, in: .rect(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(focused ? accent : Color.hairline, lineWidth: focused ? 2.5 : 1.5)
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
            StepHeadline(text: String(localized: "What should\nI *call you*?"))
            StepBody(text: String(localized: "Just for your greeting. It stays on this iPhone."))
                .padding(.top, 10)
            BigField(placeholder: String(localized: "Your name"), text: $name,
                     contentType: .givenName, onSubmit: onSubmit)
                .padding(.top, 30)
                .reveal(2)
            preview
                .padding(.top, 28)
                .reveal(3)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    /// The top of their Today, greeting them by name as they type.
    private var preview: some View {
        let line: String = trimmed.isEmpty ? greeting : "\(greeting),\n\(trimmed)"
        return VStack(alignment: .leading, spacing: 0) {
            MonoCaps(String(localized: "Your Today"), color: Color.ink.opacity(0.55))
            Text("\(line)\(Text(".").foregroundStyle(StickerTone.pink.fill))")
                .font(.hero(30, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(Color.ink)
                .contentTransition(.opacity)
                .animation(.smooth(duration: 0.25), value: trimmed)
                .padding(.top, 8)
            HStack(spacing: 6) {
                Capsule().fill(StickerTone.indigo.fill).frame(width: 90, height: 8)
                Capsule().fill(Color.ink.opacity(0.07)).frame(height: 8)
            }
            .padding(.top, 14)
            Text("3 of 8 done")
                .font(.allo(size: 13, weight: .bold, relativeTo: .caption))
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 4. Rituals

struct RitualsStep: View {
    @Binding var selection: Set<String>
    @State private var limitNudge = 0

    private var atLimit: Bool { selection.count >= PlusGate.starterRituals }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StepHeadline(text: String(localized: "Pick your\n*rituals*."))
                Text("Start with up to \(PlusGate.starterRituals). Add more anytime.")
                    .font(.allo(size: 17, weight: .bold, relativeTo: .body))
                    .foregroundStyle(atLimit ? Color.ink : Color.inkSecondary)
                    .padding(.top, 10)
                    .modifier(Shake(trigger: limitNudge))
                    .reveal(1)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(RitualOption.all.enumerated()), id: \.element.id) { index, ritual in
                        RitualTile(ritual: ritual, selected: selection.contains(ritual.id),
                                   tilt: index.isMultiple(of: 2) ? -1.5 : 1.5) { toggle(ritual) }
                            .reveal(2 + index / 2)
                    }
                }
                .padding(.top, 24)
            }
            .readableColumn()
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .sovaFeedback(.selection, trigger: selection)
    }

    private func toggle(_ ritual: RitualOption) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            if selection.contains(ritual.id) {
                selection.remove(ritual.id)
            } else if atLimit {
                limitNudge += 1
                Haptics.warning()
            } else {
                selection.insert(ritual.id)
            }
        }
    }
}

/// A little side-to-side shake when `trigger` changes.
private struct Shake: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: Double(0), trigger: trigger) { view, x in
            view.offset(x: CGFloat(x))
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(Double(-8), duration: 0.07)
                SpringKeyframe(Double(7), duration: 0.07)
                SpringKeyframe(Double(-4), duration: 0.07)
                SpringKeyframe(Double(0), duration: 0.2)
            }
        }
    }
}

/// A ritual tile: white with a colored dot until chosen, then a full,
/// slightly tilted block of its color.
private struct RitualTile: View {
    let ritual: RitualOption
    let selected: Bool
    var tilt: Double = 0
    let action: () -> Void

    private var tone: StickerTone { StickerTone(ritual.accent) }
    private var ink: Color { tone == .indigo ? .white : tone.deep }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: ritual.symbol)
                        .font(.system(size: selected ? 25 : 19, weight: .semibold))
                        .foregroundStyle(ink)
                        .frame(width: 42, height: 42)
                        .background(selected ? Color.white.opacity(0.4) : tone.fill,
                                    in: .rect(cornerRadius: 14, style: .continuous))
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
                            .stroke(tone.fill, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .padding(8)
                    }
                    .frame(width: 30, height: 30)
                }
                Spacer(minLength: 14)
                Text(ritual.title)
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                    .foregroundStyle(selected ? ink : Color.ink)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(selected ? tone.fill : Color.surface, in: .rect(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.ink.opacity(0.08), lineWidth: 1.5)
                    .opacity(selected ? 0 : 1)
            }
            .rotationEffect(.degrees(selected ? tilt : 0))
        }
        .buttonStyle(.pressable)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: selected)
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
                StepHeadline(text: String(localized: "One goal for\n*this season*."))
                StepBody(text: String(localized: "Something to work toward. You get 90 days."))
                    .padding(.top, 10)
                BigField(placeholder: String(localized: "My goal is to…"), text: $title, size: 32,
                         autofocus: false, onSubmit: onSubmit)
                    .padding(.top, 28)
                    .reveal(2)
                MonoCaps(String(localized: "Or pick one"), color: Color.ink.opacity(0.55))
                    .padding(.top, 30)
                    .reveal(3)
                FlowLayout(spacing: 8) {
                    ForEach(GoalSuggestion.all) { suggestion in
                        chip(suggestion)
                    }
                }
                .padding(.top, 12)
                .reveal(3)
            }
            .readableColumn()
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .sovaFeedback(.selection, trigger: title)
    }

    private func chip(_ suggestion: GoalSuggestion) -> some View {
        let selected: Bool = title == suggestion.title
        let tone: StickerTone = suggestion.tone
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                title = selected ? "" : suggestion.title
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: suggestion.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(selected ? tone.deep : (tone == .indigo ? tone.fill : tone.deep))
                Text(suggestion.title)
                    .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.3)
                    .foregroundStyle(selected ? tone.deep : Color.ink)
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(selected ? tone.fill : Color.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: selected ? 0 : 1.5))
            .scaleEffect(selected ? 1.04 : 1)
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
                StepHeadline(text: String(localized: "A little nudge,\n*twice a day*."))
                StepBody(text: String(localized: "Your real top three, every morning."))
                    .padding(.top, 10)

                NotificationPreview(name: name)
                    .rotationEffect(.degrees(-1.5))
                    .padding(.top, 26)
                    .offset(y: dropped ? 0 : -24)
                    .opacity(dropped ? 1 : 0)
                    .scaleEffect(dropped ? 1 : 0.95)

                VStack(spacing: 0) {
                    reminderRow(title: String(localized: "Morning plan"), symbol: "sun.max.fill",
                                tone: .yellow, isOn: $morningOn, time: $morning)
                    Rectangle().fill(Color.hairline).frame(height: 1.5)
                    reminderRow(title: String(localized: "Evening check-in"), symbol: "moon.fill",
                                tone: .lilac, isOn: $eveningOn, time: $evening)
                }
                .padding(.horizontal, 18)
                .cardBackground()
                .padding(.top, 22)
                .reveal(2)
            }
            .readableColumn()
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { dropped = true }
        }
        .sovaFeedback(.impact(weight: .light), trigger: dropped)
    }

    private func reminderRow(title: String, symbol: String, tone: StickerTone,
                             isOn: Binding<Bool>, time: Binding<Date>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tone.deep)
                .frame(width: 40, height: 40)
                .background(tone.fill, in: .rect(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                    .foregroundStyle(Color.ink)
                DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(StickerTone.indigo.fill)
                    .disabled(!isOn.wrappedValue)
                    .opacity(isOn.wrappedValue ? 1 : 0.4)
                    .padding(.leading, -8)
            }
            Spacer(minLength: 0)
            Toggle(title, isOn: isOn.animation(.smooth))
                .labelsHidden()
                .tint(StickerTone.indigo.fill)
        }
        .padding(.vertical, 14)
    }
}

/// What the morning notification will look like.
private struct NotificationPreview: View {
    var name: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OwlMark(size: 30, blinks: false, bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                    pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly, reactsToTap: false)
                .frame(width: 42, height: 42)
                .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name.isEmpty ? String(localized: "Good morning") : String(localized: "Good morning, \(name)"))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text("now").font(.caption).foregroundStyle(Color.inkSecondary)
                }
                Text("Call Mom · 6 PM\nSend the proposal\nRitual: Morning pages")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.surface, in: .rect(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1))
        .shadow(color: Color.night.opacity(0.12), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example notification: Good morning, with your top three for the day.")
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
            .readableColumn()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stage
                .padding(.top, 6)
                .reveal(0)
            StepHeadline(text: name.isEmpty ? String(localized: "You're *all set*.")
                                            : String(localized: "You're all set,\n*\(name)*."), index: 1)
                .padding(.top, 26)
                .padding(.horizontal, 8)
            HStack(spacing: 8) {
                summary(label: String(localized: "Rituals"), value: "\(ritualCount)")
                summary(label: String(localized: "Goal"),
                        value: goalTitle.isEmpty ? String(localized: "Later") : goalTitle, small: !goalTitle.isEmpty)
                    .layoutPriority(1)
                summary(label: String(localized: "Nudges"), value: remindersOn ? String(localized: "On") : String(localized: "Off"))
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 20)
            .padding(.horizontal, 8)
            .reveal(2)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 16)
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            hop += 1
            Haptics.celebrate()
        }
    }

    /// The owl, overjoyed, on indigo with sparkles.
    private var stage: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            ZStack {
                StickerTone.indigo.fill
                SparkleBurst(trigger: hop, radius: CGSize(width: 160, height: 130), count: 16)
                    .position(x: w / 2, y: h * 0.5)
                OwlMark(size: min(170, h * 0.5), happy: true, blinks: false, bodyColor: StickerTone.yellow.fill,
                        eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, celebrate: hop)
                    .position(x: w / 2, y: h * 0.54)
                SparkleDot(color: StickerTone.yellow.fill, size: 30).position(x: w * 0.15, y: h * 0.18).pop(0)
                SparkleDot(color: StickerTone.mint.fill, size: 20).position(x: w * 0.86, y: h * 0.24).pop(1)
                SparkleDot(color: StickerTone.pink.fill, size: 18).position(x: w * 0.84, y: h * 0.78).pop(2)
                SparkleDot(color: StickerTone.lilac.fill, size: 14).position(x: w * 0.14, y: h * 0.66).pop(3)
            }
        }
        .frame(maxHeight: 380)
        .clipShape(.rect(cornerRadius: 44, style: .continuous))
        .accessibilityHidden(true)
    }

    private func summary(label: String, value: String, small: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            MonoCaps(label, color: Color.ink.opacity(0.55), size: 10)
            Text(value)
                .font(small ? .allo(size: 16, weight: .heavy, relativeTo: .headline) : .hero(28, weight: .heavy))
                .tracking(small ? -0.3 : -1)
                .foregroundStyle(Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardBackground(22)
    }
}
