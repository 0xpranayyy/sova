import SwiftUI

// Onboarding: big heavy headlines, Allo's colors as blocks and stickers,
// and the owl as a character who greets you, asks your name and celebrates.

private struct StepHeadline: View {
    let text: String
    var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 44
    @Environment(\.onboardingTone) private var tone

    /// The headline, with its closing period or question mark in the step's color.
    private var styled: Text {
        guard let last = text.last, ".?!".contains(last) else { return Text(text).foregroundStyle(Color.ink) }
        let dot = tone == .yellow || tone == .lime ? tone.lip : tone.fill
        return Text(String(text.dropLast())).foregroundStyle(Color.ink) + Text(String(last)).foregroundStyle(dot)
    }

    var body: some View {
        styled
            .font(.hero(size, weight: .heavy))
            .tracking(-2)
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
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 88

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OwlStage(look: look)
                .padding(.top, 4)
                .reveal(0)

            Spacer(minLength: 18)

            Text("Sova.")
                .font(.hero(titleSize, weight: .heavy))
                .tracking(-4.2)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .reveal(2)
            Text("Your day, your rituals, your goals.\nPlanned in a minute.")
                .font(.allo(size: 20, weight: .bold, relativeTo: .title3))
                .tracking(-0.3)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 8)
                .padding(.bottom, 22)
                .reveal(3)
        }
        .padding(.horizontal, 16)
    }
}

/// The welcome stage: the owl on indigo, with the things a Sova day is
/// made of floating around it.
private struct OwlStage: View {
    var look: CGSize
    @State private var wave = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                StickerTone.indigo.fill

                OwlMark(size: 150, look: look, bodyColor: StickerTone.yellow.fill,
                        eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, celebrate: wave)
                    .position(x: w / 2, y: h * 0.42)

                TiltPill(text: String(localized: "Meditate ✓"), tone: .mint, tilt: -8).position(x: w * 0.24, y: h * 0.13).pop(0)
                TiltPill(text: String(localized: "12 days"), tone: .orange, tilt: 7).position(x: w * 0.82, y: h * 0.27).pop(1)
                TiltPill(text: String(localized: "Read 12 books"), tone: .pink, tilt: -5).position(x: w * 0.25, y: h * 0.66).pop(2)
                TiltPill(text: String(localized: "Call Mom · 6 PM"), tone: .cyan, tilt: 6).position(x: w * 0.74, y: h * 0.78).pop(3)
                TiltPill(text: String(localized: "3/8 today"), tone: .lilac, tilt: 3).position(x: w * 0.28, y: h * 0.88).pop(4)

                SparkleDot(color: StickerTone.yellow.fill, size: 30).position(x: w * 0.88, y: h * 0.11)
                SparkleDot(color: StickerTone.mint.fill, size: 20).position(x: w * 0.13, y: h * 0.45)
                SparkleDot(color: StickerTone.pink.fill, size: 16).position(x: w * 0.84, y: h * 0.58)
            }
        }
        .frame(height: 400)
        .clipShape(.rect(cornerRadius: 40, style: .continuous))
        .shadow(color: StickerTone.indigo.shadow, radius: 22, y: 12)
        .task {
            // Say hello once the stickers have landed.
            try? await Task.sleep(for: .milliseconds(900))
            wave += 1
        }
        .accessibilityHidden(true)
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
            .readableColumn()
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
        .background(tone?.fill ?? Color.surface, in: .rect(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.hairline, lineWidth: tone == nil ? 1.5 : 0))
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

    @State private var hello = 0

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
            // The owl asks.
            HStack(alignment: .top, spacing: 10) {
                OwlMark(size: 76, happy: !trimmed.isEmpty, celebrate: hello)
                    .reveal(0)
                    .onChange(of: trimmed.isEmpty) { _, isEmpty in
                        if !isEmpty {
                            hello += 1
                            Haptics.soft(0.7)
                        }
                    }
                Text(trimmed.isEmpty ? String(localized: "Hi, I'm Sova! What should I call you?")
                                     : String(localized: "Nice to meet you, \(trimmed)!"))
                    .font(.allo(size: 19, weight: .heavy, relativeTo: .title3))
                    .tracking(-0.4)
                    .foregroundStyle(StickerTone.lilac.deep)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(StickerTone.lilac.fill,
                                in: UnevenRoundedRectangle(topLeadingRadius: 26, bottomLeadingRadius: 8,
                                                           bottomTrailingRadius: 26, topTrailingRadius: 26,
                                                           style: .continuous))
                    .contentTransition(.opacity)
                    .animation(.smooth(duration: 0.3), value: trimmed.isEmpty)
                    .padding(.top, 6)
                    .reveal(1)
            }
            .padding(.top, 12)

            GlassField(placeholder: String(localized: "Your name"), text: $name,
                       contentType: .givenName, onSubmit: onSubmit)
                .padding(.top, 28)
                .reveal(2)

            HStack(spacing: 10) {
                MonoCaps(String(localized: "Preview"))
                Text(trimmed.isEmpty ? greeting : "\(greeting), \(trimmed)")
                    .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                    .foregroundStyle(Color.ink)
                    .contentTransition(.opacity)
            }
            .padding(.top, 18)
            .padding(.leading, 4)
            .animation(.smooth(duration: 0.25), value: trimmed)
            .reveal(3)

            Text("Just for your greeting. Stays on this iPhone.")
                .font(.allo(.subheadline, .bold))
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 10)
                .padding(.leading, 4)
                .reveal(4)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 4. Rituals

