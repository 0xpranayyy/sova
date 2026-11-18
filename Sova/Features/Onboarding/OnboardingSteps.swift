import SwiftUI

// Each step is left-aligned and editorial: a large serif headline, one
// supporting line, and a single interactive idea.

private struct StepHeadline: View {
    let text: String
    var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 40

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .regular, design: .serif))
            .tracking(-0.6)
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
            .font(.body)
            .foregroundStyle(Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .reveal(index)
    }
}

// MARK: - 1. Hello

struct HelloStep: View {
    var look: CGSize
    @ScaledMetric(relativeTo: .largeTitle) private var helloSize: CGFloat = 68
    @ScaledMetric(relativeTo: .title) private var taglineSize: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 12)
            OwlMark(size: 104, look: look)
                .reveal(0)
            Spacer().frame(height: 44)
            Text("Hello.")
                .font(.system(size: helloSize, weight: .regular, design: .serif))
                .italic()
                .tracking(-1.8)
                .foregroundStyle(Color.ink)
                .reveal(1)
            Text("A calmer way to\nrun your days.")
                .font(.system(size: taglineSize, weight: .regular, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(2)
            Text("Tasks, routines and goals, kept in one quiet place.")
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 18)
                .reveal(3)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(accent.color)
            }
            content
        }
        .surface(cornerRadius: 22, padding: 18)
        .rotationEffect(.degrees(settled ? rotation : 0))
        .offset(x: settled ? offsetX : 0)
    }
}

// MARK: - 3. Name

struct NameStep: View {
    @Binding var name: String
    var onSubmit: () -> Void
    @FocusState private var focused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var fieldSize: CGFloat = 38

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        default: String(localized: "Good evening")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            StepHeadline(text: String(localized: "What should\nwe call you?"))
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                TextField("", text: $name, prompt: Text("Your name").foregroundStyle(Color.inkTertiary))
                    .font(.system(size: fieldSize, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ink)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .focused($focused)
                    .onSubmit(onSubmit)

                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.hairline)
                    Rectangle()
                        .fill(Color.accentColor)
                        .scaleEffect(x: focused ? 1 : 0, anchor: .leading)
                }
                .frame(height: 2)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: focused)
            }
            .reveal(1)

            Group {
                if name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Just for your greeting. It never leaves this device.")
                } else {
                    Text("\(greeting), \(Text(name.trimmingCharacters(in: .whitespaces)).foregroundStyle(Color.ink)).")
                }
            }
            .font(.display(.title3))
            .foregroundStyle(Color.inkSecondary)
            .contentTransition(.opacity)
            .animation(.smooth(duration: 0.3), value: name.isEmpty)
            .reveal(2)

            Spacer()
        }
        .padding(.horizontal, 28)
        .task {
            try? await Task.sleep(for: .milliseconds(550))
            focused = true
        }
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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selected ? ritual.accent.color : Color.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 1)
                    .opacity(selected ? 0 : 1)
            }
            .shadow(color: (selected ? ritual.accent.color : Color.black).opacity(selected ? 0.28 : 0.04),
                    radius: selected ? 14 : 8, y: selected ? 8 : 4)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(ritual.title)
        .accessibilityValue(ritual.period.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - 5. Theme

struct ThemeStep: View {
    @Binding var themeRaw: String
    var name: String

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    StepHeadline(text: String(localized: "Make it\nyours."))
                    StepBody(text: String(localized: "One color, used with restraint. Change it whenever the mood changes."))
                }
                .padding(.top, 8)

                MiniToday(accent: theme.accent, name: name)
                    .reveal(2)

                HStack(spacing: 0) {
                    ForEach(SovaTheme.allCases) { option in
                        Button {
                            withAnimation(.smooth(duration: 0.6)) { themeRaw = option.rawValue }
                        } label: {
                            VStack(spacing: 10) {
                                Circle()
                                    .fill(option.accent.color)
                                    .frame(width: 38, height: 38)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(Color.ink, lineWidth: 2)
                                            .padding(-6)
                                            .opacity(option == theme ? 1 : 0)
                                            .scaleEffect(option == theme ? 1 : 0.85)
                                    }
                                Text(option.name)
                                    .font(.caption.weight(option == theme ? .semibold : .regular))
                                    .foregroundStyle(option == theme ? Color.ink : Color.inkSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel(option.name)
                        .accessibilityAddTraits(option == theme ? .isSelected : [])
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: themeRaw)
                .reveal(3)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: themeRaw)
    }
}

/// A miniature of the Today screen that recolors live.
private struct MiniToday: View {
    var accent: Accent
    var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(.display(.title2))
                    .foregroundStyle(Color.ink)
                Text(name.isEmpty ? String(localized: "Three things left today.")
                                  : String(localized: "Three things left, \(name)."))
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
            }
            DaySegments(done: 2, total: 5, color: accent.color)
            VStack(spacing: 0) {
                row("Morning pages", detail: "Routine", done: true)
                Divider().overlay(Color.hairline).padding(.leading, 34)
                row("Send the proposal", detail: "10:00 AM", done: true)
                Divider().overlay(Color.hairline).padding(.leading, 34)
                row("Call Mom", detail: "6:30 PM", done: false)
            }
        }
        .surface(cornerRadius: 24, padding: 18)
    }

    private func row(_ title: String, detail: String, done: Bool) -> some View {
        HStack(spacing: 12) {
            Checkbox(isOn: done, color: accent.color, size: 20)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(done ? Color.inkSecondary : Color.ink)
                .strikethrough(done, color: Color.inkTertiary)
            Spacer()
            Text(detail).font(.caption).foregroundStyle(Color.inkSecondary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 6. Finish

struct FinishStep: View {
    var name: String
    var ritualCount: Int
    var theme: SovaTheme
    @State private var hop = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 46

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 12)
            OwlMark(size: 104, happy: true, blinks: false)
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
                .font(.system(size: size, weight: .regular, design: .serif))
                .tracking(-0.8)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(1)
            Text("Here’s to good days, and the small things that make them.")
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 16)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(2)

            HStack(spacing: 10) {
                summaryChip(ritualCount == 1 ? String(localized: "1 ritual") : String(localized: "\(ritualCount) rituals"),
                            color: Accent.lagoon.color)
                summaryChip(String(localized: "\(theme.name) theme"), color: theme.accent.color)
            }
            .padding(.top, 24)
            .reveal(3)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sensoryFeedback(.success, trigger: hop)
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            hop += 1
        }
    }

    private func summaryChip(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.footnote.weight(.medium)).foregroundStyle(Color.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.surface, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.hairline))
    }
}
