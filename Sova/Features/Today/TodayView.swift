import SwiftUI
import SwiftData
import TipKit
import StoreKit

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @AppStorage("userName") private var userName = ""
    @Environment(WaveDirector.self) private var waves
    @Environment(\.requestReview) private var requestReview
    @State private var showSettings = false
    /// Finished parts of the day you've unfolded again.
    @State private var expanded: Set<DaySection> = []

    private let captureTip = QuickCaptureTip()
    private let swipeTip = SwipeTip()

    private var greeting: String { Self.greeting(for: userName) }

    static func greeting(for name: String) -> String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return name.isEmpty ? base : base + ", " + name
    }

    /// The whole day is done: once a day, a ring wave from the owl carries
    /// Today into the day's summary. The rating prompt waits until it closes.
    private func dayComplete(from owl: CGRect, summary: DaySummary) {
        let defaults = UserDefaults.standard
        let today = Date.now.startOfDay
        let shown = (defaults.object(forKey: SovaSettings.Key.dayCompleteShown) as? Date).map { $0 >= today } ?? false
        guard !shown, !waves.isActive else { return askForReviewIfDue() }
        defaults.set(today, forKey: SovaSettings.Key.dayCompleteShown)
        Task { @MainActor in
            // Let the ring close and the owl hop first.
            try? await Task.sleep(for: .milliseconds(700))
            let started = waves.play(.dayDone(summary), from: owl, afterDismiss: {
                askForReviewIfDue(after: .milliseconds(600))
            })
            if !started { askForReviewIfDue() }
        }
    }

    private func askForReviewIfDue(after delay: Duration = .seconds(2.5)) {
        guard ReviewPrompt.shouldAskAfterCelebration() else { return }
        Task {
            try? await Task.sleep(for: delay)
            requestReview()
        }
    }

    private func next(in entries: [TimelineEntry]) -> TimelineEntry? {
        // A high-priority task that slipped past its time goes first.
        if let urgent = entries.first(where: { entry in
            if !entry.isDone, entry.section == .overdue, case .task(let task) = entry.source, task.priority == .high { return true }
            return false
        }) {
            return urgent
        }
        let open = entries.filter { !$0.isDone && $0.section != .overdue }
        if let timed = open.filter({ ($0.dueTime ?? .distantPast) >= .now })
            .min(by: { ($0.dueTime ?? .distantFuture) < ($1.dueTime ?? .distantFuture) }) {
            return timed
        }
        return open.first(where: { $0.section.rawValue >= DaySection.current.rawValue }) ?? open.first
    }

    var body: some View {
        let entries = TimelineEntry.build(tasks: tasks, routines: routines)
        let done = entries.filter(\.isDone)
        let upNext = next(in: entries)
        let todaysRituals = routines.filter { $0.isScheduled(on: .now) }
        let ritualsDone = todaysRituals.filter { $0.isDone(on: .now) }.count
        let taskEntries = entries.filter { !$0.isRoutine }
        let doneTasks = taskEntries.filter(\.isDone)
        let streak = routines.map(\.streak).max() ?? 0
        let timeline = Self.timelineItems(taskEntries, expanded: expanded)
        let openTaskCount = taskEntries.filter { !$0.isDone }.count
        let upcoming = tasks.filter { !$0.isDone && ($0.dueDate.map { $0 >= Date.now.endOfDay } ?? false) }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        NavigationStack {
            List {
                ScreenTitle(title: String(localized: "Today"),
                            subtitle: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                    HStack(spacing: 8) {
                        CircleAction(symbol: "magnifyingglass", label: String(localized: "Search")) { router.sheet = .search }
                        CircleAction(symbol: "plus", label: String(localized: "New task")) { router.sheet = .quickTask }
                        CircleAction(symbol: "gearshape", label: String(localized: "Settings")) { showSettings = true }
                    }
                }
                .cardRow(top: 4, bottom: 14)

                DayHeaderCard(greeting: greeting, done: done.count, total: entries.count, streak: streak) { owl in
                    dayComplete(from: owl, summary: DaySummary(tasks: doneTasks.count, rituals: ritualsDone,
                                                               streak: streak))
                }
                .cardRow(bottom: 6)

                // The owl's line about your day, from what's actually going on.
                Text(DayBriefing.line(tasks: tasks, routines: routines, goals: goals))
                    .font(.allo(size: 15, weight: .bold, relativeTo: .subheadline))
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 6)
                    .contentTransition(.opacity)
                    .cardRow(bottom: 12)

                TipView(captureTip).cardRow(bottom: 8)
                if !entries.isEmpty { TipView(swipeTip).cardRow(bottom: 8) }

                if entries.isEmpty {
                    EmptyState(title: String(localized: "Nothing planned"),
                               message: String(localized: "Add a task, or set up a ritual you want to keep."),
                               actionTitle: String(localized: "New task")) { router.sheet = .quickTask }
                        .cardRow(top: 4)
                }

                if let upNext {
                    UpNextCard(entry: upNext) { open(upNext) }
                        .cardRow(top: 6, bottom: 6)
                }

                if !todaysRituals.isEmpty {
                    HStack {
                        StickerHeader(title: String(localized: "Rituals"), symbol: "repeat", tone: .mint,
                                      count: todaysRituals.count - ritualsDone)
                    }
                    .cardRow(top: 18, bottom: 10)

                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(Array(todaysRituals.enumerated()), id: \.element.id) { index, ritual in
                                RitualCard(routine: ritual, tilt: index.isMultiple(of: 2) ? -2 : 2) {
                                    router.sheet = .routine(ritual)
                                }
                            }
                        }
                        .readablePadding(16)
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if !timeline.isEmpty {
                    StickerHeader(title: String(localized: "Your day"), symbol: "clock.fill", tone: .yellow,
                                  count: openTaskCount)
                        .cardRow(top: 18, bottom: 2)

                    ForEach(timeline) { item in
                        switch item {
                        case .header(let section, let done, let total):
                            TimelineSectionHeader(section: section, done: done, total: total)
                                .cardRow(top: 14, bottom: 6)
                        case .folded(let section, let count):
                            FoldedSection(section: section, count: count) {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { _ = expanded.insert(section) }
                                Haptics.soft(0.4)
                            }
                            .cardRow(top: 10, bottom: 2)
                        case .now:
                            NowMarker().cardRow(top: 8, bottom: 8)
                        case .row(let entry):
                            timelineRow(entry, isNext: entry.id == upNext?.id)
                        }
                    }
                }

                if let first = upcoming.first {
                    ComingUpCard(count: upcoming.count, next: first) { router.tab = .tasks }
                        .cardRow(top: 22, bottom: 4)
                }

                Color.clear.frame(height: 80).cardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .readableMargins()
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .refreshable {
                // Pull down and the owl says something nice about your day.
                await MainActor.run { Haptics.owl() }
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run { router.show(Toast(message: "🦉 " + DayBriefing.line(tasks: tasks, routines: routines, goals: goals))) }
            }
            .task {
                for await status in captureTip.statusUpdates {
                    if case .invalidated = status { SwipeTip.isReady = true }
                }
            }
        }
    }

    @ViewBuilder
    private func timelineRow(_ entry: TimelineEntry, isNext: Bool) -> some View {
        let base = TimelineRow(time: entry.dueTime, done: entry.isDone, isNext: isNext) {
            DayRow(entry: entry, showsTime: false) { open(entry) }
        }
        .cardRow(top: 3, bottom: 3)
        .transition(.opacity.combined(with: .move(edge: .top)))
        if case .task(let task) = entry.source {
            base.taskSwipeActions(task)
        } else {
            base
        }
    }

    /// The day's tasks as a timeline: a header per part of the day, a Now
    /// marker where you are, and finished past parts folded to one line.
    static func timelineItems(_ entries: [TimelineEntry], expanded: Set<DaySection>) -> [TimelineItem] {
        let now = Date.now
        let current = DaySection.current
        let present = DaySection.allCases.filter { section in entries.contains { $0.section == section } }
        let timed: Set<DaySection> = [.morning, .afternoon, .evening]
        let hasTimed = present.contains { timed.contains($0) }
        var items: [TimelineItem] = []
        var placedNow = !hasTimed
        for section in present {
            let rows = entries.filter { $0.section == section }
            if !placedNow && (section == .anytime || (timed.contains(section) && section.rawValue > current.rawValue)) {
                items.append(.now)
                placedNow = true
            }
            let done = rows.filter(\.isDone).count
            let finishedPast = done == rows.count && timed.contains(section) && section.rawValue < current.rawValue
            if finishedPast && !expanded.contains(section) {
                items.append(.folded(section, rows.count))
                continue
            }
            items.append(.header(section, done, rows.count))
            for row in rows {
                if !placedNow && section == current, let time = row.dueTime, time > now {
                    items.append(.now)
                    placedNow = true
                }
                items.append(.row(row))
            }
            if !placedNow && section == current {
                items.append(.now)
                placedNow = true
            }
        }
        if !placedNow { items.append(.now) }
        return items
    }

    @ViewBuilder
    private func row(_ entry: TimelineEntry) -> some View {
        let base = DayRow(entry: entry) { open(entry) }
            .cardRow(top: 4, bottom: 4)
        if case .task(let task) = entry.source {
            base.taskSwipeActions(task)
        } else {
            base
        }
    }

    private func open(_ entry: TimelineEntry) {
        switch entry.source {
        case .task(let t): router.sheet = .task(t)
        case .routine(let r): router.sheet = .routine(r)
        }
    }
}

