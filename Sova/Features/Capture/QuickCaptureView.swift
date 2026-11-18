import SwiftUI
import SwiftData
import TipKit

/// Capture a task as fast as you can type. Dates, times and priority are
/// read out of the text and highlighted in place as you write.
struct QuickCaptureView: View {
    @Environment(\.modelContext) private var context
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

    private var theme: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }
    private var accent: Color { theme.accent.color }
    private var parsed: ParsedTask { QuickParse.parse(text) }
    private var canSave: Bool { !parsed.title.isEmpty }
    private let fieldFont = Font.allo(size: 27, weight: .heavy, relativeTo: .title2)

    /// The typed text with what the parser understood highlighted.
    private var highlighted: AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = Color.ink
        if let range = parsed.dateRange, let r = Range(range, in: attributed) {
            attributed[r].foregroundColor = StickerTone.yellow.deep
            attributed[r].backgroundColor = StickerTone.yellow.fill
        }
        if let range = parsed.priorityRange, let r = Range(range, in: attributed) {
            attributed[r].foregroundColor = StickerTone.pink.deep
            attributed[r].backgroundColor = StickerTone.pink.fill
        }
        return attributed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(added == 0 ? String(localized: "New task")
                     : String(localized: "\(added) added · keep going"),
                     color: added == 0 ? .inkSecondary : StickerTone.mint.deep)
                .contentTransition(.numericText())

            ZStack(alignment: .topLeading) {
                Text(highlighted)
                    .font(fieldFont)
                    .tracking(-0.4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsHitTesting(false)
                TextField("", text: $text, prompt: Text("Call Mom tomorrow 6pm !!").foregroundStyle(Color.inkTertiary),
                          axis: .vertical)
                    .font(fieldFont)
                    .tracking(-0.4)
                    .foregroundStyle(Color.clear)
                    .tint(StickerTone.indigo.fill)
                    .lineLimit(1...4)
                    .focused($focused)
                    .submitLabel(.done)
                    .onChange(of: text) { _, newValue in
                        if newValue.contains("\n") {
                            text = newValue.replacingOccurrences(of: "\n", with: "")
                            save()
                        }
                    }
            }
            .padding(.top, 12)

            HStack(spacing: 8) {
                if let due = parsed.dueDate {
                    Token(symbol: "calendar",
                          text: parsed.hasTime
                            ? due.formatted(.dateTime.weekday(.abbreviated).day().hour().minute())
                            : due.relativeDayText(includingTime: false))
                } else {
                    ForEach(DayChoice.allCases, id: \.self) { choice in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { day = choice }
                        } label: {
                            Token(symbol: nil, text: choice.label, selected: day == choice, accent: accent)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                if parsed.priority != .low {
                    Token(symbol: "flag", text: parsed.priority == .high ? String(localized: "High") : String(localized: "Medium"))
                }
                Spacer(minLength: 4)
                Button(action: openDetails) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.allo(.subheadline, .medium))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("More options")
                Button(action: save) {
                    Image(systemName: "arrow.up")
                        .font(.allo(.body, .bold))
                        .foregroundStyle(StickerTone.indigo.deep)
                        .frame(width: 46, height: 46)
                        .background(StickerTone.indigo.fill, in: .circle)
                }
                .buttonStyle(.pressable)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.25)
                .accessibilityLabel("Add task")
            }
            .padding(.top, 16)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: parsed.dueDate)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 12)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.canvas)
        .sensoryFeedback(.success, trigger: added)
        .sensoryFeedback(.selection, trigger: parsed.dueDate != nil) { _, found in found }
        .sensoryFeedback(.selection, trigger: parsed.priority)
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
            accent: theme.accent
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

/// A parsed token or choice, monospaced like a little label.
private struct Token: View {
    let symbol: String?
    let text: String
    var selected = true
    var accent: Color = .ink

    var body: some View {
        HStack(spacing: 6) {
            if let symbol { Image(systemName: symbol).font(.allo(.caption2, .semibold)) }
            Text(text).font(.allo(.subheadline, .bold))
        }
        .foregroundStyle(selected ? Color.ink : Color.inkSecondary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(selected ? Color.white : Color.clear, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.night.opacity(selected ? 0 : 0.1)))
    }
}
