import SwiftUI
import SwiftData
import TipKit

struct RoutinesView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Routine.order) private var routines: [Routine]
    @State private var showResting = false

    var body: some View {
        let today = routines.filter { $0.isScheduled(on: .now) }
        let resting = routines.filter { !$0.isScheduled(on: .now) }
        let doneToday = today.filter { $0.isDone(on: .now) }.count
        let now = DayPeriod.now

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenTitle(title: String(localized: "Rituals"),
                                subtitle: routines.isEmpty ? String(localized: "Little things, every day")
                                    : String(localized: "\(doneToday) of \(today.count) today")) {
                        CircleAction(symbol: "plus", label: String(localized: "New ritual")) { router.sheet = router.newRoutineSheet }
                    }
                    .padding(.top, 4)

                    if routines.isEmpty {
                        EmptyState(title: String(localized: "No rituals yet"),
                                   message: String(localized: "Rituals are things you do on a schedule, like reading or a morning walk."),
                                   actionTitle: String(localized: "Add a ritual")) { router.sheet = router.newRoutineSheet }
                    } else {
                        WeekStage(routines: routines, done: doneToday, total: today.count)
                        TipView(RitualCountTip())

                        if today.isEmpty {
                            RestDayCard()
                        }

                        ForEach(DayPeriod.allCases) { period in
                            let items = today.filter { $0.period == period }
                            if !items.isEmpty {
                                let done = items.filter { $0.isDone(on: .now) }.count
                                VStack(alignment: .leading, spacing: 10) {
                                    PeriodHeader(period: period, done: done, total: items.count, isNow: period == now)
                                    VStack(spacing: 10) {
                                        ForEach(Array(items.enumerated()), id: \.element.id) { index, routine in
                                            RoutineRow(routine: routine) { router.sheet = .routine(routine) }
                                                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -0.5 : 0.5))
                                                .scrollTransition(.animated(.spring(response: 0.5, dampingFraction: 0.8))) { content, phase in
                                                    content
                                                        .scaleEffect(phase.isIdentity ? 1 : 0.95)
                                                        .opacity(phase.isIdentity ? 1 : 0.6)
                                                }
                                        }
                                    }
                                }
                            }
                        }

                        if !resting.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showResting.toggle() }
                                    Haptics.soft(0.4)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "moon.zzz.fill")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundStyle(StickerTone.lilac.deep)
                                            .frame(width: 28, height: 28)
                                            .background(StickerTone.lilac.fill, in: .rect(cornerRadius: 9, style: .continuous))
                                            .rotationEffect(.degrees(-6))
                                        SectionLabel(String(localized: "Resting today"), trailing: "\(resting.count)")
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.heavy))
                                            .foregroundStyle(Color.inkTertiary)
                                            .rotationEffect(.degrees(showResting ? 90 : 0))
                                        Spacer()
                                    }
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)

                                if showResting {
                                    VStack(spacing: 10) {
                                        ForEach(resting) { routine in
                                            RoutineRow(routine: routine) { router.sheet = .routine(routine) }
                                                .saturation(0.6)
                                                .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .refreshable {
                // Pull down for a habit tip from the owl.
                await MainActor.run { Haptics.owl() }
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run { router.show(Toast(message: OwlHabitTips.random())) }
            }
        }
    }
}

extension DayPeriod {
    /// The part of the day it is right now.
    static var now: DayPeriod {
        switch Calendar.current.component(.hour, from: .now) {
        case 4..<12: .morning
        case 12..<17: .afternoon
        default: .evening
        }
    }
}

/// Shown when nothing is scheduled today.
private struct RestDayCard: View {
    var body: some View {
        HStack(spacing: 14) {
            OwlMark(size: 54, happy: true, reactsToTap: false)
            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: "A rest day"))
                    .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                    .tracking(-0.4)
                    .foregroundStyle(StickerTone.lilac.deep)
                Text(String(localized: "Nothing scheduled today. Streaks don't break on rest days."))
                    .font(.allo(.subheadline, .semibold))
                    .foregroundStyle(StickerTone.lilac.deep.opacity(0.75))
            }
            Spacer(minLength: 0)
        }
        .block(.lilac, cornerRadius: 28, padding: 18)
    }
}

/// Gentle, honest habit tips, for anyone who pulls to refresh.
enum OwlHabitTips {
    static let all = [
        String(localized: "🦉 Tip: tie a ritual to something you already do, like after your morning coffee."),
        String(localized: "🦉 Tip: make it small enough that you can't say no. Two pages still counts."),
        String(localized: "🦉 Tip: missed a day? Just do the next one. Never miss twice."),
        String(localized: "🦉 Tip: put the book on your pillow, the shoes by the door. Make it easy to start."),
        String(localized: "🦉 Tip: fewer rituals, kept well, beat many kept sometimes."),
    ]

    static func random() -> String { all.randomElement() ?? all[0] }
}

/// This week on indigo: one fat column per day that fills with yellow as
/// rituals get done, the owl perched on today, and the best streak as a
/// mint starburst.
struct WeekStage: View {
    let routines: [Routine]
    let done: Int
    let total: Int

    @State private var cheers = 0
    @State private var owlTaps = 0
    @Environment(AppRouter.self) private var router

