import SwiftUI
import SwiftData

/// Make or edit a ritual. The sticker up top is exactly how it will look on
/// Today, and it changes as you type, pick a color or an icon.
struct RoutineEditor: View {
    let routine: Routine?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Query(sort: \Routine.order) private var routines: [Routine]

    @State private var title: String
    @State private var symbol: String
    @State private var accent: Accent
    @State private var period: DayPeriod
    @State private var weekdays: [Int]
    @State private var confirmDelete = false
    @State private var wiggle = 0
    @FocusState private var nameFocused: Bool

    init(routine: Routine?) {
        self.routine = routine
        _title = State(initialValue: routine?.title ?? "")
        _symbol = State(initialValue: routine?.symbol ?? "sun.max")
        _accent = State(initialValue: routine?.accent ?? .tide)
        _period = State(initialValue: routine?.period ?? .morning)
        _weekdays = State(initialValue: routine?.weekdays ?? Array(1...7))
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var tone: StickerTone { StickerTone(accent) }
    private var canSave: Bool { !trimmedTitle.isEmpty && !weekdays.isEmpty }

    private static let ideas: [SuggestionChips.Idea] = [
        .init(title: String(localized: "Drink water"), symbol: "drop", accent: .tide),
        .init(title: String(localized: "Morning walk"), symbol: "figure.walk", accent: .ember),
        .init(title: String(localized: "Read 10 pages"), symbol: "book.closed", accent: .marigold),
        .init(title: String(localized: "Stretch"), symbol: "figure.flexibility", accent: .plum),
        .init(title: String(localized: "Journal"), symbol: "pencil.and.scribble", accent: .rose),
        .init(title: String(localized: "Meditate"), symbol: "wind", accent: .lagoon),
        .init(title: String(localized: "Screens off"), symbol: "moon", accent: .ink),
        .init(title: String(localized: "Workout"), symbol: "dumbbell", accent: .lime),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    preview

                    VStack(alignment: .leading, spacing: 12) {
                        TextField(String(localized: "Name your ritual"), text: $title)
                            .font(.allo(size: 24, weight: .heavy, relativeTo: .title2))
                            .tracking(-0.6)
                            .foregroundStyle(Color.ink)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .surface(cornerRadius: 26, padding: 18)

                        if routine == nil {
                            SuggestionChips(ideas: Self.ideas) { idea in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    title = idea.title
                                    symbol = idea.symbol
                                    accent = idea.accent
                                }
                                wiggle += 1
                                Haptics.pop()
                            }
                        }
                    }

                    EditorCard(title: String(localized: "When")) {
                        PeriodTiles(selection: $period, tone: tone)
                    }

                    EditorCard(title: String(localized: "Repeat"),
                               footer: weekdays.isEmpty ? String(localized: "Pick at least one day.")
                                                        : Weekdays.summary(for: weekdays)) {
                        ToneWeekdays(selection: $weekdays, tone: tone)
                    }

                    EditorCard(title: String(localized: "Color")) {
                        TonePicker(selection: $accent)
                    }

                    EditorCard(title: String(localized: "Icon")) {
                        ToneSymbolGrid(selection: $symbol, tone: tone, symbols: SymbolPicker.routineSymbols)
                    }

                    if let routine {
                        stats(for: routine)
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label(String(localized: "Delete ritual"), systemImage: "trash")
                                .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                                .foregroundStyle(Color.ember)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(Color.ember.opacity(0.1), in: .capsule)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background { CanvasBackground() }
            .safeAreaInset(edge: .bottom) {
                EditorSaveBar(title: routine == nil ? String(localized: "Add ritual") : String(localized: "Save changes"),
                              tone: tone, enabled: canSave,
                              hint: trimmedTitle.isEmpty ? String(localized: "Give it a name first") : nil,
                              action: save)
            }
            .navigationTitle(routine == nil ? String(localized: "New Ritual") : String(localized: "Edit Ritual"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EditorCloseButton { dismiss() } }
            .confirmationDialog(String(localized: "Delete this ritual and its history?"), isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button(String(localized: "Delete Ritual"), role: .destructive, action: delete)
            }
            .onAppear {
                if routine == nil { nameFocused = true }
            }
        }
        .tint(Color.ink)
    }

    // MARK: The live sticker

    private var preview: some View {
        let ink = tone == .indigo ? Color.white : tone.deep
        return VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Spacer()
                    Circle()
                        .strokeBorder(ink.opacity(0.5), lineWidth: 2.5)
                        .frame(width: 30, height: 30)
                }
                Spacer(minLength: 8)
                Text(trimmedTitle.isEmpty ? String(localized: "Your ritual") : trimmedTitle)
                    .font(.allo(size: 20, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.5)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .opacity(trimmedTitle.isEmpty ? 0.45 : 1)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(ink)
            .padding(16)
            .frame(width: 156, height: 156, alignment: .topLeading)
            .background(tone.fill, in: .rect(cornerRadius: 34, style: .continuous))
            .rotationEffect(.degrees(-3))
            .phaseAnimator([0, 1], trigger: wiggle) { view, phase in
                view.rotationEffect(.degrees(phase == 1 ? 4 : 0)).scaleEffect(phase == 1 ? 1.05 : 1)
            } animation: { _ in .spring(response: 0.3, dampingFraction: 0.5) }
            .shadow(color: tone.deep.opacity(0.18), radius: 18, y: 10)

            HStack(spacing: 6) {
                Image(systemName: period.symbol)
                Text(period.name + " · " + Weekdays.summary(for: weekdays))
                    .lineLimit(1)
            }
            .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
            .foregroundStyle(Color.inkSecondary)
            .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(tone.fill.opacity(0.16))
                .overlay(alignment: .topLeading) {
                    SparkleDot(color: tone.fill, size: 16).padding(22)
                }
                .overlay(alignment: .bottomTrailing) {
                    SparkleDot(color: StickerTone.pink.fill, size: 13).padding(.trailing, 30).padding(.bottom, 44)
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Preview: \(trimmedTitle.isEmpty ? String(localized: "Your ritual") : trimmedTitle)"))
    }

    private func stats(for routine: Routine) -> some View {
        HStack(spacing: 10) {
            stat(value: "\(routine.streak)", label: String(localized: "day streak"), tone: .pink, symbol: "flame.fill")
            stat(value: routine.consistency(days: 30).formatted(.percent.precision(.fractionLength(0))),
                 label: String(localized: "last 30 days"), tone: .mint, symbol: "chart.bar.fill")
        }
    }

    private func stat(value: String, label: String, tone: StickerTone, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: symbol).font(.system(size: 15, weight: .bold))
            Text(value)
                .font(.hero(34, weight: .heavy))
                .tracking(-1.2)
            Text(label)
                .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                .opacity(0.75)
        }
        .block(tone, cornerRadius: 26, padding: 16)
    }

    // MARK: Saving

    private func save() {
        guard canSave else { return }
        if let routine {
            routine.title = trimmedTitle
            routine.symbol = symbol
            routine.accent = accent
            routine.period = period
            routine.weekdays = weekdays.sorted()
        } else {
            let new = Routine(title: trimmedTitle, symbol: symbol, accent: accent, period: period,
                              weekdays: weekdays.sorted(),
                              order: (routines.map(\.order).max() ?? -1) + 1)
            context.insert(new)
        }
        try? context.save()
        SovaRefresh.changed(context)
        Haptics.success()
        if routine == nil {
            router.show(Toast(message: String(localized: "Added \(trimmedTitle) to your rituals")))
        }
        dismiss()
    }

    private func delete() {
        guard let routine else { return }
        context.delete(routine)
        try? context.save()
        SovaRefresh.changed(context)
        dismiss()
    }
}
