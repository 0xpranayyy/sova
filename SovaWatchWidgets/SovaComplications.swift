import WidgetKit
import SwiftUI

@main
struct SovaWatchWidgets: WidgetBundle {
    var body: some Widget {
        SovaComplication()
    }
}

struct WatchDayEntry: TimelineEntry {
    let date: Date
    let day: WatchDay
    /// The stored day is today's (not yesterday's, read after midnight).
    var isCurrent: Bool { Calendar.current.isDate(day.date, inSameDayAs: date) }
    var done: Int { isCurrent ? day.done : 0 }
    var total: Int { isCurrent ? day.total : 0 }
    var progress: Double { isCurrent ? day.progress : 0 }
    var allDone: Bool { isCurrent && day.allDone }

    static let sample = WatchDayEntry(
        date: .now,
        day: WatchDay(date: .now, name: "", done: 4, total: 7, streak: 6,
                      next: WatchNext(title: String(localized: "Call Mom"),
                                      time: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: .now)),
                      rituals: [], tasks: []))
}

struct WatchDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchDayEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (WatchDayEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
        } else {
            completion(WatchDayEntry(date: .now, day: WatchDayStore.load() ?? .empty))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchDayEntry>) -> Void) {
        let day = WatchDayStore.load() ?? .empty
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        // Now, and a fresh (empty) one at midnight until the iPhone sends the
        // new day. The Watch app reloads this whenever a day arrives.
        let entries = [WatchDayEntry(date: .now, day: day), WatchDayEntry(date: midnight, day: day)]
        completion(Timeline(entries: entries, policy: .never))
    }
}

struct SovaComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SovaToday", provider: WatchDayProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Sova")
        .description("Today's progress and what's next.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

struct ComplicationView: View {
    let entry: WatchDayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryCorner: corner
        case .accessoryRectangular: rectangular
        default: inline
        }
    }

    /// The owl inside a ring that fills as the day gets done.
    private var circular: some View {
        Gauge(value: entry.progress) {
            Text("Sova")
        } currentValueLabel: {
            WatchOwl(happy: entry.allDone)
                .padding(2)
                .widgetAccentable()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(WatchPalette.yellow)
        .accessibilityLabel(Text("Sova: \(entry.done) of \(entry.total) done"))
    }

    private var corner: some View {
        Text(entry.total == 0 ? "🦉" : "\(entry.done)/\(entry.total)")
            .font(.sova(16, .heavy))
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: entry.progress) {
                    Text("Sova")
                }
                .tint(WatchPalette.yellow)
            }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text("SOVA")
                    .font(.sova(11, .heavy))
                    .foregroundStyle(WatchPalette.yellow)
                    .widgetAccentable()
                Spacer(minLength: 0)
                Text(entry.total == 0 ? "" : "\(entry.done) of \(entry.total)")
                    .font(.sova(11, .bold))
                    .foregroundStyle(.secondary)
            }
            if entry.allDone {
                Text("Day done! 🦉")
                    .font(.sova(16, .heavy))
            } else if entry.isCurrent, let next = entry.day.next {
                Text(next.title)
                    .font(.sova(16, .heavy))
                    .lineLimit(1)
                if let time = next.time {
                    Text(time, style: .time)
                        .font(.sova(12, .bold))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Open Sova")
                    .font(.sova(15, .heavy))
            }
            ProgressView(value: entry.progress)
                .tint(WatchPalette.yellow)
        }
    }

    private var inline: some View {
        Group {
            if entry.allDone {
                Text("Day done 🦉")
            } else if entry.total > 0 {
                Text("\(entry.done) of \(entry.total) done 🦉")
            } else {
                Text("Sova 🦉")
            }
        }
    }
}
