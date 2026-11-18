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
    @Environment(WaveDirector.self) private var waves

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedGoal: String { goalTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var chosenRituals: [RitualOption] { RitualOption.all.filter { rituals.contains($0.id) } }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                OnboardingBackdrop(step: step, theme: theme)

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 16)
                        .frame(height: 52)

                    ZStack {
                        stepView
                            .id(step)
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .opacity.combined(with: .scale(scale: 0.98)).animation(.smooth(duration: 0.25))
                            ))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    bottomBar
                }
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
            if step > .hello && step < .finish {
                CircleAction(symbol: "chevron.left", label: String(localized: "Back"), action: back)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            if indicated.contains(step) {
                HStack(spacing: 4) {
                    ForEach(0..<indicated.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= position ? Color.ink : Color.ink.opacity(0.12))
                            .frame(height: 6)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Step \(position + 1) of \(indicated.count)")
                .transition(.opacity)
            }
            Spacer(minLength: 0)
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
            .buttonStyle(.big)
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
        .padding(.horizontal, 20)
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
        withAnimation(.smooth(duration: 0.5)) { step = next }
    }

    private func back() {
        guard let previous = step.previous else { return }
        withAnimation(.smooth(duration: 0.45)) { step = previous }
    }

    private func finish() {
        userName = trimmedName
        StarterContent.install(rituals: chosenRituals, goalTitle: trimmedGoal, theme: theme, in: context)
        // A wave in Sova's colors rises from the button and lands on Today;
        // the real Today takes over underneath once it has landed.
        let started = waves.play(.welcome, from: launchFrame) {
            hasOnboarded = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                waves.dismiss()
            }
        }
        if !started { withAnimation(.smooth(duration: 0.7)) { hasOnboarded = true } }
    }
}

/// Warm paper behind every step.
struct OnboardingBackdrop: View {
    var step: OnboardingStep
    var theme: SovaTheme

    var body: some View {
        Color.canvas
            .ignoresSafeArea()
            .accessibilityHidden(true)
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
