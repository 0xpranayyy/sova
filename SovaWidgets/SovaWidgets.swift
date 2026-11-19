import WidgetKit
import SwiftUI

@main
struct SovaWidgetsBundle: WidgetBundle {
    init() { Allo.register() }

    var body: some Widget {
        TodayWidget()
        DayWidget()
        RitualsWidget()
        NewTaskControl()
    }
}

// MARK: - Today (small, medium, Lock Screen)

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SovaToday", provider: DayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Your day's progress, with the owl.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline:
            Label(entry.allDone ? String(localized: "Whole day done")
                  : entry.total == 0 ? String(localized: "A clear day")
                  : String(localized: "\(entry.done) of \(entry.total) done today"),
                  systemImage: entry.allDone ? "checkmark.seal.fill" : "circle.dashed")
                .containerBackground(for: .widget) { Color.clear }
        case .systemMedium: medium
        default: small
        }
    }

    private var countText: String {
        entry.total == 0 ? String(localized: "A clear day")
                         : String(localized: "\(entry.done) of \(entry.total)")
    }

    private var dayText: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).day())
    }

    // MARK: Small: the owl on its stage

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                WidgetCaps(String(localized: "Today"))
                Spacer(minLength: 4)
                WidgetCaps(dayText, color: .white.opacity(0.55), size: 10)
            }
            Spacer(minLength: 0)
            HStack {
                Spacer()
                OwlRing(progress: entry.progress, happy: entry.allDone, size: 86)
                Spacer()
            }
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: 4) {
                StickerPill(text: entry.allDone ? String(localized: "All done!") : countText,
                            tone: entry.allDone ? .mint : .yellow, tilt: -4, size: 12)
                Spacer(minLength: 0)
                if entry.streak > 1 {
                    StickerPill(text: "\(entry.streak)", tone: .pink, symbol: "flame.fill", tilt: 5, size: 11)
                }
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                StageBackground()
                GeometryReader { geo in
                    WidgetSparkle(tone: .pink, size: 13).position(x: geo.size.width - 24, y: geo.size.height * 0.36)
                    WidgetSparkle(tone: .mint, size: 10).position(x: 24, y: geo.size.height * 0.46)
                    WidgetSparkle(tone: .yellow, size: 8).position(x: geo.size.width * 0.72, y: geo.size.height * 0.2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Today: \(entry.done) of \(entry.total) done"))
    }

    // MARK: Medium: the owl and what's next

    private var medium: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                OwlRing(progress: entry.progress, happy: entry.allDone, size: 118)
                if entry.streak > 1 {
                    StickerPill(text: "\(entry.streak)", tone: .pink, symbol: "flame.fill", tilt: 8, size: 11)
                        .offset(x: 6, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    WidgetCaps(entry.allDone ? String(localized: "All done") : String(localized: "Up next"))
                    Spacer(minLength: 4)
                    WidgetCaps(dayText, color: .white.opacity(0.55), size: 10)
                }
                Spacer(minLength: 6)
                Text(headline)
                    .font(.allo(size: 20, weight: .heavy))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let time = entry.next?.time, !entry.allDone {
                    StickerPill(text: time.formatted(date: .omitted, time: .shortened),
                                tone: .yellow, symbol: "clock.fill", tilt: -3, size: 12)
                        .padding(.top, 7)
                }
                Spacer(minLength: 8)
                ProgressSegments(done: entry.done, total: entry.total)
                Text(entry.total == 0 ? String(localized: "Nothing planned yet")
                                      : String(localized: "\(entry.done) of \(entry.total) done"))
                    .font(.allo(size: 11, weight: .heavy).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 5)
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                StageBackground()
                GeometryReader { geo in
                    WidgetSparkle(tone: .yellow, size: 9).position(x: geo.size.width * 0.37, y: 18)
                    WidgetSparkle(tone: .mint, size: 11).position(x: 18, y: geo.size.height - 22)
                }
            }
        }
    }

    private var headline: String {
        if entry.allDone { return String(localized: "Whole day, done!") }
        return entry.next?.title ?? String(localized: "A clear day")
    }

    // MARK: Lock Screen

    private var circular: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            Text(entry.allDone ? "✓" : "\(entry.done)")
                .font(.allo(size: 16, weight: .heavy))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Gauge(value: entry.progress) { EmptyView() }
                .gaugeStyle(.accessoryCircularCapacity)
                .scaleEffect(0.72)
                .frame(width: 40, height: 40)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.allDone ? String(localized: "ALL DONE") : String(localized: "UP NEXT"))
                    .font(.allo(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .widgetAccentable()
                Text(entry.allDone ? String(localized: "Whole day, done!") : (entry.next?.title ?? String(localized: "A clear day")))
                    .font(.allo(size: 15, weight: .heavy))
                    .lineLimit(1)
                Text(lockSubtitle)
                    .font(.allo(size: 12, weight: .semibold).monospacedDigit())
                    .opacity(0.75)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var lockSubtitle: String {
        if entry.total == 0 { return String(localized: "Nothing planned") }
        if let time = entry.next?.time, !entry.allDone {
            return time.formatted(date: .omitted, time: .shortened) + " · " + String(localized: "\(entry.done) of \(entry.total)")
        }
        return String(localized: "\(entry.done) of \(entry.total) done")
    }
}

// MARK: - My Day (large): the whole day on one widget

struct DayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SovaDay", provider: DayProvider()) { entry in
            DayWidgetView(entry: entry)
        }
        .configurationDisplayName("My Day")
        .description("Your whole day: the owl, your week, what's next and your rituals. Tick things off right here.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

struct DayWidgetView: View {
    let entry: DayEntry
    @Environment(\.widgetIsFullColor) private var fullColor

    private var maxRows: Int { entry.rituals.isEmpty ? 4 : 3 }

    var body: some View {
        VStack(spacing: 0) {
            stage
            list
        }
        .containerBackground(for: .widget) { PaperBackground() }
    }

    // The indigo stage up top, with soft round bottom corners like a sticker.
    private var stage: some View {
        HStack(alignment: .center, spacing: 16) {
            OwlRing(progress: entry.progress, happy: entry.allDone, size: 108)

            VStack(alignment: .leading, spacing: 0) {
                WidgetCaps(entry.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)), size: 10)
                Text(entry.allDone ? String(localized: "Day done!") : entry.greeting)
                    .font(.allo(size: 22, weight: .heavy))
                    .tracking(-0.7)
                    .foregroundStyle(entry.allDone ? StickerTone.yellow.fill : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.top, 4)
                HStack(spacing: 6) {
                    StickerPill(text: entry.total == 0 ? String(localized: "A clear day")
                                                       : String(localized: "\(entry.done) of \(entry.total) done"),
                                tone: entry.allDone ? .mint : .yellow, tilt: -3, size: 12)
                    if entry.streak > 1 {
                        StickerPill(text: String(localized: "\(entry.streak) days"), tone: .pink,
                                    symbol: "flame.fill", tilt: 4, size: 11)
                    }
                }
                .padding(.top, 9)
                Spacer(minLength: 8)
                WeekBars(week: entry.week, today: (entry.week.last ?? nil) ?? 0, height: 22, end: entry.date)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 164)
        .background {
            UnevenRoundedRectangle(bottomLeadingRadius: 26, bottomTrailingRadius: 26, style: .continuous)
                .fill(fullColor ? AnyShapeStyle(StickerTone.indigo.fill) : AnyShapeStyle(Color.primary.opacity(0.1)))
                .overlay {
                    if fullColor {
                        UnevenRoundedRectangle(bottomLeadingRadius: 26, bottomTrailingRadius: 26, style: .continuous)
                            .fill(RadialGradient(colors: [Color.white.opacity(0.14), .clear],
                                                 center: UnitPoint(x: 0.15, y: -0.2), startRadius: 0, endRadius: 240))
                    }
                }
                .overlay {
                    GeometryReader { geo in
                        WidgetSparkle(tone: .pink, size: 13).position(x: geo.size.width - 22, y: 26)
                        WidgetSparkle(tone: .yellow, size: 9).position(x: geo.size.width - 46, y: 56)
                        WidgetSparkle(tone: .mint, size: 10).position(x: 128, y: geo.size.height - 14)
                    }
                }
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                WidgetCaps(String(localized: "Up next"), color: Color.inkSecondary, size: 10)
                Spacer()
                if entry.openTasks > 0 {
                    WidgetCaps(String(localized: "\(entry.openTasks) left"), color: Color.inkTertiary, size: 10)
                }
            }
            .padding(.bottom, 4)

            if entry.tasks.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(StickerTone.orange.fill)
                        .widgetAccentable()
                    Text(entry.allDone ? String(localized: "Everything's done. Go enjoy your evening.")
                                       : String(localized: "No tasks today. Add one in Sova."))
                        .font(.allo(size: 14, weight: .bold))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(2)
                }
                .frame(height: 34)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(maxRows).enumerated()), id: \.element.id) { index, task in
                        if index > 0 { Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, 40) }
                        TaskLine(task: task)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(fullColor ? Color.surface.shadow(.drop(color: Color.night.opacity(0.06), radius: 8, y: 4))
                                        : Color.primary.opacity(0.06).shadow(.drop(color: .clear, radius: 0)))
                }
            }

            Spacer(minLength: 6)

            if !entry.rituals.isEmpty {
                HStack(alignment: .center, spacing: 9) {
                    ForEach(entry.rituals.prefix(6)) { item in
                        RitualDot(item: item, size: 36)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 1) {
                        WidgetCaps(String(localized: "Rituals"), color: Color.inkTertiary, size: 9)
                        Text("\(entry.ritualsDone)/\(entry.rituals.count)")
                            .font(.allo(size: 15, weight: .heavy).monospacedDigit())
                            .foregroundStyle(Color.ink)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Rituals (interactive)

struct RitualsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SovaRituals", provider: DayProvider()) { entry in
            RitualsWidgetView(entry: entry)
        }
        .configurationDisplayName("Rituals")
        .description("Tick off today's rituals right from your Home Screen.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct RitualsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    private var isLarge: Bool { family == .systemLarge }

    var body: some View {
        let items = Array(entry.rituals.prefix(isLarge ? 9 : 4))
        let allDone = !entry.rituals.isEmpty && entry.ritualsDone == entry.rituals.count
        VStack(alignment: .leading, spacing: isLarge ? 14 : 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    WidgetCaps(String(localized: "Rituals"), color: Color.inkSecondary, size: 10)
                    Text(items.isEmpty ? String(localized: "Nothing today")
                         : allDone ? String(localized: "All kept today!")
                         : String(localized: "\(entry.ritualsDone) of \(entry.rituals.count) kept"))
                        .font(.allo(size: isLarge ? 21 : 18, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 6)
                if entry.streak > 1 {
                    StickerPill(text: "\(entry.streak)", tone: .pink, symbol: "flame.fill", tilt: 4, size: 11)
                }
                Image(allDone ? "OwlHappy" : "Owl")
                    .resizable()
                    .widgetAccentedRenderingMode(.accentedDesaturated)
                    .scaledToFit()
                    .frame(height: isLarge ? 46 : 36)
                    .rotationEffect(.degrees(6))
                    .accessibilityHidden(true)
            }

            if items.isEmpty {
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    Text("A rest day. The owl approves.")
                        .font(.allo(size: 15, weight: .heavy))
                        .foregroundStyle(Color.inkSecondary)
                    Text("Add rituals in Sova to tick them off here.")
                        .font(.allo(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTertiary)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            } else if isLarge {
                Grid(horizontalSpacing: 9, verticalSpacing: 9) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<3, id: \.self) { column in
                                let index = row * 3 + column
                                if index < items.count {
                                    RitualTile(item: items[index], tilt: tilt(index), titleSize: 13)
                                } else {
                                    Color.clear
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                ProgressSegments(done: entry.ritualsDone, total: entry.rituals.count,
                                 fill: StickerTone.mint.fill, track: Color.ink.opacity(0.07), height: 6)
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        RitualTile(item: item, tilt: tilt(index), titleSize: 12)
                    }
                    ForEach(items.count..<4, id: \.self) { _ in Color.clear }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) { PaperBackground() }
    }

    /// Stickers sit a little crooked, alternating.
    private func tilt(_ index: Int) -> Double {
        [-2, 1.5, -1, 2][index % 4]
    }
}

// MARK: - Previews

#Preview("Today small", as: .systemSmall) {
    TodayWidget()
} timeline: {
    DayEntry.placeholder
}

#Preview("Today medium", as: .systemMedium) {
    TodayWidget()
} timeline: {
    DayEntry.placeholder
}

#Preview("My Day", as: .systemLarge) {
    DayWidget()
} timeline: {
    DayEntry.placeholder
}

#Preview("Rituals medium", as: .systemMedium) {
    RitualsWidget()
} timeline: {
    DayEntry.placeholder
}

#Preview("Rituals large", as: .systemLarge) {
    RitualsWidget()
} timeline: {
    DayEntry.placeholder
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    TodayWidget()
} timeline: {
    DayEntry.placeholder
}
