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
    @State private var target: Int
    @State private var reminderOn: Bool
    @State private var reminderTime: Date
    @State private var shareImage: Image?
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
        _target = State(initialValue: routine?.target ?? 1)
        let minutes = routine?.reminderMinutes ?? -1
        _reminderOn = State(initialValue: minutes >= 0)
        _reminderTime = State(initialValue: Reminders.time(hour: minutes >= 0 ? minutes / 60 : 8,
                                                           minute: minutes >= 0 ? minutes % 60 : 0))
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

                    EditorCard(title: String(localized: "Each day"),
                               footer: target == 1 ? String(localized: "Done with one tap.")
                                                   : String(localized: "Tap \(target) times to finish it, like glasses of water or sets.")) {
                        FlowChips(choices: [1, 2, 3, 4, 5, 6, 8, 10], selection: $target, tone: tone) { n in
                            n == 1 ? String(localized: "Once") : "\(n)×"
                        }
                    }

                    EditorCard(title: String(localized: "Reminder"),
                               footer: reminderOn ? String(localized: "A nudge at \(reminderTime.formatted(date: .omitted, time: .shortened)) on the days it's due, with a Done button.")
                                                  : String(localized: "No reminder.")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $reminderOn.animation(.spring(response: 0.4, dampingFraction: 0.8))) {
                                Label(String(localized: "Remind me"), systemImage: "bell.badge.fill")
                                    .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                                    .foregroundStyle(Color.ink)
                            }
                            .tint(tone == .yellow || tone == .lime ? tone.deep : tone.fill)
                            if reminderOn {
                                DatePicker(String(localized: "Time"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 140)
                                    .clipped()
                                    .transition(.opacity)
                            }
                        }
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
                .readableColumn()
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
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                stat(value: "\(routine.streak)", label: String(localized: "day streak"), tone: .pink, symbol: "flame.fill")
                stat(value: routine.consistency(days: 30).formatted(.percent.precision(.fractionLength(0))),
                     label: String(localized: "last 30 days"), tone: .mint, symbol: "chart.bar.fill")
            }
            if let shareImage, routine.streak > 0 {
                ShareLink(item: shareImage,
                          preview: SharePreview(String(localized: "My \(routine.title) streak"), image: shareImage)) {
                    Label(String(localized: "Share my streak"), systemImage: "square.and.arrow.up")
                        .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.surface, in: .capsule)
                        .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1.5))
                }
                .buttonStyle(.pressable)
            }
        }
        .task {
            // Draw the share card once, off the main render.
            let renderer = ImageRenderer(content: StreakCard(title: routine.title, symbol: routine.symbol,
                                                             tone: StickerTone(routine.accent), streak: routine.streak))
            renderer.scale = 3
            if let image = renderer.uiImage { shareImage = Image(uiImage: image) }
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

    private var reminderMinutes: Int {
        guard reminderOn else { return -1 }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return (parts.hour ?? 8) * 60 + (parts.minute ?? 0)
    }

    private func save() {
        guard canSave else { return }
        if let routine {
            routine.title = trimmedTitle
            routine.symbol = symbol
            routine.accent = accent
            routine.period = period
            routine.weekdays = weekdays.sorted()
            routine.target = target
            routine.reminderMinutes = reminderMinutes
            RitualReminders.schedule(routine)
        } else {
            let new = Routine(title: trimmedTitle, symbol: symbol, accent: accent, period: period,
                              weekdays: weekdays.sorted(),
                              order: (routines.map(\.order).max() ?? -1) + 1)
            new.target = target
            new.reminderMinutes = reminderMinutes
            context.insert(new)
            RitualReminders.schedule(new)
        }
        if reminderOn { Task { await TaskAlerts.requestPermissionIfNeeded() } }
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
        RitualReminders.cancel(routine)
        context.delete(routine)
        try? context.save()
        SovaRefresh.changed(context)
        dismiss()
    }
}

/// A ritual's streak as a square sticker card, to share.
struct StreakCard: View {
    let title: String
    let symbol: String
    let tone: StickerTone
    let streak: Int

    var body: some View {
        let ink = tone == .indigo ? Color.white : tone.deep
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 64, height: 64)
                    .background(ink.opacity(0.14), in: .rect(cornerRadius: 20, style: .continuous))
                    .rotationEffect(.degrees(-6))
                Spacer()
                OwlMark(size: 70, happy: true, blinks: false, reactsToTap: false)
                    .rotationEffect(.degrees(8))
            }
            Spacer()
            Text("\(streak)")
                .font(.hero(120, weight: .heavy))
                .tracking(-6)
            Text(streak == 1 ? String(localized: "day of") : String(localized: "days of"))
                .font(.allo(size: 26, weight: .heavy))
                .opacity(0.7)
            Text(title)
                .font(.allo(size: 34, weight: .heavy))
                .tracking(-1)
                .lineLimit(2)
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                Text(String(localized: "Kept with Sova"))
            }
            .font(.allo(size: 18, weight: .heavy))
            .opacity(0.75)
        }
        .foregroundStyle(ink)
        .padding(36)
        .frame(width: 400, height: 500)
        .background(tone.fill)
    }
}
