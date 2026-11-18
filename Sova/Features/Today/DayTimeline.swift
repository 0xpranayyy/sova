import SwiftUI

/// Where an item sits in the day.
enum DaySection: Int, CaseIterable, Identifiable {
    case overdue, morning, afternoon, evening, anytime

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .overdue: String(localized: "Overdue")
        case .morning: String(localized: "Morning")
        case .afternoon: String(localized: "Afternoon")
        case .evening: String(localized: "Evening")
        case .anytime: String(localized: "Anytime")
        }
    }

    var range: String? {
        switch self {
        case .morning: "06—12"
        case .afternoon: "12—18"
        case .evening: "18—24"
        default: nil
        }
    }

    /// Minutes since midnight where the section starts, for ordering.
    var startMinutes: Int {
        switch self {
        case .overdue: -1
        case .morning: 0
        case .afternoon: 12 * 60
        case .evening: 18 * 60
        case .anytime: 24 * 60
        }
    }

    static func forHour(_ hour: Int) -> DaySection {
        switch hour {
        case 0..<12: .morning
        case 12..<18: .afternoon
        default: .evening
        }
    }

    static func forPeriod(_ period: DayPeriod) -> DaySection {
        switch period {
        case .morning: .morning
        case .afternoon: .afternoon
        case .evening: .evening
        case .anytime: .anytime
        }
    }

    static var current: DaySection { forHour(Calendar.current.component(.hour, from: .now)) }
}

/// One thing on today's timeline: a task or a ritual.
struct TimelineEntry: Identifiable {
    enum Source {
        case task(TaskItem)
        case routine(Routine)
    }

    let source: Source
    let section: DaySection
    let sortKey: Int

    var id: String {
        switch source {
        case .task(let t): "t-\(ObjectIdentifier(t).hashValue)"
        case .routine(let r): "r-\(ObjectIdentifier(r).hashValue)"
        }
    }

    var isDone: Bool {
        switch source {
        case .task(let t): t.isDone
        case .routine(let r): r.isDone(on: .now)
        }
    }

    var isRoutine: Bool {
        if case .routine = source { return true }
        return false
    }

    /// The scheduled time for timed tasks.
    var dueTime: Date? {
        if case .task(let t) = source, t.hasTime { return t.dueDate }
        return nil
    }

    static func build(tasks: [TaskItem], routines: [Routine]) -> [TimelineEntry] {
        let cal = Calendar.current
        var entries: [TimelineEntry] = []
        for task in tasks {
            let relevant = task.isDone
                ? (task.completedAt?.isSameDay(as: .now) ?? false)
                : task.isDueTodayOrEarlier
            guard relevant else { continue }
            let section: DaySection
            var key: Int
            if !task.isDone, let due = task.dueDate, due < Date.now.startOfDay {
                section = .overdue
                key = Int(due.timeIntervalSince1970 / 60)
            } else if task.hasTime, let due = task.dueDate {
                let comps = cal.dateComponents([.hour, .minute], from: due)
                section = .forHour(comps.hour ?? 9)
                key = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            } else {
                section = .anytime
                key = DaySection.anytime.startMinutes + 500
                    + Int(task.createdAt.timeIntervalSince1970.truncatingRemainder(dividingBy: 10_000))
            }
            if task.priority == .high && section == .anytime { key -= 400 }
            entries.append(TimelineEntry(source: .task(task), section: section, sortKey: key))
        }
        for routine in routines where routine.isScheduled(on: .now) {
            let section = DaySection.forPeriod(routine.period)
            entries.append(TimelineEntry(source: .routine(routine), section: section,
                                         sortKey: section.startMinutes + 1 + routine.order))
        }
        return entries.sorted { ($0.section.rawValue, $0.sortKey) < ($1.section.rawValue, $1.sortKey) }
    }
}

// MARK: - Rows

/// The vertical line running through the timeline, drawn per row so the
/// list can still scroll, swipe and animate natively.
struct TimelineRail: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.09))
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .padding(.leading, 21.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
    }
}

struct TimelineSectionHeader: View {
    let section: DaySection
    var count: String? = nil