extension View {
    /// A List row with no chrome and standard side margins.
    func cardRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        readableRow(top: top, bottom: bottom)
    }
}

/// What's planned after today, as one card that opens the Tasks tab.
struct ComingUpCard: View {
    let count: Int
    let next: TaskItem
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(StickerTone.lilac.deep)
                    .frame(width: 46, height: 46)
                    .background(StickerTone.lilac.fill, in: .rect(cornerRadius: 15, style: .continuous))
                    .rotationEffect(.degrees(-5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 1 ? String(localized: "1 task coming up") : String(localized: "\(count) tasks coming up"))
                        .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                        .tracking(-0.3)
                        .foregroundStyle(Color.ink)
                    Text(String(localized: "Next: \(next.title), \((next.dueDate ?? .now).relativeDayText(includingTime: next.hasTime))"))
                        .font(.allo(.footnote, .bold))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.inkTertiary)
            }
            .padding(14)
            .cardBackground()
        }
        .buttonStyle(.pressable)
        .accessibilityHint(String(localized: "Opens Tasks"))
    }
}

/// The day on an indigo stage: the owl inside a ring that fills as you
/// finish things, with today's numbers floating as stickers.
struct DayStage: View {
    let greeting: String
    let done: Int
    let total: Int
    let streak: Int
    /// Called with the owl's place on screen when the last thing of the day
    /// is ticked. Without it, the stage asks for a rating itself.
    var onDayComplete: ((CGRect) -> Void)? = nil

