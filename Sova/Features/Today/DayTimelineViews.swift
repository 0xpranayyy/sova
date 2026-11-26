import SwiftUI
import StoreKit

// Today, as your day: a compact card with the owl in its ring, then the
// day's tasks on a timeline (Morning, Afternoon, Evening, Anytime) with a
// Now marker, and finished parts of the day folded away.

/// The day at a glance on indigo: the owl inside a ring that fills as you
/// finish things, a greeting, the count and one segment per thing to do.
/// Celebrates when the last thing is ticked.
struct DayHeaderCard: View {
    let greeting: String
    let done: Int
    let total: Int
    let streak: Int
    /// Called with the owl's place on screen when the whole day is done.
    var onDayComplete: ((CGRect) -> Void)? = nil

    @Environment(\.requestReview) private var requestReview
    @State private var cheers = 0
    @State private var owlFrame: CGRect = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    private var allDone: Bool { total > 0 && done == total }

    /// "Good morning, Alex" split into the small line and the big name.
    private var parts: (hello: String, name: String?) {
        guard let comma = greeting.range(of: ", ") else { return (greeting, nil) }
        return (String(greeting[..<comma.lowerBound]), String(greeting[comma.upperBound...]))
    }

    private var statusLine: String {
        if total == 0 { return String(localized: "A clear day") }
        if allDone { return String(localized: "All done!") }
        return String(localized: "of \(total) done")
    }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            hero(part: DayPart.at(timeline.date))
        }
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

    private func hero(part: DayPart) -> some View {
        let harmony: Harmony = part.harmony
        return ZStack(alignment: .topLeading) {
            harmony.bg
            DayScene(part: part, harmony: harmony)
            heroText(part: part, harmony: harmony)
                .padding(.leading, 20)
                .padding(.top, 18)
            SegmentBar(done: done, total: total, fill: harmony.accent,
                       empty: harmony.isDark ? harmony.soft : harmony.top)
                .frame(width: 166)
                .padding(.leading, 20)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 22)
            owl(part: part)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 22)
                .padding(.bottom, 26)
        }
        .frame(height: 212)
        .clipShape(.rect(cornerRadius: Radius.hero, style: .continuous))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: part)
    }

    /// The owl on the hill: sleepy at night, happy when the day is done.
    private func owl(part: DayPart) -> some View {
        let sleepy: Bool = part.isNight && !allDone
        return OwlMark(size: 88, happy: allDone, blinks: !sleepy,
                       bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                       pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly,
                       celebrate: cheers, sleepy: sleepy)
            .shadow(color: Color(hex: 0x120840).opacity(0.18), radius: 5, y: 5)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { owlFrame = $0 }
            .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 120, height: 90)) }
    }

    private func heroText(part: DayPart, harmony: Harmony) -> some View {
        let name: String = parts.name ?? ""
        return VStack(alignment: .leading, spacing: 0) {
            MonoCaps(name.isEmpty ? String(localized: "Today") : part.greeting, color: harmony.mute)
                .lineLimit(1)
            nameLine(name.isEmpty ? part.greeting : name, harmony: harmony)
                .padding(.top, 4)
            HStack(alignment: .center, spacing: 8) {
                progressText(harmony: harmony)
                if streak > 1 { StreakSticker(streak: streak) }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 220, alignment: .leading)
    }

    /// The name with the yellow highlighter (by night, the name is yellow).
    @ViewBuilder
    private func nameLine(_ name: String, harmony: Harmony) -> some View {
        let dot = Text(".").foregroundStyle(harmony.isDark ? StickerTone.yellow.fill : harmony.accent)
        if harmony.isDark {
            Text("\(Text(name).foregroundStyle(StickerTone.yellow.fill))\(dot)")
                .font(.hero(34, weight: .heavy))
                .tracking(-1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            Text("\(Text(name).foregroundStyle(harmony.ink).customAttribute(MarkerAttribute()))\(dot)")
                .font(.hero(34, weight: .heavy))
                .tracking(-1.4)
                .textRenderer(MarkerRenderer(color: StickerTone.yellow.fill))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func progressText(harmony: Harmony) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            if total > 0 && !allDone {
                Text(done, format: .number)
                    .font(.hero(22, weight: .heavy))
                    .foregroundStyle(harmony.ink)
                    .contentTransition(.numericText(value: Double(done)))
            }
            Text(statusLine)
                .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                .foregroundStyle(allDone ? harmony.ink : harmony.mute)
                .lineLimit(1)
        }
    }

}

extension DaySection {
    var tone: StickerTone {
        switch self {
        case .overdue: .pink
        case .morning: .orange
        case .afternoon: .yellow
        case .evening: .lilac
        case .anytime: .lime
        }
    }

    var symbol: String {
        switch self {
        case .overdue: "exclamationmark.circle.fill"
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        case .anytime: "sparkles"
        }
    }
}

/// The time column, rail and dot that every timeline row sits on.
private struct Rail: View {
    var done = false
    var tone: StickerTone? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color.ink.opacity(0.08))
                .frame(width: 2)
                .padding(.vertical, -8)
            Circle()
                .fill(done ? StickerTone.mint.fill : (tone?.fill ?? Color.surface))
                .overlay(Circle().strokeBorder(done ? StickerTone.mint.deep : Color.ink.opacity(0.22), lineWidth: 2.5))
                .frame(width: 11, height: 11)
                .padding(.top, 21)
        }
        .frame(width: 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityHidden(true)
    }
}

