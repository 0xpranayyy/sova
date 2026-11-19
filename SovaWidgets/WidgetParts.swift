import WidgetKit
import SwiftUI
import AppIntents

// The small pieces every Sova widget is made of: the indigo stage, the owl in
// its ring, sticker pills, the week, and the check buttons.
//
// Each piece also reads well when iOS draws the widget tinted or clear (the
// "accented" rendering mode) or on StandBy at night ("vibrant"): colors give
// way to the system tint and fills fall back to soft glass-like washes.

extension EnvironmentValues {
    /// True when the widget is drawn in its own colors.
    var widgetIsFullColor: Bool { widgetRenderingMode == .fullColor }
}

/// Caps label, Sova's mono-caps voice.
struct WidgetCaps: View {
    let text: String
    var color: Color = StickerTone.yellow.fill
    var size: CGFloat = 11

    init(_ text: String, color: Color = StickerTone.yellow.fill, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(.allo(size: size, weight: .heavy))
            .tracking(size * 0.13)
            .foregroundStyle(color)
            .lineLimit(1)
            .widgetAccentable()
    }
}

/// The night-indigo stage behind the owl, with a soft light from the top.
struct StageBackground: View {
    var body: some View {
        ZStack {
            StickerTone.indigo.fill
            RadialGradient(colors: [Color.white.opacity(0.16), .clear],
                           center: UnitPoint(x: 0.18, y: -0.1), startRadius: 0, endRadius: 260)
            RadialGradient(colors: [Color(hex: 0x120840).opacity(0.55), .clear],
                           center: UnitPoint(x: 0.9, y: 1.15), startRadius: 0, endRadius: 220)
        }
    }
}

/// A four-point sparkle in a sticker color.
struct WidgetSparkle: View {
    let tone: StickerTone
    var size: CGFloat = 12

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .black))
            .foregroundStyle(tone.fill)
            .accessibilityHidden(true)
    }
}

/// The yellow owl inside a ring that fills as the day gets done, with a
/// bright cap on the end of the arc.
struct OwlRing: View {
    let progress: Double
    let happy: Bool
    let size: CGFloat
    @Environment(\.widgetIsFullColor) private var fullColor

    var body: some View {
        let line = size * 0.095
        let shown = max(0.001, min(1, progress))
        ZStack {
            Circle()
                .fill(Color.white.opacity(fullColor ? 0.05 : 0.08))
                .padding(line)
            Circle()
                .stroke(Color.white.opacity(fullColor ? 0.13 : 0.2), lineWidth: line)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(
                    AngularGradient(colors: [StickerTone.orange.fill, StickerTone.yellow.fill, StickerTone.yellow.fill],
                                    center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * shown)),
                    style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
                .widgetAccentable()
            // The bright cap where the arc ends.
            if progress > 0.02 && progress < 1 {
                Circle()
                    .fill(Color.white)
                    .frame(width: line * 0.42, height: line * 0.42)
                    .offset(y: -size / 2 + line / 2)
                    .rotationEffect(.degrees(360 * shown))
            }
            Image(happy ? "OwlHappy" : "Owl")
                .resizable()
                .widgetAccentedRenderingMode(.accentedDesaturated)
                .scaledToFit()
                .frame(width: size * 0.5)
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A tilted sticker pill.
struct StickerPill: View {
    let text: String
    var tone: StickerTone = .yellow
    var symbol: String? = nil
    var tilt: Double = -4
    var size: CGFloat = 13
    @Environment(\.widgetIsFullColor) private var fullColor

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: size * 0.85, weight: .black))
            }
            Text(text)
                .font(.allo(size: size, weight: .heavy).monospacedDigit())
                .tracking(-0.2)
        }
        .foregroundStyle(fullColor ? (tone == .indigo ? Color.white : tone.deep) : Color.primary)
        .lineLimit(1)
        .padding(.horizontal, size * 0.8)
        .padding(.vertical, size * 0.38)
        .background(fullColor ? tone.fill : Color.white.opacity(0.16), in: .capsule)
        .widgetAccentable()
        .rotationEffect(.degrees(tilt))
    }
}

/// A row of short bars, one per thing to do today, filled for the done ones.
/// Turns into one bar when there are too many to count.
struct ProgressSegments: View {
    let done: Int
    let total: Int
    var fill: Color = StickerTone.yellow.fill
    var track: Color = Color.white.opacity(0.16)
    var height: CGFloat = 6

    var body: some View {
        if total > 0 && total <= 12 {
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index < done ? fill : track)
                        .frame(height: height)
                }
            }
            .widgetAccentable()
        } else {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(track)
                    Capsule().fill(fill)
                        .frame(width: total == 0 ? 0 : geo.size.width * Double(done) / Double(total))
                }
            }
            .frame(height: height)
            .widgetAccentable()
        }
    }
}

/// The last seven days as little bars, with the weekday letter under each.
struct WeekBars: View {
    let week: [Double?]
    let today: Double
    var height: CGFloat = 26
    /// The day the entry is for; the bars end on it.
    var end: Date = .now

    var body: some View {
        let days = week.count == 7 ? week : Array(repeating: nil, count: 7)
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<7, id: \.self) { index in
                let isToday = index == 6
                let value = isToday ? today : (days[index] ?? 0)
                let date = end.startOfDay.adding(days: index - 6)
                VStack(spacing: 3) {
                    ZStack(alignment: .bottom) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(isToday ? StickerTone.yellow.fill : StickerTone.mint.fill)
                            .frame(height: max(4, height * value))
                            .opacity(value > 0 ? 1 : 0)
                    }
                    .frame(width: 7, height: height)
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(.allo(size: 8, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(isToday ? 0.95 : 0.5))
                }
            }
        }
        .widgetAccentable()
        .accessibilityHidden(true)
    }
}