    @Environment(\.requestReview) private var requestReview

    @State private var cheers = 0
    @State private var owlFrame: CGRect = .zero

    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                StickerTone.indigo.fill

                // Progress ring around the owl.
                ZStack {
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 15)
                    Circle()
                        .trim(from: 0, to: max(0.001, progress))
                        .stroke(StickerTone.yellow.fill, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .opacity(progress > 0 ? 1 : 0)
                }
                .frame(width: 172, height: 172)
                .position(x: w / 2, y: h * 0.56)
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)

                SparkleBurst(trigger: cheers)
                    .position(x: w / 2, y: h * 0.56)

                OwlMark(size: 84, happy: total > 0 && done == total,
                        bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly,
                        celebrate: cheers)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { owlFrame = $0 }
                    .position(x: w / 2, y: h * 0.57)

                MonoCaps(greeting, color: StickerTone.indigo.deep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .position(x: w / 2, y: 26)

                TiltPill(text: total == 0 ? String(localized: "A clear day")
                         : String(localized: "\(done) of \(total) done"), tone: .yellow, tilt: -6)
                    .contentTransition(.numericText(value: Double(done)))
                    .position(x: w * 0.2, y: h * 0.66)
                if streak > 1 {
                    TiltPill(text: String(localized: "\(streak)-day streak"), tone: .mint, tilt: 6)
                        .position(x: w * 0.8, y: h * 0.44)
                }

                SparkleDot(color: StickerTone.pink.fill, size: 18).position(x: w * 0.9, y: h * 0.82)
                SparkleDot(color: StickerTone.mint.fill, size: 15).position(x: w * 0.14, y: h * 0.36)
                SparkleDot(color: StickerTone.yellow.fill, size: 12).position(x: w * 0.84, y: h * 0.16)
            }
        }
        .frame(height: 250)
        .clipShape(.rect(cornerRadius: Radius.hero, style: .continuous))
        .shadow(color: StickerTone.indigo.shadow, radius: 18, y: 10)
        .onChange(of: done) { old, new in
            // The last thing of the day: the owl hops, sparkles burst, and a
            // rolling haptic plays.
            if total > 0, new == total, old < total {
                cheers += 1
                Haptics.celebrate()
                if let onDayComplete {
                    onDayComplete(owlFrame)
                } else if ReviewPrompt.shouldAskAfterCelebration() {
                    Task {
                        try? await Task.sleep(for: .seconds(2.5))
                        requestReview()
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(greeting)
        .accessibilityValue(String(localized: "\(done) of \(total) done"))
    }
}

/// The one thing to do next: a yellow block with big buttons.
struct UpNextCard: View {
    let entry: TimelineEntry
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router
    private let tone = StickerTone.yellow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(label, color: tone.deep)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if case .task(let t) = entry.source, !t.priority.marks.isEmpty {
                    Text(t.priority.marks).foregroundStyle(Color.ember)
                }
                Text(title).foregroundStyle(StickerTone.indigo.fill)
            }
            .font(.allo(size: 26, weight: .heavy, relativeTo: .title2))
            .tracking(-0.8)
            .padding(.top, 8)
            if let meta {
                Text(meta)
                    .font(.allo(.subheadline, .heavy))
                    .opacity(0.7)
                    .padding(.top, 4)
            }
            HStack(spacing: 8) {
                Button(action: complete) {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(.big(.indigo, height: 50))
                .layoutPriority(1)
                if case .task(let t) = entry.source {
                    Button {
                        TaskActions.moveToTomorrow(t, router: router)
                    } label: {
                        Text("Tomorrow")
                            .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                            .foregroundStyle(tone.deep)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(tone.deep.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.top, 16)
        }
        .block(tone, cornerRadius: 32)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
    }

    private var title: String {
        switch entry.source {
        case .task(let t): t.title
        case .routine(let r): r.title
        }
    }

    private var meta: String? {
        var parts: [String] = []
        if let due = entry.dueTime { parts.append(due.formatted(date: .omitted, time: .shortened)) }
        switch entry.source {
        case .task(let t):
            if let goal = t.goal { parts.append(goal.title) } else if !t.notes.isEmpty { parts.append(t.notes) }
        case .routine(let r):
            parts.append(r.streak > 1 ? String(localized: "Ritual · \(r.streak)-day streak") : String(localized: "Ritual"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var label: String {
        guard let due = entry.dueTime, due > .now else {
            return entry.section == .overdue ? String(localized: "Overdue · first things first") : String(localized: "Up next")
        }
        let minutes = Int(due.timeIntervalSinceNow / 60)
        if minutes < 60 { return String(localized: "Up next · in \(max(minutes, 1)) min") }
        return minutes < 12 * 60 ? String(localized: "Up next · in \(minutes / 60) h") : String(localized: "Up next")
    }

    private func complete() {
        Haptics.success()
        Sounds.play(.check)
        switch entry.source {
        case .task(let t): TaskActions.toggle(t, router: router)
        case .routine(let r):
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { r.advance(on: .now) }
        }
    }
}

/// A ritual as a square, slightly tilted tile in its color.
struct RitualCard: View {
    let routine: Routine
    var tilt: Double = 0
    var onOpen: () -> Void

    @State private var wiggle = 0

    /// The tile's content: icon and check, the name, and a count or tag.
    private func tile(tone: StickerTone, ink: Color, done: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: routine.symbol)
                    .font(.system(size: 24, weight: .semibold))
                Spacer()
                check(tone: tone, done: done)
                    .padding(-7)
            }
            Spacer(minLength: 8)
            Text(routine.title)
                .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                .tracking(-0.4)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if routine.isCounted && !done {
                Text("\(routine.tally(on: .now)) / \(routine.target)")
                    .font(.allo(size: 12, weight: .heavy, relativeTo: .caption2).monospacedDigit())
                    .opacity(0.7)
                    .padding(.top, 2)
            } else if !done && routine.isSlipping {
                SlippingTag(ink: ink)
                    .padding(.top, 4)
            }
        }
    }

    var body: some View {
        let tone: StickerTone = StickerTone(routine.accent)
        let ink: Color = tone == .indigo ? Color.white : tone.deep
        let done: Bool = routine.isDone(on: .now)
        let actionName: String = done ? String(localized: "Mark as not done") : String(localized: "Mark as done")
        tile(tone: tone, ink: ink, done: done)
            .foregroundStyle(ink)
            .padding(14)
            .frame(width: 132, height: 132, alignment: .topLeading)
            .background { tileBackground(tone) }
            .opacity(done ? 0.6 : 1)
            .wiggle(on: wiggle)
            .rotationEffect(.degrees(tilt))
            .contentShape(.rect)
            .onTapGesture(perform: onOpen)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: done)
            .accessibilityElement(children: .combine)
            .accessibilityAction(named: Text(actionName)) {
                withAnimation { routine.advance(on: .now) }
            }
    }

    @ViewBuilder
    private func check(tone: StickerTone, done: Bool) -> some View {
        if routine.isCounted {
            CountCheck(routine: routine, ink: tone.deep, fill: tone.fill, size: 30, action: advance)
        } else {
            CheckButton(isOn: done, color: tone.deep, round: true, size: 30, checkColor: tone.fill,
                        label: routine.title, action: advance)
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { routine.advance(on: .now) }
        if routine.isDone(on: .now) { wiggle += 1 }
    }

    @ViewBuilder
    private func tileBackground(_ tone: StickerTone) -> some View {
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        shape.fill(tone.fill.shadow(.drop(color: tone.shadow, radius: 12, y: 7)))
        shape.fill(LinearGradient(colors: [Color.white.opacity(0.24), .clear], startPoint: .top, endPoint: .center))
        shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.55), .clear],
                                          startPoint: .top, endPoint: .center), lineWidth: 1.2)
    }
}

