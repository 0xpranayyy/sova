import SwiftUI
import SwiftData
import TipKit

/// A small sheet for capturing tasks as fast as you can type. Dates, times
/// and priority are read out of the text as you write.
struct QuickCaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue

    @State private var text = ""
    @State private var day: DayChoice = .today
    @State private var added = 0
    @FocusState private var focused: Bool

    enum DayChoice: CaseIterable {
        case today, tomorrow, someday

        var label: String {
            switch self {
            case .today: String(localized: "Today")
            case .tomorrow: String(localized: "Tomorrow")
            case .someday: String(localized: "Someday")
            }
        }

        var date: Date? {
            switch self {
            case .today: Date.now.startOfDay
            case .tomorrow: Date.now.startOfDay.adding(days: 1)
            case .someday: nil
            }
        }
    }

    private var accent: Accent { (SovaTheme(rawValue: themeRaw) ?? .ember).accent }
    private var parsed: ParsedTask { QuickParse.parse(text) }
    private var canSave: Bool { !parsed.title.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Checkbox(isOn: false, color: accent.color)
                TextField("New task", text: $text)
                    .font(.display(.title3))
                    .foregroundStyle(Color.ink)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(save)
                Button(action: save) {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.inkInverse)
                        .frame(width: 36, height: 36)
                        .background(Color.ink, in: .circle)
                        .frame(width: 44, height: 44)
                        .contentShape(.circle)
                }
                .buttonStyle(.pressable)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.2)
                .animation(.smooth(duration: 0.2), value: canSave)
                .accessibilityLabel("Add task")
            }

            HStack(spacing: 8) {
                if let due = parsed.dueDate {
                    CaptureChip(text: due.relativeDayText(includingTime: parsed.hasTime),
                                symbol: parsed.hasTime ? "clock" : "calendar", selected: true, color: accent.color)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                } else {
                    ForEach(DayChoice.allCases, id: \.self) { choice in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { day = choice }
                        } label: {
                            CaptureChip(text: choice.label, symbol: nil, selected: day == choice, color: accent.color)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                if parsed.priority != .low {
                    CaptureChip(text: parsed.priority.marks, symbol: nil, selected: true, color: parsed.priority.color)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                Spacer(minLength: 0)
                Button(action: openDetails) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 44, height: 34)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("More options")
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: parsed)

            Group {
                if added > 0 {
                    Label(added == 1 ? String(localized: "1 task added") : String(localized: "\(added) tasks added"),
                          systemImage: "checkmark")
                        .foregroundStyle(accent.color)
                        .contentTransition(.numericText())
                } else {
                    Text("Try “Pay rent friday !!” or “Call Mom tomorrow 6pm”")
                        .foregroundStyle(Color.inkTertiary)
                }
            }
            .font(.footnote)
            .animation(.smooth, value: added)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .presentationDetents([.height(196)])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.success, trigger: added)
        .task { focused = true }
    }

    @discardableResult
    private func makeTask() -> TaskItem? {
        let p = parsed
        guard !p.title.isEmpty else { return nil }
        let task = TaskItem(
            title: p.title,
            dueDate: p.dueDate ?? day.date,
            hasTime: p.dueDate != nil && p.hasTime,
            priority: p.priority,
            accent: accent
        )
        context.insert(task)
        QuickCaptureTip().invalidate(reason: .actionPerformed)
        SwipeTip.isReady = true
        return task
    }

    private func save() {
        guard makeTask() != nil else { return }
        added += 1
        text = ""
        focused = true
    }

    private func openDetails() {
        if let task = makeTask() {
            router.sheet = .task(task)
        } else {
            router.sheet = .newTask(nil)
        }
    }
}

private struct CaptureChip: View {
    let text: String
    let symbol: String?
    let selected: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.caption.weight(.semibold)) }
            Text(text).font(.footnote.weight(.medium))
        }
        .foregroundStyle(selected ? color : Color.inkSecondary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(selected ? color.opacity(0.13) : Color.well, in: .capsule)
    }
}
