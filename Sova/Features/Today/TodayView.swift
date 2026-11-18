import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt) private var goals: [Goal]
    @AppStorage("theme") private var themeRaw = AuroraTheme.aurora.rawValue
    @State private var showCompleted = false

    private var theme: AuroraTheme { AuroraTheme(rawValue: themeRaw) ?? .aurora }

    // MARK: Derived data

    private var dueTasks: [TaskItem] {
        tasks.filter { !$0.isDone && $0.isDueTodayOrEarlier }.sorted(by: TaskItem.ordering)
    }

    private var upcomingTasks: [TaskItem] {
        tasks.filter { !$0.isDone && !$0.isDueTodayOrEarlier }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var completedToday: [TaskItem] {
        tasks.filter { $0.isDone && ($0.completedAt?.isSameDay(as: .now) ?? false) }
            .sorted { ($0.completedAt ?? .now) > ($1.completedAt ?? .now) }
    }

    private var todaysRoutines: [Routine] { routines.filter { $0.isScheduled(on: .now) } }
    private var routinesDone: Int { todaysRoutines.filter { $0.isDone(on: .now) }.count }

    private var dayTotal: Int { dueTasks.count + completedToday.count + todaysRoutines.count }

    private var dayProgress: Double {
        guard dayTotal > 0 else { return 0 }
        return Double(completedToday.count + routinesDone) / Double(dayTotal)
    }

    private var spotlightGoal: Goal? {
        goals.filter { $0.progress < 1 }
            .min { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Good night")
        }
    }

    private var heroMessage: String {
        if dayTotal == 0 { return String(localized: "A calm, open day.") }
        switch dayProgress {
        case 0: return String(localized: "Let's get the day moving.")
        case ..<0.5: return String(localized: "Nice start. Keep going.")
        case ..<1: return String(localized: "Almost there!")
        default: return String(localized: "All done. Breathe.")
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heroCard
                    if !todaysRoutines.isEmpty { routinesStrip }
                    tasksSection
                    if let goal = spotlightGoal { goalSpotlight(goal) }
                    if !upcomingTasks.isEmpty { upcomingSection }
                    if !completedToday.isEmpty { completedSection }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .animation(.snappy, value: tasks.map(\.isDone))
            }
            .scrollIndicators(.hidden)
            .background { AuroraBackground() }
            .navigationTitle(greeting)
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { ThemeMenu() }
            }
        }
    }

    private var heroCard: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: dayProgress, lineWidth: 12, colors: theme.ringColors)
                VStack(spacing: 0) {
                    Text(dayProgress, format: .percent.precision(.fractionLength(0)))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .contentTransition(.numericText(value: dayProgress))
                    Text("done")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 104, height: 104)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Day progress")

            VStack(alignment: .leading, spacing: 10) {
                Text(heroMessage)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                StatPill(symbol: "checklist", value: "\(dueTasks.count)",
                         label: String(localized: "tasks left"), tint: Accent.iris.color)
                StatPill(symbol: "repeat", value: "\(todaysRoutines.count - routinesDone)",
                         label: String(localized: "routines to go"), tint: Accent.lagoon.color)
            }
        }
        .card(tint: theme.tint, cornerRadius: 32, padding: 20)
        .animation(.snappy, value: dayProgress)
    }

    private var routinesStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Routines"), symbol: "repeat",
                          trailing: "\(routinesDone)/\(todaysRoutines.count)")
            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(todaysRoutines) { RoutineBubble(routine: $0) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Tasks"), symbol: "checklist",
                          trailing: dueTasks.isEmpty ? nil : String(localized: "\(dueTasks.count) left"))
            if dueTasks.isEmpty {
                EmptyCard(symbol: "checkmark.seal.fill",
                          title: String(localized: "All clear"),
                          message: String(localized: "Nothing due today. Add something, or enjoy the space."),
                          actionTitle: String(localized: "Add a Task")) { router.sheet = .newTask(nil) }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(dueTasks) { task in
                        TaskRow(task: task) { router.sheet = .task(task) }
                            .transition(.asymmetric(insertion: .scale(0.95).combined(with: .opacity),
                                                    removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }
            }
        }
    }

    private func goalSpotlight(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Focus Goal"), symbol: "target")
            Button {
                router.tab = .goals
            } label: {
                GoalCard(goal: goal)
            }
            .buttonStyle(.plain)
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: String(localized: "Upcoming"), symbol: "calendar",
                          trailing: "\(upcomingTasks.count)")
            LazyVStack(spacing: 10) {
                ForEach(upcomingTasks.prefix(6)) { task in
                    TaskRow(task: task) { router.sheet = .task(task) }
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) { showCompleted.toggle() }
            } label: {
                HStack {
                    SectionHeader(title: String(localized: "Completed"), symbol: "checkmark.circle",
                                  trailing: "\(completedToday.count)")
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showCompleted ? 0 : -90))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(showCompleted ? "Collapse" : "Expand")

            if showCompleted {
                LazyVStack(spacing: 10) {
                    ForEach(completedToday) { task in
                        TaskRow(task: task) { router.sheet = .task(task) }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
