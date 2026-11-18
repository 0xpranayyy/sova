import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable, Comparable {
    case hello, pillars, name, rituals, goal, rhythm, theme, finish

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }

    /// The steps that show in the progress indicator.
    static let indicated: [OnboardingStep] = [.pillars, .name, .rituals, .goal, .rhythm, .theme]
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("theme") private var themeRaw = SovaTheme.lime.rawValue
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

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .lime }
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
        .tint(theme.accent.color)
        .sensoryFeedback(.selection, trigger: step)
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
        let position = (indicated.firstIndex(of: step) ?? 0) + 1
        return HStack(spacing: 16) {
            if step > .hello && step < .finish {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Back")
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            if indicated.contains(step) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.well)
                        Capsule()
                            .fill(theme.accent.color)
                            .frame(width: geo.size.width * Double(position) / Double(indicated.count))
                    }
                }
                .frame(height: 3)
                .transition(.opacity)
                Text("\(position)/\(indicated.count)")
                    .font(.mono(12))
                    .foregroundStyle(Color.inkTertiary)
                    .contentTransition(.numericText())
                    .frame(width: 34, alignment: .trailing)
                    .accessibilityLabel("Step \(position) of \(indicated.count)")
            } else {
                Spacer()
            }
        }
        .foregroundStyle(Color.ink)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
    }

    private var primaryTitle: String {
        switch step {
        case .hello: String(localized: "Get started")
        case .name: trimmedName.isEmpty ? String(localized: "Skip for now") : String(localized: "Continue")
        case .rituals: rituals.isEmpty ? String(localized: "Skip for now")
                                       : String(localized: "Continue with \(rituals.count)")
        case .goal: trimmedGoal.isEmpty ? String(localized: "Skip for now") : String(localized: "Set this goal")
        case .rhythm: (morningOn || eveningOn) ? String(localized: "Turn on reminders") : String(localized: "Continue")
        case .finish: String(localized: "Open Sova")
        default: String(localized: "Continue")
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Button(action: primaryAction) {
                ZStack {
                    Text(primaryTitle)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: primaryTitle)
                        .opacity(isRequesting ? 0 : 1)
                    if isRequesting { ProgressView().tint(Color.inkInverse) }
                }
            }
            .buttonStyle(.ink)
            .disabled(isRequesting)

            if step == .rhythm && (morningOn || eveningOn) {
                Button("Not now") {
                    morningOn = false
                    eveningOn = false
                    advance()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.inkSecondary)
                .frame(minHeight: 32)
                .transition(.opacity)
            }

            if step == .hello {
                Label("Private by design. Stays on your iPhone.", systemImage: "lock")
                    .font(.footnote)
                    .foregroundStyle(Color.inkTertiary)
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
        withAnimation(.smooth(duration: 0.7)) { hasOnboarded = true }
    }
}

/// Near-black with one soft glow of the accent, stronger on the welcome
/// and finish screens.
struct OnboardingBackdrop: View {
    var step: OnboardingStep
    var theme: SovaTheme

    var body: some View {
        let accent = theme.accent.color
        let hero = step == .hello || step == .finish
        ZStack {
            Color.canvas
            RadialGradient(colors: [accent.opacity(hero ? 0.14 : 0.06), .clear],
                           center: hero ? UnitPoint(x: 0.5, y: 0.33) : UnitPoint(x: 0.15, y: 0),
                           startRadius: 0, endRadius: hero ? 230 : 420)
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.8), value: step)
        .animation(.smooth(duration: 0.6), value: theme)
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
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