struct RitualsStep: View {
    @Binding var selection: Set<String>
    @State private var cheers = 0
    @State private var limitNudge = 0

    private var atLimit: Bool { selection.count >= PlusGate.starterRituals }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    StepHeadline(text: String(localized: "Pick your\nrituals."))
                    OwlMark(size: 50, happy: selection.count >= 3, celebrate: cheers)
                        .rotationEffect(.degrees(8))
                        .onChange(of: selection.count) { old, new in
                            if old < 3 && new >= 3 {
                                cheers += 1
                                Haptics.soft(0.8)
                            }
                        }
                        .padding(.bottom, 2)
                        .reveal(1)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(RitualOption.all.enumerated()), id: \.element.id) { index, ritual in
                        RitualTile(ritual: ritual, selected: selection.contains(ritual.id), tilt: index.isMultiple(of: 2) ? -1.5 : 1.5) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                if selection.contains(ritual.id) { selection.remove(ritual.id) }
                                else if atLimit { limitNudge += 1; Haptics.warning() }
                                else { selection.insert(ritual.id) }
                            }
                        }
                        .reveal(2 + index / 2)
                    }
                }
                .padding(.top, 20)

                Text("Start with up to \(PlusGate.starterRituals). You can add more anytime.")
                    .font(.allo(.footnote, .bold))
                    .foregroundStyle(atLimit ? Color.ink : Color.inkSecondary)
                    .padding(.top, 14)
                    .keyframeAnimator(initialValue: 0.0, trigger: limitNudge) { view, x in
                        view.offset(x: x)
                    } keyframes: { _ in
                        KeyframeTrack {
                            SpringKeyframe(-8, duration: 0.07)
                            SpringKeyframe(7, duration: 0.07)
                            SpringKeyframe(-4, duration: 0.07)
                            SpringKeyframe(0, duration: 0.2)
                        }
                    }
            }
            .readableColumn()
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .sovaFeedback(.selection, trigger: selection)
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
            .background(selected ? tone.fill : Color.surface, in: .rect(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
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
                StepHeadline(text: String(localized: "One goal for\nthis season."))
                StepBody(text: String(localized: "Something to work toward. You get 90 days."))
                    .padding(.top, 10)

                GlassField(placeholder: String(localized: "My goal is to…"), text: $title,
                           autofocus: false, onSubmit: onSubmit)
                    .padding(.top, 22)
                    .reveal(2)

                FlowLayout(spacing: 8) {
                    ForEach(Array(GoalSuggestion.all.enumerated()), id: \.element.id) { index, suggestion in
                        let selected = title == suggestion.title
                        let tone = suggestion.tone
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                title = selected ? "" : suggestion.title
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: suggestion.symbol)
                                    .font(.system(size: 15, weight: .bold))
                                Text(suggestion.title)
                                    .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                                    .tracking(-0.3)
                            }
                            .foregroundStyle(tone == .indigo ? tone.deep : tone.deep)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(tone.fill, in: .capsule)
                            .overlay(Capsule().strokeBorder(Color.ink, lineWidth: selected ? 3 : 0))
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -2.5 : 2.5))
                            .scaleEffect(selected ? 1.05 : 1)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.top, 20)
                .reveal(3)
            }
            .readableColumn()
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .sovaFeedback(.selection, trigger: title)
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
                StepHeadline(text: String(localized: "A little nudge,\ntwice a day."))

                NotificationPreview(name: name)
                    .rotationEffect(.degrees(-2))
                    .padding(.top, 24)
                    .offset(y: dropped ? 0 : -24)
                    .opacity(dropped ? 1 : 0)
                    .scaleEffect(dropped ? 1 : 0.95)

                VStack(spacing: 10) {
                    reminderRow(title: String(localized: "Morning plan"), symbol: "sunrise",
                                tone: .yellow, isOn: $morningOn, time: $morning)
                    reminderRow(title: String(localized: "Evening review"), symbol: "moon",
                                tone: .lilac, isOn: $eveningOn, time: $evening)
                }
                .padding(.top, 22)
                .reveal(2)
            }
            .readableColumn()
            .padding(.horizontal, 20)
            .padding(.top, 8)
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
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(tone.deep)
                    .disabled(!isOn.wrappedValue)
                    .opacity(isOn.wrappedValue ? 1 : 0.4)
            }
            Spacer(minLength: 0)
            Toggle(title, isOn: isOn.animation(.smooth))
                .labelsHidden()
                .tint(tone.deep)
        }
        .foregroundStyle(tone.deep)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(tone.fill, in: .rect(cornerRadius: 28, style: .continuous))
    }
}