/// A part of the day: a tilted colored tag and how much of it is done.
struct TimelineSectionHeader: View {
    let section: DaySection
    let done: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: 44 + 8 + 16)
            Label(section.title, systemImage: section.symbol)
                .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                .foregroundStyle(section.tone.deep)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(section.tone.fill, in: .capsule)
                .rotationEffect(.degrees(-3))
            Spacer()
            Text(done == total ? String(localized: "\(done) of \(total) ✓") : String(localized: "\(done) of \(total)"))
                .font(.allo(size: 12, weight: .heavy, relativeTo: .caption2).monospacedDigit())
                .foregroundStyle(done == total ? Color.positive : Color.inkTertiary)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A finished part of the day, folded to one line. Tap to open it again.
struct FoldedSection: View {
    let section: DaySection
    let count: Int
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 8) {
                Color.clear.frame(width: 44 + 8 + 16)
                HStack(spacing: 8) {
                    Image(systemName: section.symbol)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(section.tone.deep)
                        .frame(width: 24, height: 24)
                        .background(section.tone.fill, in: .circle)
                    Text(section.title)
                        .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                        .foregroundStyle(Color.ink)
                    Text(String(localized: "· all \(count) done"))
                        .font(.allo(size: 14, weight: .bold, relativeTo: .subheadline))
                        .foregroundStyle(Color.inkSecondary)
                    Spacer(minLength: 4)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.positive)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color.inkTertiary)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.surface.opacity(0.7), in: .capsule)
                .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1.5))
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(String(localized: "\(section.title), all \(count) done"))
        .accessibilityHint(String(localized: "Shows them"))
    }
}

/// One task on the timeline: its time, a dot on the rail, and its card.
struct TimelineRow<Card: View>: View {
    let time: Date?
    let done: Bool
    var isNext = false
    @ViewBuilder var card: Card

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 0) {
                if let time {
                    Text(time.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()))
                        .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote).monospacedDigit())
                    Text(time.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))).filter { $0.isLetter })
                        .font(.allo(size: 9, weight: .heavy, relativeTo: .caption2))
                        .opacity(0.7)
                }
            }
            .foregroundStyle(done ? Color.inkTertiary : (isNext ? Color.ink : Color.inkSecondary))
            .frame(width: 44, alignment: .trailing)
            .padding(.top, 15)
            Rail(done: done, tone: isNext ? .yellow : nil)
            card
                .overlay(alignment: .topTrailing) {
                    if isNext && !done {
                        Text(String(localized: "NEXT"))
                            .font(.allo(size: 10, weight: .heavy, relativeTo: .caption2))
                            .tracking(1)
                            .foregroundStyle(StickerTone.yellow.deep)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(StickerTone.yellow.fill, in: .capsule)
                            .rotationEffect(.degrees(6))
                            .offset(x: 4, y: -8)
                    }
                }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Where you are in the day.
struct NowMarker: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            HStack(spacing: 8) {
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2).monospacedDigit())
                    .foregroundStyle(StickerTone.pink.fill)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 44, alignment: .trailing)
                Circle()
                    .fill(StickerTone.pink.fill)
                    .frame(width: 12, height: 12)
                    .background(Circle().fill(StickerTone.pink.fill.opacity(0.25)).padding(-5))
                    .frame(width: 16)
                Text(String(localized: "NOW"))
                    .font(.allo(size: 10, weight: .heavy, relativeTo: .caption2))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(StickerTone.pink.fill, in: .capsule)
                LinearGradient(colors: [StickerTone.pink.fill, StickerTone.pink.fill.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Now"))
    }
}
