import SwiftUI

/// Today on the wrist: the owl ring, what's next, rituals and tasks.
/// Tap anything to tick it.
struct TodayScreen: View {
    @Environment(WatchStore.self) private var store

    private var day: WatchDay { store.day }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                header
                    .listRowBackground(Color.clear)

                if !store.hasData {
                    note(String(localized: "Open Sova on your iPhone to get started."))
                } else if !day.isFromToday {
                    note(String(localized: "Open Sova on your iPhone to load today."))
                } else if day.total == 0 {
                    note(String(localized: "Nothing planned today 🦉"))
                }

                if day.isFromToday, let next = day.next, !day.allDone {
                    UpNextCard(next: next)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                if day.isFromToday && !day.rituals.isEmpty {
                    Section {
                        RitualGrid(rituals: day.rituals)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    } header: {
                        SectionTitle(text: String(localized: "Rituals"))
                    }
                }

                if day.isFromToday && !day.tasks.isEmpty {
                    Section {
                        ForEach(day.tasks) { task in
                            TaskRow(task: task) { store.toggleTask(task.id) }
                        }
                    } header: {
                        SectionTitle(text: String(localized: "Tasks"))
                    }
                }

                AddTaskButton()
                    .listRowBackground(Color.clear)

                if store.hasData {
                    Text("Updated \(day.date.formatted(date: .omitted, time: .shortened))")
                        .font(.sova(11, .medium, relativeTo: .caption2))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .containerBackground(WatchPalette.indigo.gradient, for: .navigation)
            .navigationTitle("Sova")
        }
        .fullScreenCover(isPresented: $store.celebrating) {
            DayDoneView(day: day) { store.celebrating = false }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            OwlRing(progress: day.isFromToday ? day.progress : 0, happy: day.isFromToday && day.allDone, live: true)
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 1) {
                Text(greeting)
                    .font(.sova(11, .heavy, relativeTo: .caption2))
                    .textCase(.uppercase)
                    .foregroundStyle(WatchPalette.yellow.opacity(0.85))
                    .lineLimit(1)
                Text(day.isFromToday ? "\(day.done) of \(day.total)" : "–")
                    .font(.sova(24, .heavy, relativeTo: .title2))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                if day.streak > 1 {
                    Text("🔥 \(day.streak)-day streak")
                        .font(.sova(11, .bold, relativeTo: .caption2))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        let base: String = switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Still up")
        }
        return day.name.isEmpty ? base : base + ", " + day.name
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.sova(14, .bold, relativeTo: .footnote))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
    }
}

private struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.sova(13, .heavy, relativeTo: .footnote))
            .foregroundStyle(.white)
            .textCase(nil)
    }
}

/// The one thing to do next, as a yellow sticker.
private struct UpNextCard: View {
    let next: WatchNext

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("UP NEXT")
                .font(.sova(10, .heavy, relativeTo: .caption2))
                .tracking(1)
                .opacity(0.7)
            Text(next.title)
                .font(.sova(17, .heavy, relativeTo: .headline))
                .lineLimit(2)
            if let time = next.time {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.sova(12, .bold, relativeTo: .caption))
                    .opacity(0.75)
            }
        }
        .foregroundStyle(WatchTone.yellow.deep)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(WatchTone.yellow.fill, in: .rect(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Today's rituals as colored tiles. Plain ones tick on tap; counted ones
/// (like water) open a page where the Digital Crown counts.
private struct RitualGrid: View {
    let rituals: [WatchRitual]
    @Environment(WatchStore.self) private var store

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
            ForEach(rituals) { ritual in
                if ritual.isCounted {
                    NavigationLink {
                        RitualDetail(ritualID: ritual.id)
                    } label: {
                        RitualTile(ritual: ritual)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { store.tapRitual(ritual.id) } label: {
                        RitualTile(ritual: ritual)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RitualTile: View {
    let ritual: WatchRitual

    var body: some View {
        let tone = WatchTone(name: ritual.tone)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: ritual.symbol)
                    .font(.system(size: 13, weight: .bold))
                Spacer(minLength: 0)
                Image(systemName: ritual.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .bold))
            }
            Text(ritual.title)
                .font(.sova(12, .heavy, relativeTo: .caption))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if ritual.isCounted {
                Text("\(ritual.tally) of \(ritual.target)")
                    .font(.sova(10, .bold, relativeTo: .caption2))
                    .opacity(0.8)
            }
        }
        .foregroundStyle(ritual.done ? tone.deep : .white)
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        .background(ritual.done ? tone.fill : tone.fill.opacity(0.22), in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(tone.fill.opacity(ritual.done ? 0 : 0.6), lineWidth: 1.5))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: ritual.done)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(ritual.done ? [.isButton, .isSelected] : .isButton)
    }
}

private struct TaskRow: View {
    let task: WatchTask
    let onToggle: () -> Void

    var body: some View {
        let tone = WatchTone(name: task.tone)
        Button(action: onToggle) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(task.done ? .clear : tone.fill, lineWidth: 2)
                        .background(task.done ? tone.fill : .clear, in: .rect(cornerRadius: 7, style: .continuous))
                    if task.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(tone.deep)
                    }
                }
                .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3) {
                        if !task.marks.isEmpty && !task.done {
                            Text(task.marks).foregroundStyle(WatchPalette.pink)
                        }
                        Text(task.title)
                            .strikethrough(task.done)
                            .lineLimit(2)
                    }
                    .font(.sova(15, .bold, relativeTo: .body))
                    .foregroundStyle(task.done ? Color.white.opacity(0.5) : Color.white)
                    if let time = task.time {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.sova(11, .bold, relativeTo: .caption2))
                            .foregroundStyle(task.overdue && !task.done ? WatchPalette.pink : .white.opacity(0.55))
                    } else if task.overdue && !task.done {
                        Text("Overdue")
                            .font(.sova(11, .bold, relativeTo: .caption2))
                            .foregroundStyle(WatchPalette.pink)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
        .accessibilityAddTraits(task.done ? .isSelected : [])
    }
}

/// Dictate or scribble a task; the iPhone reads the day and time from it.
private struct AddTaskButton: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        TextFieldLink(prompt: Text("Call Mom tomorrow 6pm")) {
            Label("New task", systemImage: "plus")
                .font(.sova(15, .heavy, relativeTo: .body))
                .foregroundStyle(WatchTone.indigo.deep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(WatchPalette.yellow.opacity(0.18), in: .capsule)
        } onSubmit: { text in
            store.addTask(text)
        }
        .buttonStyle(.plain)
    }
}
