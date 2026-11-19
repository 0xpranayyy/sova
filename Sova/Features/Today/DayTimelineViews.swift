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

    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    private var allDone: Bool { total > 0 && done == total }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.13), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.001, progress))
                    .stroke(AngularGradient(colors: [StickerTone.orange.fill, StickerTone.yellow.fill, StickerTone.yellow.fill],
                                            center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * max(progress, 0.001))),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(progress > 0 ? 1 : 0)
                OwlMark(size: 44, happy: allDone,
                        bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8),
                        celebrate: cheers)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { owlFrame = $0 }
                    .offset(y: 2)
            }
            .frame(width: 78, height: 78)
            .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 120, height: 90)) }
            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)

            VStack(alignment: .leading, spacing: 3) {
                MonoCaps(greeting, color: StickerTone.yellow.fill)
                    .lineLimit(1)
                Text(total == 0 ? String(localized: "A clear day")
                     : allDone ? String(localized: "All done!")
                     : String(localized: "\(done) of \(total) done"))
                    .font(.allo(size: 25, weight: .heavy, relativeTo: .title2))
                    .tracking(-0.7)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(done)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if total > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<min(total, 12), id: \.self) { index in
                            let lit = total <= 12 ? index < done : Double(index) < progress * 12
                            Capsule()
                                .fill(lit ? StickerTone.yellow.fill : Color.white.opacity(0.16))
                                .frame(height: 6)
                        }
                    }
                    .padding(.top, 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: done)
                }
            }
            Spacer(minLength: 0)
            if streak > 1 {
                TiltPill(text: "🔥 \(streak)", tone: .mint, tilt: 6, size: 13)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(.vertical, 14)
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .background {
            let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
            shape.fill(StickerTone.indigo.fill.shadow(.drop(color: StickerTone.indigo.shadow, radius: 16, y: 9)))
            shape.fill(RadialGradient(colors: [Color.white.opacity(0.14), .clear],
                                      center: .topLeading, startRadius: 0, endRadius: 240))
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
                .font(.allo(size: 12, weight: .heavy).monospacedDigit())
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
                        .font(.allo(size: 13, weight: .heavy).monospacedDigit())
                    Text(time.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))).filter { $0.isLetter })
                        .font(.allo(size: 9, weight: .heavy))
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
                            .font(.allo(size: 10, weight: .heavy))
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
                    .font(.allo(size: 11, weight: .heavy).monospacedDigit())
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
                    .font(.allo(size: 10, weight: .heavy))
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
