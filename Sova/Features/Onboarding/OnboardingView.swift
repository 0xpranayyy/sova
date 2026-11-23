import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable, Comparable {
    case hello, pillars, name, rituals, goal, rhythm, theme, finish

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    // The accent step is skipped: the design uses Allo's full palette.
    var next: OnboardingStep? {
        let n = OnboardingStep(rawValue: rawValue + 1)
        return n == .theme ? .finish : n
    }
    var previous: OnboardingStep? {
        let p = OnboardingStep(rawValue: rawValue - 1)
        return p == .theme ? .rhythm : p
    }

    /// The steps that show in the progress indicator.
    static let indicated: [OnboardingStep] = [.pillars, .name, .rituals, .goal, .rhythm]

    /// Each step has its own sticker color: the glow behind it, the
    /// progress bar and the end of its headline.
    var tone: StickerTone {
        switch self {
        case .hello: .yellow
        case .pillars: .mint
        case .name: .lilac
        case .rituals: .orange
        case .goal: .pink
        case .rhythm: .cyan
        case .theme: .lime
        case .finish: .yellow
        }
    }
}

extension EnvironmentValues {
    /// The current onboarding step's color, for headlines to pick up.
    @Entry var onboardingTone: StickerTone = .indigo
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("userName") private var userName = ""
    @AppStorage("morningReminderOn") private var savedMorningOn = false
    @AppStorage("morningReminderMinutes") private var savedMorningMinutes = 8 * 60
    @AppStorage("eveningReminderOn") private var savedEveningOn = false
    @AppStorage("eveningReminderMinutes") private var savedEveningMinutes = 21 * 60

    @State private var step: OnboardingStep = .hello
    @State private var name = ""
    @State private var rituals: Set<String> = []
    @State private var goalTitle = ""
    @State private var morningOn = true
    @State private var morning = Reminders.time(hour: 8)
    @State private var eveningOn = true
    @State private var evening = Reminders.time(hour: 21)
    @State private var remindersGranted = false
    @State private var isRequesting = false
    @State private var look = CGSize(width: 0, height: 0.4)
    /// Where the main button sits on screen: the welcome wave rises from it.
    @State private var launchFrame: CGRect = .zero
    /// Which way the last step change went, so steps slide the right way.
    @State private var forward = true
    @Environment(WaveDirector.self) private var waves

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedGoal: String { goalTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var chosenRituals: [RitualOption] { RitualOption.all.filter { rituals.contains($0.id) } }
    /// The little owl in the top bar smiles once you've answered.
    private var owlHappy: Bool {
        switch step {
        case .name: !trimmedName.isEmpty
        case .rituals: !rituals.isEmpty
        case .goal: !trimmedGoal.isEmpty
        case .rhythm: morningOn || eveningOn
        default: false
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                OnboardingBackdrop(step: step, theme: theme)

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 24)
                        .frame(height: 56)

                    ZStack {
                        stepView
                            .id(step)
                            .environment(\.onboardingTone, step.tone)
                            .transition(.asymmetric(
                                insertion: .move(edge: forward ? .trailing : .leading)
                                    .combined(with: .opacity).combined(with: .scale(scale: 0.96)),
                                removal: .move(edge: forward ? .leading : .trailing)
                                    .combined(with: .opacity).combined(with: .scale(scale: 0.96))
                            ))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .clipped()

                    bottomBar
                }
                // On iPad the steps stay a comfortable column in the middle,
                // while the glow fills the whole screen.
                .readableColumn(620)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard step == .hello else { return }
                        let dx = (value.location.x - geo.size.width / 2) / (geo.size.width / 2)
                        let dy = (value.location.y - geo.size.height * 0.28) / (geo.size.height / 2)
                        look = CGSize(width: max(-1, min(1, dx)), height: max(-1, min(1, dy)))
                    }
                    .onEnded { value in
                        look = CGSize(width: 0, height: 0.4)
                        // Swipe right to go back, like a navigation stack.
                        if step > .hello, step < .finish,
                           value.translation.width > 90, abs(value.translation.height) < 70 {
                            back()
                        }
                    }
            )
        }
        .tint(Color.ink)
        .sovaFeedback(.selection, trigger: step)
        // Replaying the welcome keeps the name you already gave.
        .onAppear { if name.isEmpty { name = userName } }
    }

    // MARK: Pieces

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .hello: HelloStep(look: look)
        case .pillars: PillarsStep()
        case .name: NameStep(name: $name, onSubmit: primaryAction)
        case .rituals: RitualsStep(selection: $rituals)
        case .goal: GoalStep(title: $goalTitle, onSubmit: primaryAction)
        case .rhythm: RhythmStep(name: trimmedName, morningOn: $morningOn, morning: $morning,
                                 eveningOn: $eveningOn, evening: $evening)
        case .theme: ThemeStep(themeRaw: $themeRaw, name: trimmedName, rituals: chosenRituals, goalTitle: trimmedGoal)
        case .finish: FinishStep(name: trimmedName, ritualCount: rituals.count, goalTitle: trimmedGoal,
                                 remindersOn: remindersGranted, theme: theme)
        }
    }

    private var topBar: some View {
        let indicated = OnboardingStep.indicated
        let position = indicated.firstIndex(of: step) ?? 0
        return HStack(spacing: 14) {
            if indicated.contains(step) {
                CircleAction(symbol: "chevron.left", label: String(localized: "Back"), action: back)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                StepTrack(value: Double(position + 1) / Double(indicated.count))
                    .accessibilityElement()
                    .accessibilityLabel("Step \(position + 1) of \(indicated.count)")
                    .transition(.opacity)
                OwlMark(size: 32, happy: owlHappy, bodyColor: StickerTone.yellow.fill,
                        eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, reactsToTap: false)
                    .accessibilityHidden(true)
                    .transition(.opacity.combined(with: .scale(scale: 0.6)))
            } else {
                Spacer(minLength: 0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
    }

    private var primaryTitle: String {
        switch step {
        case .hello: String(localized: "Get started")
        case .name: trimmedName.isEmpty ? String(localized: "Skip for now") : String(localized: "Continue")
        case .rituals: rituals.isEmpty ? String(localized: "Skip for now")
                                       : String(localized: "Continue with \(rituals.count)")
        case .finish: String(localized: "Open Sova")
        case .goal: trimmedGoal.isEmpty ? String(localized: "Skip for now") : String(localized: "Set this goal")
        case .rhythm: (morningOn || eveningOn) ? String(localized: "Turn on reminders") : String(localized: "Continue")
        default: String(localized: "Continue")
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Text(primaryTitle)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: primaryTitle)
                        .opacity(isRequesting ? 0 : 1)
                    if isRequesting { ProgressView().tint(StickerTone.indigo.deep) }
                    if !isRequesting && (step == .hello || step == .finish) {
                        Image(systemName: "arrow.right").font(.system(size: 17, weight: .heavy))
                    }
                }
            }
            .buttonStyle(.big(.indigo))
            .disabled(isRequesting)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { launchFrame = $0 }

            if step == .rhythm && (morningOn || eveningOn) {
                Button("Not now") {
                    morningOn = false
                    eveningOn = false
                    advance()
                }
                .font(.allo(.subheadline, .medium))
                .foregroundStyle(Color.inkSecondary)
                .frame(minHeight: 32)
                .transition(.opacity)
            }

        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .animation(.smooth(duration: 0.35), value: step)
    }

    // MARK: Flow

    private func primaryAction() {
        guard step == .rhythm, morningOn || eveningOn else { return advance() }
        isRequesting = true
        let morningTime = morningOn ? morning : nil
        let eveningTime = eveningOn ? evening : nil
        Task {
            let granted = await Reminders.enable(morning: morningTime, evening: eveningTime)
            remindersGranted = granted
            savedMorningOn = granted && morningOn
            savedEveningOn = granted && eveningOn
            savedMorningMinutes = minutes(of: morning)
            savedEveningMinutes = minutes(of: evening)
            isRequesting = false
            advance()
        }
    }

    private func minutes(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private func advance() {
        if step == .name { userName = trimmedName }
        guard let next = step.next else { return finish() }
        forward = true
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { step = next }
    }

    private func back() {
        guard let previous = step.previous else { return }
        forward = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) { step = previous }
    }

    private func finish() {
        userName = trimmedName
        StarterContent.install(rituals: chosenRituals, goalTitle: trimmedGoal, theme: theme, in: context)
        // A wave in Sova's colors rises from the button and lands on Today.
        // The real Today is switched in underneath straight away; the wave
        // is only a cover over it that clears itself.
        let started = waves.play(.welcome, from: launchFrame)
        if started {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { hasOnboarded = true }
            return
        }
        withAnimation(.smooth(duration: 0.7)) { hasOnboarded = true }
    }
}

