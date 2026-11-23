import SwiftUI
import SwiftData

/// "Add a task…" right on the Tasks screen: big type on an indigo line,
/// with what Sova understood shown as chips underneath (when, goal,
/// priority). Return adds it and keeps the line ready for the next one.
struct InlineAdd: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt) private var goals: [Goal]
    @State private var text = ""
    @State private var added = 0
    @FocusState private var focused: Bool

    private var parsed: ParsedTask { QuickParse.parse(text, goals: goals.map(\.title)) }
    private var parsedGoal: Goal? {
        guard let i = parsed.goalIndex, goals.indices.contains(i) else { return nil }
        return goals[i]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("", text: $text, prompt: Text("Add a task…").foregroundStyle(Color.inkTertiary))
                    .font(.hero(24, weight: .heavy))
                    .tracking(-0.8)
                    .foregroundStyle(Color.ink)
                    .tint(Color(hex: 0x6E4BFF))
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(add)
                if !parsed.title.isEmpty {
                    Button(action: add) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(StickerTone.indigo.deep)
                            .frame(width: 36, height: 36)
                            .background(StickerTone.indigo.fill, in: .circle)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(String(localized: "Add task"))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            Capsule()
                .fill(focused || !text.isEmpty ? StickerTone.indigo.fill : Color.hairline)
                .frame(height: 3)
            if focused || !text.isEmpty {
                chips.transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 4)
        .animation(.smooth(duration: 0.25), value: focused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: parsed.title.isEmpty)
        .sovaFeedback(.success, trigger: added)
    }

    /// What Sova read from the text, or hints for what it can read.
    private var chips: some View {
        HStack(spacing: 6) {
            if let due = parsed.dueDate {
                chip("calendar", due.relativeDayText(includingTime: parsed.hasTime), on: true)
            } else {
                chip("calendar", String(localized: "Today"), on: false)
            }
            if let goal = parsedGoal {
                chip(goal.symbol, goal.title, on: true)
            } else if !goals.isEmpty {
                chip("flag", String(localized: "for a goal"), on: false)
            }
            if parsed.priority != .low {
                chip("exclamationmark", parsed.priority == .high ? String(localized: "High") : String(localized: "Medium"), on: true)
            } else {
                chip("exclamationmark", String(localized: "!! for priority"), on: false)
            }
        }
    }

    private func chip(_ symbol: String, _ title: String, on: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 11, weight: .heavy))
            Text(title).font(.allo(size: 13, weight: .heavy, relativeTo: .footnote)).lineLimit(1)
        }
        .foregroundStyle(on ? StickerTone.indigo.deep : Color.inkSecondary)
        .padding(.horizontal, 11)
        .frame(height: 30)
        .background(on ? StickerTone.indigo.fill : Color.surface, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: on ? 0 : 1.5))
    }

    private func add() {
        let p = parsed
        guard !p.title.isEmpty else { return }
        let task = TaskItem(title: p.title, dueDate: p.dueDate ?? Date.now.startOfDay,
                            hasTime: p.dueDate != nil && p.hasTime, priority: p.priority,
                            accent: SovaTheme.current.accent)
        task.repeatRule = p.repeatRule
        context.insert(task)
        if let goal = parsedGoal { task.goal = goal }
        TaskAlerts.schedule(task)
        SovaRefresh.changed(context)
        if task.hasTime { Task { await TaskAlerts.requestPermissionIfNeeded() } }
        Sounds.play(.pop)
        added += 1
        text = ""
        focused = true
    }
}