/// What the morning notification will look like.
private struct NotificationPreview: View {
    var name: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OwlMark(size: 24, blinks: false)
                .frame(width: 40, height: 40)
                .background(StickerTone.yellow.fill, in: .rect(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("SOVA").font(.allo(.caption, .bold)).foregroundStyle(Color.inkSecondary)
                    Spacer()
                    Text("now").font(.allo(.caption, .bold)).foregroundStyle(Color.inkSecondary)
                }
                Text(name.isEmpty ? String(localized: "Good morning ☀️") : String(localized: "Good morning, \(name) ☀️"))
                    .font(.allo(.subheadline, .heavy))
                    .foregroundStyle(Color.ink)
                Text("Your day is ready. Let's go.")
                    .font(.allo(.subheadline, .semibold))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .padding(14)
        .background(Color.surface, in: .rect(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.ink.opacity(0.12), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example notification: Good morning. Your day is ready.")
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
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    StickerTone.indigo.fill
                    SparkleBurst(trigger: hop, radius: CGSize(width: 150, height: 120), count: 14)
                        .position(x: w / 2, y: h * 0.5)
                    OwlMark(size: 140, happy: true, blinks: false, bodyColor: StickerTone.yellow.fill,
                            eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                            bellyColor: Color.owlBelly, celebrate: hop)
                        .position(x: w / 2, y: h * 0.52)
                    SparkleDot(color: StickerTone.mint.fill, size: 40).position(x: w * 0.16, y: h * 0.22).pop(0)
                    SparkleDot(color: StickerTone.pink.fill, size: 28).position(x: w * 0.84, y: h * 0.18).pop(1)
                    SparkleDot(color: StickerTone.yellow.fill, size: 44).position(x: w * 0.88, y: h * 0.74).pop(2)
                    SparkleDot(color: StickerTone.lilac.fill, size: 24).position(x: w * 0.14, y: h * 0.78).pop(3)
                    SparkleDot(color: StickerTone.orange.fill, size: 16).position(x: w * 0.28, y: h * 0.47).pop(4)
                    SparkleDot(color: StickerTone.cyan.fill, size: 20).position(x: w * 0.72, y: h * 0.46).pop(5)
                }
            }
            .frame(height: 290)
            .clipShape(.rect(cornerRadius: 40, style: .continuous))
            .padding(.top, 6)
            .reveal(0)

            HStack(spacing: 8) {
                summary(ritualCount == 0 ? "0" : "\(ritualCount)", label: String(localized: "Rituals"), tone: .mint)
                summary(remindersOn ? String(localized: "On") : String(localized: "Off"), label: String(localized: "Reminders"), tone: .yellow)
            }
            .frame(height: 96)
            .reveal(1)

            if !goalTitle.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    MonoCaps(String(localized: "Your goal · 90 days"), color: StickerTone.pink.deep, size: 10)
                    Text(goalTitle)
                        .font(.allo(size: 21, weight: .heavy, relativeTo: .title3))
                        .tracking(-0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(StickerTone.pink.deep)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(StickerTone.pink.fill, in: .rect(cornerRadius: 28, style: .continuous))
                .reveal(2)
            }

            Spacer(minLength: 12)

            Text(name.isEmpty ? String(localized: "You're all set.") : String(localized: "You're all set,\n\(name)."))
                .font(.hero(size, weight: .heavy))
                .tracking(-2)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 18)
                .reveal(3)
        }
        .padding(.horizontal, 16)
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            hop += 1
            Haptics.celebrate()
        }
    }

    private func summary(_ value: String, label: String, tone: StickerTone) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            MonoCaps(label, color: tone.deep, size: 10)
            Text(value)
                .font(.hero(40, weight: .heavy))
                .tracking(-1.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(tone.deep)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .background(tone.fill, in: .rect(cornerRadius: 28, style: .continuous))
    }
}
