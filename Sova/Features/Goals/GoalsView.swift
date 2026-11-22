import SwiftUI
import SwiftData

/// Your goals for the season. Up top, the season on an indigo stage: the
/// average, the next deadline, and your biggest goals as rings around the
/// owl, each in its own color. Below, quick filters, the goal cards, the
/// ones you've achieved, and the archive.
struct GoalsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.createdAt) private var allGoals: [Goal]
    @Namespace private var zoom
    @State private var path: [Goal] = []
    @State private var filter: GoalFilter = .all
    @State private var showArchived = false
    @State private var confirmDelete: Goal?

    var body: some View {
        let live = allGoals.filter { !$0.isArchived }
        let inProgress = live.filter { $0.progress < 1 }
        let achieved = live.filter { $0.progress >= 1 }
        let archived = allGoals.filter(\.isArchived)
        let shown = inProgress.filter(filter.matches)

        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenTitle(title: String(localized: "Goals"), subtitle: subtitle(inProgress.count, achieved.count)) {
                        CircleAction(symbol: "plus", label: String(localized: "New goal")) { router.sheet = router.newGoalSheet }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    if live.isEmpty {
                        EmptyState(title: String(localized: "No goals yet"),
                                   message: String(localized: "Add a goal and break it into steps you can check off."),
                                   actionTitle: String(localized: "Set a goal")) { router.sheet = router.newGoalSheet }
                    } else {
                        SeasonStage(goals: inProgress, achieved: achieved.count)

                        if inProgress.count > 1 {
                            GoalFilterChips(selection: $filter, counts: GoalFilter.counts(in: inProgress))
                                .padding(.horizontal, -16)
                        }

                        if shown.isEmpty && !inProgress.isEmpty {
                            Text(String(localized: "No goals here. Try another filter."))
                                .font(.allo(.subheadline, .bold))
                                .foregroundStyle(Color.inkSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }

                        ForEach(Array(shown.enumerated()), id: \.element.id) { index, goal in
                            card(goal, index: index)
                        }

                        if !achieved.isEmpty {
                            StickerHeader(title: String(localized: "Achieved"), symbol: "trophy.fill", tone: .yellow,
                                          count: achieved.count)
                                .padding(.top, 18)
                            ForEach(achieved) { goal in
                                TrophyRow(goal: goal) { open(goal) } onArchive: { archive(goal) }
                                    .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                            }
                        }
                    }

                    if !archived.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showArchived.toggle() }
                            Haptics.soft(0.4)
                        } label: {
                            HStack(spacing: 8) {
                                SectionLabel(String(localized: "Archived · \(archived.count)"))
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(Color.inkTertiary)
                                    .rotationEffect(.degrees(showArchived ? 90 : 0))
                                Spacer()
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)

                        if showArchived {
                            ForEach(archived) { goal in
                                TrophyRow(goal: goal, archived: true) { open(goal) } onArchive: { archive(goal) }
                                    .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                }
                .readableColumn()
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: filter)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: achieved.count)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .refreshable {
                // Pull down for a word from the owl.
                await MainActor.run { Haptics.owl() }
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run { router.show(Toast(message: OwlPepTalk.random())) }
            }
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
                    .toolbarVisibility(.visible, for: .navigationBar)
                    .navigationTransition(.zoom(sourceID: goal.persistentModelID, in: zoom))
            }
            .confirmationDialog(String(localized: "Delete “\(confirmDelete?.title ?? "")”?"),
                                isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
                                titleVisibility: .visible) {
                Button(String(localized: "Delete Goal"), role: .destructive) {
                    if let goal = confirmDelete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { context.delete(goal) }
                        SovaRefresh.changed(context)
                        Haptics.warning()
                    }
                    confirmDelete = nil
                }
            } message: {
                Text(String(localized: "Its steps are deleted too. Linked tasks are kept."))
            }
        }
    }

    private func subtitle(_ inProgress: Int, _ achieved: Int) -> String {
        if inProgress == 0 && achieved == 0 { return String(localized: "Nothing in progress") }
        if achieved > 0 { return String(localized: "\(inProgress) in progress · \(achieved) achieved") }
        return String(localized: "\(inProgress) in progress")
    }

    private func card(_ goal: Goal, index: Int) -> some View {
        GoalCard(goal: goal, number: index + 1)
            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -0.6 : 0.6))
            .contentShape(.rect)
            .onTapGesture { open(goal) }
            .matchedTransitionSource(id: goal.persistentModelID, in: zoom)
            .contextMenu {
                Button(String(localized: "Edit Goal"), systemImage: "pencil") { router.sheet = .goal(goal) }
                Button(String(localized: "Add a Task"), systemImage: "plus") { router.sheet = .newTask(goal) }
                Button(String(localized: "Archive"), systemImage: "archivebox") { archive(goal) }
                Divider()
                Button(String(localized: "Delete Goal"), systemImage: "trash", role: .destructive) { confirmDelete = goal }
            }
            .scrollTransition(.animated(.spring(response: 0.5, dampingFraction: 0.8))) { content, phase in
                content
                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
                    .opacity(phase.isIdentity ? 1 : 0.55)
                    .offset(y: phase.value * 14)
            }
            .transition(.scale(scale: 0.92).combined(with: .opacity))
    }

    private func open(_ goal: Goal) {
        Haptics.soft(0.45)
        path.append(goal)
    }

    private func archive(_ goal: Goal) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { goal.isArchived.toggle() }
        SovaRefresh.changed(context)
        Haptics.pop(0.5, sound: true)
        let archived = goal.isArchived
        router.show(Toast(message: archived ? String(localized: "Archived “\(goal.title)”")
                                            : String(localized: "Back in progress")) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { goal.isArchived = !archived }
            SovaRefresh.changed(context)
        })
    }
}

