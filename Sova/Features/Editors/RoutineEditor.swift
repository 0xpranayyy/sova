import SwiftUI
import SwiftData

struct RoutineEditor: View {
    let routine: Routine?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Routine.order) private var routines: [Routine]

    @State private var title: String
    @State private var symbol: String
    @State private var accent: Accent
    @State private var period: DayPeriod
    @State private var weekdays: [Int]
    @State private var confirmDelete = false

    init(routine: Routine?) {
        self.routine = routine
        _title = State(initialValue: routine?.title ?? "")
        _symbol = State(initialValue: routine?.symbol ?? "sun.max")
        _accent = State(initialValue: routine?.accent ?? SovaTheme.current.accent)
        _period = State(initialValue: routine?.period ?? .morning)
        _weekdays = State(initialValue: routine?.weekdays ?? Array(1...7))
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        IconTile(symbol: symbol, accent: accent, size: 56, filled: true)
                            .contentTransition(.symbolEffect(.replace))
                        TextField("New habit", text: $title)
                            .font(.display(.title3))
                    }
                    .padding(.vertical, 4)
                }

                Section("Time of Day") {
                    Picker("Time of Day", selection: $period) {
                        ForEach(DayPeriod.allCases) { p in
                            Text(p.name).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    WeekdayPicker(selection: $weekdays, accent: accent)
                } header: {
                    Text("Repeat")
                } footer: {
                    Text(Weekdays.summary(for: weekdays))
                }

                Section("Icon") {
                    SymbolPicker(selection: $symbol, accent: accent, symbols: SymbolPicker.routineSymbols)
                }

                Section("Color") {
                    AccentPicker(selection: $accent)
                }

                if let routine {
                    Section {
                        LabeledContent("Current streak") {
                            Label("\(routine.streak) days", systemImage: "flame.fill")
                                .foregroundStyle(Accent.ember.color)
                        }
                        LabeledContent("Last 30 days") {
                            Text(routine.consistency(days: 30), format: .percent.precision(.fractionLength(0)))
                        }
                    }
                    Section {
                        Button("Delete Routine", systemImage: "trash", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { CanvasBackground() }
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { save() }
                        .disabled(trimmedTitle.isEmpty || weekdays.isEmpty)
                }
            }
            .confirmationDialog("Delete this routine and its history?", isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button("Delete Routine", role: .destructive) {
                    if let routine { context.delete(routine) }
                    dismiss()
                }
            }
        }
        .tint(accent.color)
    }

    private func save() {
        let target = routine ?? {
            let new = Routine(title: trimmedTitle, symbol: symbol, accent: accent, period: period,
                              order: (routines.map(\.order).max() ?? -1) + 1)
            context.insert(new)
            return new
        }()
        target.title = trimmedTitle
        target.symbol = symbol
        target.accent = accent
        target.period = period
        target.weekdays = weekdays.sorted()
        dismiss()
    }
}