    var body: some View {
        HStack {
            MonoCaps(section.title, color: section == .overdue ? Color.danger : .inkTertiary)
            Spacer()
            if let range = section.range {
                Text(range).font(.mono(11)).foregroundStyle(Color.inkTertiary)
            } else if let count {
                Text(count).font(.mono(10.5)).foregroundStyle(Color.inkTertiary)
            }
        }
        .padding(.leading, 49)
        .padding(.trailing, 4)
        .padding(.top, 18)
        .padding(.bottom, 2)
    }
}

struct NowMarker: View {
    var accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .background(Circle().fill(accent.opacity(0.18)).frame(width: 16, height: 16))
                .frame(width: 22)
                .padding(.leading, 11)
            LinearGradient(colors: [accent.opacity(0.6), accent.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
            Text(Date.now, format: .dateTime.hour().minute())
                .font(.mono(10.5))
                .foregroundStyle(accent)
        }
        .padding(.vertical, 8)
        .padding(.trailing, 4)
        .accessibilityLabel("Now")
    }
}

struct TimelineRow: View {
    let entry: TimelineEntry
    var isNext = false
    var accent: Color
    var onOpen: () -> Void

    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            CheckButton(isOn: entry.isDone, color: accent, round: entry.isRoutine,
                        emphasized: isNext, label: title, action: toggle)
                .padding(.top, isNext ? 14 : -1)

            VStack(alignment: .leading, spacing: 3) {
                if isNext {
                    Text(nextLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(accent)
                        .padding(.bottom, 2)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let marks, !entry.isDone {
                        Text(marks).font(.body.weight(.bold)).foregroundStyle(Color.danger)
                    }
                    Text(title)
                        .font(isNext ? .body.weight(.semibold) : .body.weight(.medium))
                        .foregroundStyle(entry.isDone ? Color.inkTertiary : Color.ink)
                        .lineLimit(2)
                }
                if !meta.isEmpty {
                    Text(meta)
                        .font(.footnote)
                        .foregroundStyle(entry.section == .overdue && !entry.isDone ? Color.danger : Color.inkTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, isNext ? 14 : 10)

            Spacer(minLength: 8)

            Text(timeText)
                .font(.mono(11.5))
                .foregroundStyle(isNext ? Color.inkSecondary : Color.inkTertiary)
                .padding(.top, isNext ? 34 : 13)
        }
        .padding(.trailing, 4)
        .background {
            if isNext {
                // The card bleeds slightly past the row so the node sits inside it.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.canvas)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.surfaceRaised))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.09)))
                    .padding(.horizontal, -8)
                    .padding(.vertical, 4)
            }
        }
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: entry.isDone ? "Mark as not done" : "Mark as done", toggle)
    }

    private var title: String {
        switch entry.source {
        case .task(let t): t.title
        case .routine(let r): r.title
        }
    }

    private var marks: String? {
        if case .task(let t) = entry.source, !t.priority.marks.isEmpty { return t.priority.marks }
        return nil
    }

    private var meta: String {
        switch entry.source {
        case .task(let t):
            if entry.section == .overdue, let due = t.dueDate {
                return String(localized: "Was due \(due.formatted(.dateTime.month(.abbreviated).day()))")
            }
            if let goal = t.goal { return goal.title }
            if !t.notes.isEmpty { return t.notes }
            return String(localized: "Task")
        case .routine(let r):
            let streak = r.streak
            return streak > 1 ? String(localized: "\(streak) day streak") : String(localized: "Ritual")
        }
    }

    private var timeText: String {
        switch entry.source {
        case .task(let t):
            if t.isDone, let done = t.completedAt { return done.formatted(.dateTime.hour().minute()) }
            if t.hasTime, let due = t.dueDate { return due.formatted(.dateTime.hour().minute()) }
            return ""
        case .routine(let r):
            if let done = r.completions.last(where: { $0.isSameDay(as: .now) }) {
                return done.formatted(.dateTime.hour().minute())
            }
            return ""
        }
    }

    private var nextLabel: String {
        guard let due = entry.dueTime, due > .now else { return String(localized: "Up next") }
        let minutes = Int(due.timeIntervalSinceNow / 60)
        if minutes < 60 { return String(localized: "Up next · in \(max(minutes, 1)) min") }
        let hours = minutes / 60
        return hours < 12 ? String(localized: "Up next · in \(hours) h") : String(localized: "Up next")
    }

    private func toggle() {
        switch entry.source {
        case .task(let t):
            TaskActions.toggle(t, router: router)
        case .routine(let r):
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { r.toggle(on: .now) }
        }
    }
}