/// A task as a white card.
struct DayRow: View {
    let entry: TimelineEntry
    var showsTime = true
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        if case .task(let t) = entry.source {
            HStack(spacing: 10) {
                CheckButton(isOn: entry.isDone, color: Color.ink, round: false, size: 30, label: t.title, action: toggle)
                    .padding(.leading, -6)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        if !t.priority.marks.isEmpty && !t.isDone {
                            Text(t.priority.marks).foregroundStyle(Color.ember)
                        }
                        Text(t.title).foregroundStyle(t.isDone ? Color.inkTertiary : Color.ink)
                    }
                    .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                    .lineLimit(2)
                    Text(meta(t))
                        .font(.allo(.footnote, .bold))
                        .foregroundStyle(entry.section == .overdue && !t.isDone ? Color.ember : Color.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                if !t.checklist.isEmpty && !t.isDone {
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                        Text("\(t.checklistDone)/\(t.checklist.count)").monospacedDigit()
                    }
                    .font(.allo(size: 12, weight: .heavy, relativeTo: .caption2))
                    .foregroundStyle(t.checklistDone == t.checklist.count ? Color.positive : Color.inkTertiary)
                    .accessibilityLabel(String(localized: "\(t.checklistDone) of \(t.checklist.count) steps"))
                }
                if t.repeatRule != .none && !t.isDone {
                    Image(systemName: "repeat")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.inkTertiary)
                        .accessibilityLabel(t.repeatRule.label)
                }
                if showsTime, let time = time(t) {
                    Text(time)
                        .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline).monospacedDigit())
                        .foregroundStyle(t.isOverdue ? Color.ember : Color.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.surfaceMuted, in: .rect(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
            .padding(.vertical, 9)
            .cardBackground()
            .contentShape(.rect)
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .combine)
            .accessibilityAction(named: entry.isDone ? "Mark as not done" : "Mark as done", toggle)
        }
    }

    private func meta(_ t: TaskItem) -> String {
        if entry.section == .overdue, let due = t.dueDate {
            return String(localized: "Was due \(due.formatted(.dateTime.month(.abbreviated).day()))")
        }
        return t.goal?.title ?? (t.notes.isEmpty ? String(localized: "Task") : t.notes)
    }

    private func time(_ t: TaskItem) -> String? {
        if t.isDone, let done = t.completedAt { return done.formatted(date: .omitted, time: .shortened) }
        if t.hasTime, let due = t.dueDate { return due.formatted(date: .omitted, time: .shortened) }
        return nil
    }

    private func toggle() {
        if case .task(let t) = entry.source { TaskActions.toggle(t, router: router) }
    }
}

#Preview {
    TodayView()
        .environment(AppRouter())
        .environment(WaveDirector())
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}

/// Small, kind lines from the owl, for anyone who pulls down on Today.
enum OwlMorningLines {
    static let all = [
        String(localized: "🦉 One thing at a time. You've got this."),
        String(localized: "🦉 Tip: swipe a task right to finish it, left to move it."),
        String(localized: "🦉 Hoo! Drink some water. The owl insists."),
        String(localized: "🦉 Done is better than perfect."),
        String(localized: "🦉 Tip: long-press the Sova icon for quick actions."),
        String(localized: "🦉 Tip: type “every Monday” and a task repeats."),
    ]

    static func random() -> String { all.randomElement() ?? all[0] }
}

/// One line of Today's timeline.
enum TimelineItem: Identifiable {
    case header(DaySection, Int, Int)
    case folded(DaySection, Int)
    case row(TimelineEntry)
    case now

    var id: String {
        switch self {
        case .header(let section, _, _): "h\(section.rawValue)"
        case .folded(let section, _): "f\(section.rawValue)"
        case .row(let entry): entry.id
        case .now: "now"
        }
    }
}
