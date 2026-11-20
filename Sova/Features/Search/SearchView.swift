import SwiftUI
import SwiftData

/// One field that finds tasks, rituals and goals as you type.
struct SearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Routine.order) private var routines: [Routine]
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    @State private var query = ""
    @FocusState private var focused: Bool

    private var needle: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func hit(_ text: String) -> Bool {
        text.localizedStandardContains(needle)
    }

    var body: some View {
        let foundTasks = needle.isEmpty ? [] : tasks.filter {
            hit($0.title) || hit($0.notes) || $0.checklist.contains { hit($0.title) }
        }
        let foundRituals = needle.isEmpty ? [] : routines.filter { hit($0.title) }
        let foundGoals = needle.isEmpty ? [] : goals.filter { hit($0.title) || hit($0.notes) }
        let none = !needle.isEmpty && foundTasks.isEmpty && foundRituals.isEmpty && foundGoals.isEmpty

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.inkSecondary)
                        TextField(String(localized: "Search tasks, rituals and goals"), text: $query)
                            .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                            .focused($focused)
                            .submitLabel(.search)
                            .autocorrectionDisabled()
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.inkTertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Clear"))
                        }
                    }
                    .surface(cornerRadius: 26, padding: 16)
                    .padding(.bottom, 6)

                    if needle.isEmpty {
                        hint
                    } else if none {
                        VStack(spacing: 10) {
                            OwlMark(size: 64, reactsToTap: false)
                            Text(String(localized: "Nothing called “\(needle)”"))
                                .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                                .foregroundStyle(Color.ink)
                            Button(String(localized: "Add it as a task")) { router.sheet = .quickTask }
                                .buttonStyle(.inkCompact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                    }

                    if !foundTasks.isEmpty {
                        section(String(localized: "Tasks"), count: foundTasks.count)
                        ForEach(foundTasks.prefix(30)) { task in
                            result(symbol: task.isDone ? "checkmark.circle.fill" : "circle",
                                   tone: StickerTone(task.accent), title: task.title,
                                   detail: task.dueDate.map { $0.relativeDayText(includingTime: task.hasTime) }
                                       ?? String(localized: "Someday"),
                                   faded: task.isDone) { router.sheet = .task(task) }
                        }
                    }
                    if !foundRituals.isEmpty {
                        section(String(localized: "Rituals"), count: foundRituals.count)
                        ForEach(foundRituals) { routine in
                            result(symbol: routine.symbol, tone: StickerTone(routine.accent), title: routine.title,
                                   detail: Weekdays.summary(for: routine.weekdays) + (routine.streak > 1 ? " · 🔥 \(routine.streak)" : ""),
                                   faded: false) { router.sheet = .routine(routine) }
                        }
                    }
                    if !foundGoals.isEmpty {
                        section(String(localized: "Goals"), count: foundGoals.count)
                        ForEach(foundGoals) { goal in
                            result(symbol: goal.symbol, tone: StickerTone(goal.accent), title: goal.title,
                                   detail: goal.progress.formatted(.percent.precision(.fractionLength(0)))
                                       + (goal.isArchived ? " · " + String(localized: "Archived") : ""),
                                   faded: goal.isArchived) { router.sheet = .goal(goal) }
                        }
                    }
                }
                .readableColumn()
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: needle)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { CanvasBackground() }
            .navigationTitle(String(localized: "Search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EditorCloseButton { dismiss() } }
            .onAppear { focused = true }
        }
        .tint(Color.ink)
    }

    private var hint: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoCaps(String(localized: "Try"))
            FlowLayout(spacing: 8) {
                ForEach([String(localized: "call"), String(localized: "read"), String(localized: "gym"), String(localized: "mom")],
                        id: \.self) { word in
                    Button { query = word } label: {
                        Text(word)
                            .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(Color.well, in: .capsule)
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
        .padding(.top, 4)
    }

    private func section(_ title: String, count: Int) -> some View {
        SectionLabel(title, trailing: "\(count)")
            .padding(.top, 10)
    }

    private func result(symbol: String, tone: StickerTone, title: String, detail: String,
                        faded: Bool, open: @escaping () -> Void) -> some View {
        Button(action: open) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                    .frame(width: 38, height: 38)
                    .background(tone.fill, in: .rect(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                        .foregroundStyle(faded ? Color.inkTertiary : Color.ink)
                        .lineLimit(1)
                    Text(detail)
                        .font(.allo(.footnote, .bold))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color.inkTertiary)
            }
            .padding(12)
            .background(Color.surface, in: .rect(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
        }
        .buttonStyle(.pressable)
    }
}