/// A round check for a task, on paper.
struct TaskCheck: View {
    let done: Bool
    let tone: StickerTone
    @Environment(\.widgetIsFullColor) private var fullColor

    var body: some View {
        ZStack {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(fullColor ? (tone == .indigo ? Color.white : tone.deep) : Color.primary.opacity(0.5),
                                     fullColor ? tone.fill : Color.primary)
            } else {
                Circle().strokeBorder(Color.ink.opacity(0.22), lineWidth: 2)
            }
        }
        .frame(width: 22, height: 22)
        .widgetAccentable()
    }
}

/// One task on the Day widget, with a working check button.
struct TaskLine: View {
    let task: TaskRowItem
    @Environment(\.widgetIsFullColor) private var fullColor

    var body: some View {
        HStack(spacing: 10) {
            Button(intent: ToggleTaskIntent(taskID: task.id)) {
                TaskCheck(done: task.done, tone: task.tone)
                    .frame(width: 30, height: 30)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.done ? String(localized: "Mark \(task.title) not done")
                                          : String(localized: "Mark \(task.title) done"))

            Text(task.title)
                .font(.allo(size: 15, weight: .heavy))
                .tracking(-0.3)
                .strikethrough(task.done, color: Color.ink.opacity(0.35))
                .foregroundStyle(Color.ink.opacity(task.done ? 0.38 : 1))
                .lineLimit(1)

            if !task.done, !task.priority.marks.isEmpty {
                Text(task.priority.marks)
                    .font(.allo(size: 14, weight: .heavy))
                    .foregroundStyle(task.priority == .high ? Color.ember : StickerTone.orange.fill)
                    .widgetAccentable()
            }

            Spacer(minLength: 4)

            if task.overdue && !task.done {
                timeChip(String(localized: "Late"), tone: .pink)
            } else if let time = task.time, !task.done {
                timeChip(time.formatted(date: .omitted, time: .shortened), tone: task.tone)
            }
        }
        .frame(height: 30)
    }

    private func timeChip(_ text: String, tone: StickerTone) -> some View {
        Text(text)
            .font(.allo(size: 11, weight: .heavy).monospacedDigit())
            .foregroundStyle(fullColor ? (tone == .indigo ? Color.white : tone.deep) : Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(fullColor ? tone.fill : Color.primary.opacity(0.12), in: .capsule)
            .widgetAccentable()
    }
}

/// A ritual as a round sticker button: soft until it's done, then solid
/// with a check badge.
struct RitualDot: View {
    let item: RitualItem
    var size: CGFloat = 38
    @Environment(\.widgetIsFullColor) private var fullColor

    var body: some View {
        Button(intent: ToggleRitualIntent(ritual: item.entity)) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(fullColor ? item.tone.fill.opacity(item.done ? 1 : 0.32) : Color.primary.opacity(item.done ? 0.3 : 0.1))
                    .overlay {
                        Image(systemName: item.symbol)
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundStyle(fullColor ? (item.tone == .indigo ? Color.white : item.tone.deep) : Color.primary)
                    }
                    .frame(width: size, height: size)
                if item.done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.42, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(fullColor ? item.tone.fill : Color.primary.opacity(0.4),
                                         fullColor ? Color.ink : Color.primary)
                        .background(Circle().fill(Color.canvas).padding(-2))
                        .offset(x: 3, y: 3)
                }
            }
            .widgetAccentable()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.done ? String(localized: "Mark \(item.title) not done")
                                      : String(localized: "Mark \(item.title) done"))
    }
}

/// A ritual as a little sticker card, like the ones on Today, with a check
/// that works right from the Home Screen.
struct RitualTile: View {
    let item: RitualItem
    var tilt: Double = 0
    var titleSize: CGFloat = 13
    @Environment(\.widgetIsFullColor) private var fullColor

    var body: some View {
        let ink = fullColor ? (item.tone == .indigo ? Color.white : item.tone.deep) : Color.primary
        Button(intent: ToggleRitualIntent(ritual: item.entity)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    Image(systemName: item.symbol)
                        .font(.system(size: titleSize + 3, weight: .bold))
                    Spacer(minLength: 2)
                    if item.target > 1 && !item.done {
                        Text("\(item.tally)/\(item.target)")
                            .font(.allo(size: 11, weight: .heavy).monospacedDigit())
                            .padding(.horizontal, 6)
                            .frame(height: 20)
                            .background(ink.opacity(0.14), in: .capsule)
                    } else if item.done {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(fullColor ? item.tone.fill : Color.primary.opacity(0.4), ink)
                    } else {
                        Circle().strokeBorder(ink.opacity(0.45), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
                Spacer(minLength: 4)
                Text(item.title)
                    .font(.allo(size: titleSize, weight: .heavy))
                    .tracking(-0.3)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(ink)
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(fullColor ? item.tone.fill : Color.primary.opacity(item.done ? 0.22 : 0.1),
                        in: .rect(cornerRadius: 18, style: .continuous))
            .saturation(item.done ? 0.85 : 1)
            .rotationEffect(.degrees(tilt))
            .widgetAccentable()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.done ? String(localized: "\(item.title), done") : item.title)
    }
}