// MARK: - The season

/// The season on indigo: the average, the next deadline, and the biggest
/// goals as rings around the owl, each in its own color.
private struct SeasonStage: View {
    let goals: [Goal]
    let achieved: Int

    @State private var grown = false
    @State private var owlTaps = 0
    @State private var secret = 0
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var average: Double {
        goals.isEmpty ? (achieved > 0 ? 1 : 0) : goals.map(\.progress).reduce(0, +) / Double(goals.count)
    }

    /// The goal with the nearest deadline that's still ahead or overdue.
    private var nextDeadline: Goal? {
        goals.filter { $0.deadline != nil }.min { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    private var ringed: [Goal] {
        Array(goals.sorted { $0.progress > $1.progress }.prefix(3))
    }

    var body: some View {
        let tone = StickerTone.indigo
        HStack(alignment: .center, spacing: 16) {
            GoalRings(goals: ringed, grown: grown, size: 112) {
                OwlMark(size: 40, happy: average >= 0.5 || owlTaps > 0,
                        bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly,
                        celebrate: secret, reactsToTap: false)
                    .onTapGesture(perform: pokeOwl)
            }
            .overlay { SparkleBurst(trigger: secret, radius: CGSize(width: 120, height: 110), count: 14) }

            VStack(alignment: .leading, spacing: 3) {
                MonoCaps(String(localized: "This season"), color: tone.deep)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Int((average * 100).rounded()), format: .number)
                        .font(.hero(54, weight: .heavy))
                        .tracking(-2.6)
                        .contentTransition(.numericText(value: average))
                    Text("%").font(.hero(24, weight: .heavy)).opacity(0.6)
                }
                .foregroundStyle(tone.deep)
                Text(goals.count == 1 ? String(localized: "on your goal")
                     : String(localized: "average across \(goals.count) goals"))
                    .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                    .foregroundStyle(Color.white.opacity(0.7))
                if let goal = nextDeadline, let text = goal.deadlineText {
                    TiltPill(text: "⏳ " + goal.title + " · " + text,
                             tone: (goal.daysLeft ?? 99) <= 7 ? .pink : .yellow, tilt: -3, size: 12)
                        .lineLimit(1)
                        .padding(.top, 6)
                } else if achieved > 0 {
                    TiltPill(text: String(localized: "\(achieved) achieved 🏆"), tone: .mint, tilt: 3, size: 12)
                        .padding(.top, 6)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background {
            ZStack {
                tone.fill
                SparkleDot(color: StickerTone.pink.fill, size: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 150).padding(.top, 22)
                SparkleDot(color: StickerTone.mint.fill, size: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 26).padding(.bottom, 22)
            }
        }
        .clipShape(.rect(cornerRadius: Radius.hero, style: .continuous))
        .shadow(color: StickerTone.indigo.shadow, radius: 18, y: 10)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 1.0, dampingFraction: 0.8).delay(0.1)) { grown = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "This season"))
        .accessibilityValue(String(localized: "\(Int((average * 100).rounded())) percent average across \(goals.count) goals"))
    }

    /// A small secret: poke the owl five times for a pep talk and sparkles.
    private func pokeOwl() {
        owlTaps += 1
        Haptics.owl()
        if owlTaps == 5 {
            owlTaps = 0
            secret += 1
            Haptics.celebrate()
            router.show(Toast(message: String(localized: "Hoo! Big goals look good on you. 🦉")))
        }
    }
}

/// Up to three goals as nested rings, like a target, around a center view.
struct GoalRings<Center: View>: View {
    let goals: [Goal]
    let grown: Bool
    var size: CGFloat = 128
    @ViewBuilder var center: Center