    private var days: [Date] {
        let today = Date.now.startOfDay
        let start = Calendar.sova.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).map { start.adding(days: $0) }
    }

    private func fraction(for day: Date) -> Double {
        let scheduled = routines.filter { $0.isScheduled(on: day) }
        guard !scheduled.isEmpty else { return 0 }
        return Double(scheduled.filter { $0.isDone(on: day) }.count) / Double(scheduled.count)
    }

    private var bestStreak: Int { routines.map(\.streak).max() ?? 0 }

    /// Days so far this week where every scheduled ritual got done.
    private var perfectDays: Int {
        let today = Date.now.startOfDay
        return days.filter { $0 <= today && fraction(for: $0) >= 1 }.count
    }

    /// A small secret: poke the owl five times.
    private func pokeOwl() {
        owlTaps += 1
        Haptics.owl()
        if owlTaps == 5 {
            owlTaps = 0
            cheers += 1
            Haptics.celebrate()
            router.show(Toast(message: String(localized: "Hoo! The owl does its rituals too. Mostly naps. 🦉")))
        }
    }

    var body: some View {
        let tone = StickerTone.indigo
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    MonoCaps(String(localized: "This week"), color: tone.deep)
                    Text(total == 0 ? String(localized: "A rest day")
                         : done == total ? String(localized: "All done today")
                         : String(localized: "\(total - done) left today"))
                        .font(.allo(size: 24, weight: .heavy, relativeTo: .title2))
                        .tracking(-0.6)
                        .foregroundStyle(Color.white)
                        .contentTransition(.numericText())
                    if perfectDays > 0 {
                        TiltPill(text: perfectDays == 1 ? String(localized: "1 perfect day ✨")
                                                        : String(localized: "\(perfectDays) perfect days ✨"),
                                 tone: .yellow, tilt: -4, size: 12)
                            .padding(.top, 6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Spacer(minLength: 0)
                if bestStreak > 1 {
                    Starburst(value: "\(bestStreak)", caption: String(localized: "day streak"),
                              tone: .mint, size: 74, tilt: 10)
                        .padding(.top, -8)
                        .padding(.trailing, -6)
                }
            }

            HStack(alignment: .bottom, spacing: 7) {
                ForEach(days, id: \.self) { day in
                    let isToday = day.isSameDay(as: .now)
                    let isFuture = day > Date.now && !isToday
                    let value = isFuture ? 0 : fraction(for: day)
                    VStack(spacing: 6) {
                        if isToday {
                            OwlMark(size: 34, happy: total > 0 && done == total,
                                    bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                                    pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8),
                                    celebrate: cheers)
                                .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 80, height: 60), count: 10) }
                                .onTapGesture(perform: pokeOwl)
                        } else {
                            Color.clear.frame(height: 34)
                        }
                        ZStack(alignment: .bottom) {
                            Capsule().fill(Color.white.opacity(isFuture ? 0.06 : 0.13))
                            Capsule()
                                .fill(StickerTone.yellow.fill)
                                .frame(height: value > 0 ? max(22, 84 * value) : 0)
                                .opacity(value > 0 ? 1 : 0)
                        }
                        .frame(height: 84)
                        .overlay {
                            if isToday {
                                Capsule().strokeBorder(StickerTone.yellow.fill, lineWidth: 2.5)
                            }
                        }
                        Text(Weekdays.letter(day.weekday))
                            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption2))
                            .foregroundStyle(isToday ? tone.deep : Color.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day()))
                    .accessibilityValue(isFuture ? String(localized: "Upcoming")
                                        : value.formatted(.percent.precision(.fractionLength(0))))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: done)
        }
        .padding(20)
        .background {
            ZStack {
                tone.fill
                SparkleDot(color: StickerTone.pink.fill, size: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 150).padding(.top, 18)
                SparkleDot(color: StickerTone.cyan.fill, size: 11)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 98).padding(.top, 54)
            }
        }
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .shadow(color: StickerTone.indigo.shadow, radius: 18, y: 10)
        .onChange(of: done) { old, new in
            if total > 0, new == total, old < total {
                cheers += 1
                Haptics.celebrate()
            }
        }
    }
}

/// A small tilted pill naming a part of the day, with its count.
private struct PeriodHeader: View {
    let period: DayPeriod
    let done: Int
    let total: Int
    var isNow = false

    private var tone: StickerTone {
        switch period {
        case .morning: .orange
        case .afternoon: .yellow
        case .evening: .lilac
        case .anytime: .cyan
        }
    }

    private var symbol: String {
        switch period {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        case .anytime: "sparkles"
        }
    }

    var body: some View {
        let allDone = total > 0 && done == total
        HStack(spacing: 10) {
            Label(period.name, systemImage: symbol)
                .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                .foregroundStyle(tone.deep)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(tone.fill, in: .capsule)
                .rotationEffect(.degrees(-3))
            if isNow && !allDone {
                HStack(spacing: 5) {
                    Circle().fill(StickerTone.pink.fill).frame(width: 7, height: 7)
                        .phaseAnimator([1.0, 0.35]) { dot, phase in dot.opacity(phase) } animation: { _ in .easeInOut(duration: 0.9) }
                    Text(String(localized: "NOW"))
                        .font(.allo(size: 11, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(StickerTone.pink.deep)
                }
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(StickerTone.pink.fill.opacity(0.25), in: .capsule)
                .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            if total > 0 {
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        ForEach(0..<total, id: \.self) { index in
                            Capsule()
                                .fill(index < done ? tone.fill : Color.ink.opacity(0.08))
                                .frame(width: 10, height: 6)
                        }
                    }
                    if allDone {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(tone == .yellow ? StickerTone.yellow.deep : tone.fill)
                            .symbolEffect(.bounce, value: allDone)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("\(done) of \(total)")
                            .font(.mono(13))
                            .foregroundStyle(Color.inkSecondary)
                            .contentTransition(.numericText())
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: done)
            }
        }
        .padding(.top, 6)
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isNow ? String(localized: "Now") : "")
    }
}
