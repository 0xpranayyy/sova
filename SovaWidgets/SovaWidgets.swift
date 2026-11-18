import WidgetKit
import SwiftUI

@main
struct SovaWidgetsBundle: WidgetBundle {
    init() { Allo.register() }

    var body: some Widget {
        TodayWidget()
        RitualsWidget()
    }
}

// MARK: - Today

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
        case .accessoryCircular:
            Gauge(value: entry.progress) {
                Image(systemName: "checkmark")
            } currentValueLabel: {
                Text("\(entry.done)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.allDone ? "ALL DONE" : "UP NEXT")
                    .font(.allo(size: 11, weight: .heavy))
                    .tracking(1.2)
                    .widgetAccentable()
                Text(entry.allDone ? String(localized: "Whole day, done! 🦉") : (entry.next?.title ?? String(localized: "A clear day")))
                    .font(.allo(size: 15, weight: .heavy))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.allo(size: 12, weight: .semibold))
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Text("\(entry.done) of \(entry.total) done today")
                .containerBackground(for: .widget) { Color.clear }
        case .systemMedium:
            medium
        default:
            small
        }
    }

    private var subtitle: String {
        if let time = entry.next?.time, !entry.allDone { return time.formatted(date: .omitted, time: .shortened) }
        return String(localized: "\(entry.done) of \(entry.total) done")
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY")
                .font(.allo(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(StickerTone.yellow.fill)
            Spacer(minLength: 0)
            HStack {
                Spacer()
                OwlRing(progress: entry.progress, happy: entry.allDone, size: 96)
                Spacer()
            }
            Spacer(minLength: 0)
            DonePill(text: entry.total == 0 ? String(localized: "A clear day") : String(localized: "\(entry.done) of \(entry.total) done"))
        }
        .containerBackground(for: .widget) { StickerTone.indigo.fill }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            OwlRing(progress: entry.progress, happy: entry.allDone, size: 118)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.allDone ? "ALL DONE" : "UP NEXT")
                    .font(.allo(size: 11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(StickerTone.yellow.fill)
                Text(entry.allDone ? String(localized: "Whole day, done! 🎉") : (entry.next?.title ?? String(localized: "A clear day")))
                    .font(.allo(size: 20, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let time = entry.next?.time, !entry.allDone {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(.allo(size: 13, weight: .heavy).monospacedDigit())
                        .foregroundStyle(StickerTone.indigo.fill)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(StickerTone.yellow.fill, in: .rect(cornerRadius: 9, style: .continuous))
                }
                Spacer(minLength: 0)
                DonePill(text: String(localized: "\(entry.done) of \(entry.total) done"))
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { StickerTone.indigo.fill }
    }
}

/// The yellow owl inside a ring that fills as the day gets done.
struct OwlRing: View {
    let progress: Double
    let happy: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.14), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(StickerTone.yellow.fill, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
                .widgetAccentable()
            Image(happy ? "OwlHappy" : "Owl")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.52)
        }
        .frame(width: size, height: size)
    }
}

struct DonePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.allo(size: 13, weight: .heavy))
            .foregroundStyle(StickerTone.yellow.deep)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(StickerTone.yellow.fill, in: .capsule)
            .rotationEffect(.degrees(-4))
            .lineLimit(1)
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

    var body: some View {
        let items = Array(entry.rituals.prefix(family == .systemLarge ? 10 : 4))
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RITUALS")
                        .font(.allo(size: 11, weight: .heavy))
                        .tracking(1.4)
                        .foregroundStyle(Color.inkSecondary)
                    Text(items.isEmpty ? String(localized: "Nothing today")
                         : String(localized: "\(entry.ritualsDone) of \(entry.rituals.count) done"))
                        .font(.allo(size: 18, weight: .heavy))
                        .tracking(-0.4)
                        .foregroundStyle(Color.ink)
                }
                Spacer()
                Image(entry.ritualsDone == entry.rituals.count && !items.isEmpty ? "OwlHappy" : "Owl")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .rotationEffect(.degrees(6))
            }
            if items.isEmpty {
                Text("A rest day. The owl approves. 🦉")
                    .font(.allo(size: 14, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(items) { item in
                        Button(intent: ToggleRitualIntent(ritual: item.entity)) {
                            RitualPill(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.canvas }
    }
}

struct RitualPill: View {
    let item: RitualItem

    var body: some View {
        let ink = item.tone == .indigo ? Color.white : item.tone.deep
        HStack(spacing: 7) {
            Image(systemName: item.symbol)
                .font(.system(size: 13, weight: .bold))
            Text(item.title)
                .font(.allo(size: 13, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            ZStack {
                Circle().strokeBorder(ink, lineWidth: 2)
                if item.done {
                    Circle().fill(ink)
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(item.tone.fill)
                }
            }
            .frame(width: 20, height: 20)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(item.tone.fill, in: .rect(cornerRadius: 14, style: .continuous))
        .opacity(item.done ? 0.75 : 1)
    }
}