    var body: some View {
        let line: CGFloat = 11
        let gap: CGFloat = 4
        ZStack {
            ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                let tone = StickerTone(goal.accent)
                let color = tone == .indigo ? StickerTone.lilac.fill : tone.fill
                let inset = CGFloat(index) * (line + gap) + line / 2
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: line)
                    .padding(inset)
                Circle()
                    .trim(from: 0, to: grown ? max(0.001, goal.progress) : 0.001)
                    .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(inset)
                    .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(Double(index) * 0.08), value: grown)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goal.progress)
            }
            if goals.isEmpty {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: line).padding(line / 2)
            }
            center
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Filters

enum GoalFilter: Hashable, CaseIterable {
    case all, dueSoon, almostThere, justStarted, noDeadline

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .dueSoon: String(localized: "Due soon")
        case .almostThere: String(localized: "Almost there")
        case .justStarted: String(localized: "Just started")
        case .noDeadline: String(localized: "No deadline")
        }
    }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .dueSoon: "hourglass"
        case .almostThere: "flame.fill"
        case .justStarted: "leaf.fill"
        case .noDeadline: "infinity"
        }
    }

    var tone: StickerTone {
        switch self {
        case .all: .indigo
        case .dueSoon: .pink
        case .almostThere: .orange
        case .justStarted: .mint
        case .noDeadline: .lilac
        }
    }

    func matches(_ goal: Goal) -> Bool {
        switch self {
        case .all: true
        case .dueSoon: (goal.daysLeft ?? .max) <= 14
        case .almostThere: goal.progress >= 0.7
        case .justStarted: goal.progress < 0.25
        case .noDeadline: goal.deadline == nil
        }
    }

    static func counts(in goals: [Goal]) -> [GoalFilter: Int] {
        var counts: [GoalFilter: Int] = [:]
        for goal in goals {
            for filter in allCases where filter.matches(goal) { counts[filter, default: 0] += 1 }
        }
        return counts
    }
}

private struct GoalFilterChips: View {
    @Binding var selection: GoalFilter
    let counts: [GoalFilter: Int]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(GoalFilter.allCases, id: \.self) { filter in
                    let on = selection == filter
                    let n = counts[filter] ?? 0
                    if filter == .all || n > 0 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selection = on && filter != .all ? .all : filter
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filter.symbol)
                                    .font(.system(size: 12, weight: .heavy))
                                    .symbolEffect(.bounce, value: on)
                                Text(filter.title)
                                    .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                                Text("\(n)")
                                    .font(.allo(size: 12, weight: .heavy).monospacedDigit())
                                    .opacity(0.6)
                            }
                            .foregroundStyle(on ? (filter.tone == .indigo ? Color.white : filter.tone.deep) : Color.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(on ? filter.tone.fill : Color.surface, in: .capsule)
                            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: on ? 0 : 1.5))
                        }
                        .buttonStyle(.pressable)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .sovaFeedback(.selection, trigger: selection)
    }
}

// MARK: - Achieved

/// A finished goal as a small trophy sticker, ready to archive.
private struct TrophyRow: View {
    let goal: Goal
    var archived = false
    let onOpen: () -> Void
    let onArchive: () -> Void

    var body: some View {
        let tone = StickerTone(goal.accent)
        HStack(spacing: 12) {
            ZStack {
                StarburstShape(points: 12)
                    .fill(archived ? Color.well : tone.fill)
                    .frame(width: 48, height: 48)
                Image(systemName: archived ? goal.symbol : "trophy.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(archived ? Color.inkSecondary : (tone == .indigo ? Color.white : tone.deep))
            }
            .rotationEffect(.degrees(-8))
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.3)
                    .foregroundStyle(archived ? Color.inkSecondary : Color.ink)
                    .lineLimit(1)
                Text(archived ? String(localized: "\(Int((goal.progress * 100).rounded()))% · archived")
                              : String(localized: "Achieved · \(goal.steps.count) steps"))
                    .font(.allo(.footnote, .bold))
                    .foregroundStyle(Color.inkTertiary)
            }
            Spacer(minLength: 6)
            Button(action: onArchive) {
                Image(systemName: archived ? "tray.and.arrow.up.fill" : "archivebox.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.well, in: .circle)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(archived ? String(localized: "Unarchive") : String(localized: "Archive"))
        }
        .padding(12)
        .cardBackground()
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Short, honest encouragement from the owl, for anyone who pulls to refresh.
enum OwlPepTalk {
    static let all = [
        String(localized: "🦉 One step today beats ten someday."),
        String(localized: "🦉 Small steps still move the ring."),
        String(localized: "🦉 Break it down until the next step feels easy."),
        String(localized: "🦉 Progress, not perfect. Hoo!"),
        String(localized: "🦉 The owl believes in you. Quietly, but a lot."),
    ]

    static func random() -> String { all.randomElement() ?? all[0] }
}
