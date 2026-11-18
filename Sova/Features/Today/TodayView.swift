import SwiftUI
import SwiftData
import TipKit
import StoreKit

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("userName") private var userName = ""
    @State private var showSettings = false
    @State private var showDone = false

    private let captureTip = QuickCaptureTip()
    private let swipeTip = SwipeTip()

    private var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return userName.isEmpty ? base : base + ", " + userName
    }

    private func next(in entries: [TimelineEntry]) -> TimelineEntry? {
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
        let openTasks = taskEntries.filter { !$0.isDone && $0.id != upNext?.id }
        let overdue = openTasks.filter { $0.section == .overdue }
        let later = openTasks.filter { $0.section != .overdue }
        let doneTasks = taskEntries.filter(\.isDone)
        let streak = routines.map(\.streak).max() ?? 0

        NavigationStack {
            List {
                ScreenTitle(title: String(localized: "Today"),
                            subtitle: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                    CircleAction(symbol: "gearshape", label: String(localized: "Settings")) { showSettings = true }
                }
                .cardRow(top: 4, bottom: 14)

                DayStage(greeting: greeting, done: done.count, total: entries.count, streak: streak)
                    .cardRow(bottom: 10)

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
                        .cardRow(top: 44, bottom: 6)
                }

                if !todaysRituals.isEmpty {
                    HStack {
                        SectionLabel(String(localized: "Rituals · \(ritualsDone) of \(todaysRituals.count)"))
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if !overdue.isEmpty {
                    SectionLabel(String(localized: "Overdue"), trailing: "\(overdue.count)", color: .ember)
                        .cardRow(top: 18, bottom: 10)
                    ForEach(overdue) { row($0) }
                }

                if !later.isEmpty {
                    SectionLabel(String(localized: "Tasks"), trailing: "\(later.count)")
                        .cardRow(top: 18, bottom: 10)
                    ForEach(later) { row($0) }
                }

                if !doneTasks.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDone.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            SectionLabel(String(localized: "Done today"), trailing: "\(doneTasks.count)")
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Color.inkTertiary)
                                .rotationEffect(.degrees(showDone ? 90 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .cardRow(top: 18, bottom: 10)
                    if showDone { ForEach(doneTasks) { row($0) } }
                }

                Color.clear.frame(height: 80).cardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .task {
                for await status in captureTip.statusUpdates {
                    if case .invalidated = status { SwipeTip.isReady = true }
                }
            }
        }
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
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

/// The day on an indigo stage: the owl inside a ring that fills as you
/// finish things, with today's numbers floating as stickers.
struct DayStage: View {
    let greeting: String
    let done: Int
    let total: Int
    let streak: Int

    @Environment(\.requestReview) private var requestReview

    @State private var cheers = 0

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
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8),
                        celebrate: cheers)
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
        .clipShape(.rect(cornerRadius: 36, style: .continuous))
        .onChange(of: done) { old, new in
            // The last thing of the day: the owl hops, sparkles burst, and a
            // rolling haptic plays.
            if total > 0, new == total, old < total {
                cheers += 1
                Haptics.celebrate()
                if ReviewPrompt.shouldAskAfterCelebration() {
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

/// The one thing to do next: a yellow block with big buttons, and the owl
/// perched on top pointing it out.
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
        .overlay(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 6) {
                Text("This one's next!")
                    .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                    .tracking(-0.3)
                    .foregroundStyle(StickerTone.lilac.deep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(StickerTone.lilac.fill,
                                in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18,
                                                           bottomTrailingRadius: 6, topTrailingRadius: 18,
                                                           style: .continuous))
                    .padding(.top, 14)
                OwlMark(size: 50, bodyColor: Color(hex: 0x2B1677), eyeColor: StickerTone.yellow.fill)
                    .rotationEffect(.degrees(6))
            }
            .offset(x: -12, y: -58)
            .allowsHitTesting(false)
        }
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
        guard let due = entry.dueTime, due > .now else { return String(localized: "Up next") }
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { r.toggle(on: .now) }
        }
    }
}

/// A ritual as a square, slightly tilted tile in its color.
struct RitualCard: View {
    let routine: Routine
    var tilt: Double = 0
    var onOpen: () -> Void

    @State private var wiggle = 0

    var body: some View {
        let tone = StickerTone(routine.accent)
        let ink = tone == .indigo ? Color.white : tone.deep
        let done = routine.isDone(on: .now)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: routine.symbol)
                    .font(.system(size: 24, weight: .semibold))
                Spacer()
                CheckButton(isOn: done, color: tone.deep, round: true, size: 30, checkColor: tone.fill,
                            label: routine.title) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { routine.toggle(on: .now) }
                    if routine.isDone(on: .now) { wiggle += 1 }
                }
                .padding(-7)
            }
            Spacer(minLength: 8)
            Text(routine.title)
                .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                .tracking(-0.4)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(ink)
        .padding(14)
        .frame(width: 132, height: 132, alignment: .topLeading)
        .background(tone.fill, in: .rect(cornerRadius: 30, style: .continuous))
        .opacity(done ? 0.6 : 1)
        // A happy wiggle when checked: a quick swell and a shake that settles.
        .keyframeAnimator(initialValue: 0.0, trigger: wiggle) { view, t in
            view.scaleEffect(1 + abs(t) * 0.012).rotationEffect(.degrees(t))
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(-5, duration: 0.09, spring: .snappy)
                SpringKeyframe(4, duration: 0.1, spring: .snappy)
                SpringKeyframe(-2, duration: 0.1, spring: .snappy)
                SpringKeyframe(0, duration: 0.3, spring: .bouncy)
            }
        }
        .rotationEffect(.degrees(tilt))
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: done)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: done ? "Mark as not done" : "Mark as done") {
            withAnimation { routine.toggle(on: .now) }
        }
    }
}

/// A task as a white card.
struct DayRow: View {
    let entry: TimelineEntry
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
                if t.repeatRule != .none && !t.isDone {
                    Image(systemName: "repeat")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.inkTertiary)
                        .accessibilityLabel(t.repeatRule.label)
                }
                if let time = time(t) {
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
            .background(Color.surface, in: .rect(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
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
        .modelContainer(for: [TaskItem.self, Goal.self, Milestone.self, Routine.self], inMemory: true)
}