/// Warm paper behind every step, with a big soft glow in the step's color
/// that drifts and changes color as you move through the steps.
struct OnboardingBackdrop: View {
    var step: OnboardingStep
    var theme: SovaTheme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // One calm canvas for every step: the content carries the color.
        CanvasBackground()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// The progress bar: a chunky track that fills in the step's color, with
/// the owl riding along the end of it.
struct OwlProgress: View {
    var value: Double
    var tone: StickerTone

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let filled = max(18, w * value)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.ink.opacity(0.08))
                Capsule()
                    .fill(tone.fill.shadow(.drop(color: tone.shadow, radius: 4, y: 2)))
                    .overlay(alignment: .top) {
                        Capsule().fill(Color.white.opacity(0.45)).frame(height: 3).padding(.horizontal, 5).padding(.top, 2)
                    }
                    .frame(width: filled)
                OwlMark(size: 26, blinks: true, bodyColor: StickerTone.indigo.fill, eyeColor: StickerTone.yellow.fill,
                        reactsToTap: false)
                    .offset(x: filled - 17, y: -9)
            }
            .frame(height: 12)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.72), value: value)
        .animation(.easeInOut(duration: 0.5), value: tone)
    }
}

/// Staggered entrance: each line arrives a beat after the last.
struct Reveal: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 20)
            .blur(radius: shown || reduceMotion ? 0 : 8)
            .onAppear {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.86).delay(0.1 + Double(index) * 0.075)) {
                    shown = true
                }
            }
    }
}

extension View {
    func reveal(_ index: Int) -> some View { modifier(Reveal(index: index)) }
}

#Preview {
    OnboardingView()
        .environment(WaveDirector())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
