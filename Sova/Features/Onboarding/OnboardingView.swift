import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable, Comparable {
    case hello, pillars, name, rituals, theme, finish

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }

    /// The steps that show in the progress indicator.
    static let indicated: [OnboardingStep] = [.pillars, .name, .rituals, .theme]
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("userName") private var userName = ""

    @State private var step: OnboardingStep = .hello
    @State private var name = ""
    @State private var rituals: Set<String> = ["pages", "water", "read"]
    @State private var look = CGSize(width: 0, height: 0.4)

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

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
                    .onEnded { _ in look = CGSize(width: 0, height: 0.4) }
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
        case .name: NameStep(name: $name, onSubmit: advance)
        case .rituals: RitualsStep(selection: $rituals)
        case .theme: ThemeStep(themeRaw: $themeRaw, name: trimmedName)
        case .finish: FinishStep(name: trimmedName, ritualCount: rituals.count, theme: theme)
        }
    }

    private var topBar: some View {
        HStack {
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

            Spacer()

            if OnboardingStep.indicated.contains(step) {
                StepIndicator(steps: OnboardingStep.indicated, current: step)
                    .transition(.opacity)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .foregroundStyle(Color.ink)
        .animation(.smooth(duration: 0.4), value: step)
    }

    private var primaryTitle: String {
        switch step {
        case .hello: String(localized: "Get started")
        case .name: trimmedName.isEmpty ? String(localized: "Skip for now") : String(localized: "Continue")
        case .rituals: rituals.isEmpty ? String(localized: "Skip for now")
                                       : String(localized: "Start with \(rituals.count)")
        case .finish: String(localized: "Open Sova")
        default: String(localized: "Continue")
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Button(action: advance) {
                Text(primaryTitle)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.3), value: primaryTitle)
            }
            .buttonStyle(.ink)

            if step == .hello {
                Text("Takes a minute. Everything stays on your iPhone.")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .animation(.smooth(duration: 0.35), value: step)
    }

    // MARK: Flow

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
        let chosen = RitualOption.all.filter { rituals.contains($0.id) }
        StarterContent.install(rituals: chosen, theme: theme, in: context)
        withAnimation(.smooth(duration: 0.7)) { hasOnboarded = true }
    }
}

/// Small capsule dots; the current one stretches.
struct StepIndicator: View {
    let steps: [OnboardingStep]
    let current: OnboardingStep

    var body: some View {
        HStack(spacing: 6) {
            ForEach(steps, id: \.self) { step in
                Capsule()
                    .fill(step == current ? Color.ink : Color.ink.opacity(step < current ? 0.4 : 0.14))
                    .frame(width: step == current ? 22 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \((steps.firstIndex(of: current) ?? 0) + 1) of \(steps.count)")
    }
}

/// Soft, drifting washes of color that change mood with each step.
struct OnboardingBackdrop: View {
    var step: OnboardingStep
    var theme: SovaTheme

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var colors: [Accent] {
        switch step {
        case .hello: [.marigold, .ember, .rose]
        case .pillars: [.tide, .lagoon, .plum]
        case .name: [.rose, .plum, .marigold]
        case .rituals: [.moss, .marigold, .lagoon]
        case .theme, .finish: [theme.accent, theme.companion, theme.accent]
        }
    }

    private var anchors: [UnitPoint] {
        switch step {
        case .hello: [UnitPoint(x: 0.1, y: 0.08), UnitPoint(x: 0.95, y: 0.3), UnitPoint(x: 0.45, y: 1.0)]
        case .pillars: [UnitPoint(x: 0.9, y: 0.05), UnitPoint(x: 0.05, y: 0.5), UnitPoint(x: 0.75, y: 1.0)]
        case .name: [UnitPoint(x: 0.15, y: 0.15), UnitPoint(x: 0.95, y: 0.55), UnitPoint(x: 0.25, y: 1.05)]
        case .rituals: [UnitPoint(x: 0.95, y: 0.0), UnitPoint(x: 0.0, y: 0.38), UnitPoint(x: 0.8, y: 0.95)]
        case .theme: [UnitPoint(x: 0.05, y: 0.08), UnitPoint(x: 0.95, y: 0.42), UnitPoint(x: 0.4, y: 1.0)]
        case .finish: [UnitPoint(x: 0.3, y: 0.15), UnitPoint(x: 0.95, y: 0.7), UnitPoint(x: 0.05, y: 0.95)]
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    Color.canvas
                    ForEach(0..<3, id: \.self) { index in
                        let anchor = anchors[index]
                        let phase = Double(index) * 2.1
                        Circle()
                            .fill(colors[index].color)
                            .frame(width: size.width * [1.15, 0.95, 1.05][index],
                                   height: size.width * [1.15, 0.95, 1.05][index])
                            .position(
                                x: anchor.x * size.width + sin(t * 0.32 + phase) * 26,
                                y: anchor.y * size.height + cos(t * 0.27 + phase) * 34
                            )
                            .opacity(scheme == .dark ? 0.42 : 0.5)
                            .blur(radius: 70)
                    }
                }
            }
        }
        .overlay(GrainOverlay(intensity: 1.5))
        .ignoresSafeArea()
        .animation(.smooth(duration: 1.2), value: step)
        .animation(.smooth(duration: 0.9), value: theme)
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
