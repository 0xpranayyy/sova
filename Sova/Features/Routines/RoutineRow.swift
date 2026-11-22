import SwiftUI
import SwiftData

/// A ritual as a block in its color: a tilted icon tile, its name and
/// schedule, the last seven days as chunky dots, a streak chip and a big
/// check that wiggles when ticked.
struct RoutineRow: View {
    let routine: Routine
    var onOpen: () -> Void

    @State private var wiggle = 0
    @State private var cheers = 0
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @State private var confirmDelete = false

    private var scheduleText: String {
        let days: String = Weekdays.summary(for: routine.weekdays)
        guard routine.isCounted else { return days }
        return "\(routine.tally(on: .now))/\(routine.target) · " + days
    }

    /// Streaks worth a little party.
    private static let milestones: Set<Int> = [3, 7, 14, 21, 30, 50, 100, 200, 365]

    /// The name with its streak chip, or a slipping tag.
    private func titleLine(ink: Color, done: Bool) -> some View {
        HStack(spacing: 6) {
            Text(routine.title)
                .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                .tracking(-0.4)
                .lineLimit(2)
            if routine.streak > 1 {
                Text("\(Image(systemName: "flame.fill")) \(routine.streak)")
                    .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(ink.opacity(0.12), in: .capsule)
                    .rotationEffect(.degrees(-4))
                    .accessibilityLabel(String(localized: "\(routine.streak) day streak"))
            } else if !done && routine.isSlipping {
                SlippingTag(ink: ink)
            }
        }
    }

    var body: some View {
        let tone: StickerTone = StickerTone(routine.accent)
        let done: Bool = routine.isDone(on: .now)
        let scheduled: Bool = routine.isScheduled(on: .now)
        // Open rituals are a soft wash of their color; done ones fill in.
        let ink: Color = inkColor(tone: tone, done: done)
        let actionName: String = done ? String(localized: "Mark as not done") : String(localized: "Mark as done")
        decorated(row(tone: tone, ink: ink, done: done, scheduled: scheduled), tone: tone, done: done)
            .contextMenu { menu(done: done, scheduled: scheduled) }
            .confirmationDialog(String(localized: "Delete this ritual and its history?"), isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button(String(localized: "Delete Ritual"), role: .destructive, action: delete)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint(String(localized: "Opens the ritual"))
            .accessibilityAction(named: Text(actionName)) {
                guard scheduled else { return }
                toggle()
            }
    }

    private func inkColor(tone: StickerTone, done: Bool) -> Color {
        guard tone == .indigo else { return tone.deep }
        return done ? Color.white : StickerTone.indigo.fill
    }

    private func icon(tone: StickerTone, ink: Color, done: Bool) -> some View {
        let symbolColor: Color = done ? ink : (tone == .indigo ? Color.white : tone.deep)
        let fill: AnyShapeStyle = done ? AnyShapeStyle(Color.white.opacity(0.3))
                                       : AnyShapeStyle(tone.fill.shadow(.drop(color: tone.shadow, radius: 5, y: 3)))
        return Image(systemName: routine.symbol)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(symbolColor)
            .frame(width: 48, height: 48)
            .background(fill, in: .rect(cornerRadius: 16, style: .continuous))
            .rotationEffect(.degrees(-6))
    }

    private func row(tone: StickerTone, ink: Color, done: Bool, scheduled: Bool) -> some View {
        HStack(spacing: 14) {
            icon(tone: tone, ink: ink, done: done)
            VStack(alignment: .leading, spacing: 7) {
                titleLine(ink: ink, done: done)
                HStack(spacing: 8) {
                    WeekTrack(routine: routine, color: ink)
                    Text(scheduleText)
                        .font(.allo(size: 10.5, weight: .heavy, relativeTo: .caption2))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .opacity(0.7)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            check(tone: tone, ink: ink, done: done, scheduled: scheduled)
        }
        .foregroundStyle(ink)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func check(tone: StickerTone, ink: Color, done: Bool, scheduled: Bool) -> some View {
        if !scheduled {
            MonoCaps(String(localized: "Rest"), color: ink.opacity(0.6))
                .frame(width: 44)
        } else if routine.isCounted {
            CountCheck(routine: routine, ink: ink, fill: tone.fill, size: 36, action: toggle)
        } else {
            CheckButton(isOn: done, color: ink, round: true, size: 36, emphasized: true,
                        checkColor: tone.fill, label: routine.title, action: toggle)
        }
    }

    @ViewBuilder
    private func background(tone: StickerTone, done: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        if done {
            shape.fill(tone.fill.shadow(.drop(color: tone.shadow, radius: 12, y: 7)))
            shape.fill(LinearGradient(colors: [Color.white.opacity(0.2), .clear], startPoint: .top, endPoint: .center))
            shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.5), .clear],
                                              startPoint: .top, endPoint: .center), lineWidth: 1.2)
        } else {
            shape.fill(Color.surface)
            shape.fill(tone.fill.opacity(0.24))
            shape.strokeBorder(tone.fill.opacity(0.65), lineWidth: 1.5)
        }
    }

    private func decorated(_ content: some View, tone: StickerTone, done: Bool) -> some View {
        content
            .background { background(tone: tone, done: done) }
            .wiggle(on: wiggle, angle: 0.48, swell: 0.008)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: done)
            .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 150, height: 70), count: 12) }
            .contentShape(.rect)
            .onTapGesture(perform: onOpen)
    }

    @ViewBuilder
    private func menu(done: Bool, scheduled: Bool) -> some View {
        if scheduled {
            Button(done ? String(localized: "Mark as Not Done") : String(localized: "Mark as Done"),
                   systemImage: done ? "arrow.uturn.backward" : "checkmark.circle", action: toggle)
        }
        Button(String(localized: "Edit Ritual"), systemImage: "pencil", action: onOpen)
        Divider()
        Button(String(localized: "Delete Ritual"), systemImage: "trash", role: .destructive) { confirmDelete = true }
    }

    private func delete() {
        RitualReminders.cancel(routine)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { context.delete(routine) }
        SovaRefresh.changed(context)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { routine.advance(on: .now) }
        SovaRefresh.changed(context)
        guard routine.isDone(on: .now) else { return }
        wiggle += 1
        let streak = routine.streak
        // A streak milestone gets sparkles, the flourish and a cheer.
        let key = "celebratedStreak-" + routine.entityID
        let celebrated = UserDefaults.standard.integer(forKey: key)
        if Self.milestones.contains(streak), streak != celebrated {
            UserDefaults.standard.set(streak, forKey: key)
            cheers += 1
            Haptics.celebrate()
            router.show(Toast(message: String(localized: "\(streak)-day streak on \(routine.title)! 🔥")))
        } else if routine.title.lowercased().contains("owl") {
            Haptics.owl()
        }
    }
}

/// The last seven days as chunky dots; today is outlined.
struct WeekTrack: View {
    let routine: Routine
    var color: Color = .ink

    var body: some View {
        HStack(spacing: 4) {
            ForEach(-6...0, id: \.self) { offset in
                let day = Date.now.adding(days: offset)
                let done = routine.isDone(on: day)
                let scheduled = routine.isScheduled(on: day)
                Circle()
                    .fill(done ? color : color.opacity(scheduled ? 0.2 : 0.07))
                    .overlay {
                        if offset == 0 {
                            Circle().strokeBorder(color, lineWidth: 1.8)
                        }
                    }
                    .frame(width: 11, height: 11)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Last 7 days")
        .accessibilityValue("\((-6...0).filter { routine.isDone(on: Date.now.adding(days: $0)) }.count) of 7 done")
    }
}

/// A gentle tag for a ritual that missed 2 of its last 3 days.
struct SlippingTag: View {
    let ink: Color

    var body: some View {
        Text("\(Image(systemName: "arrow.down.right")) \(String(localized: "slipping"))")
            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(ink.opacity(0.12), in: .capsule)
            .rotationEffect(.degrees(3))
            .accessibilityLabel(String(localized: "Slipping: missed 2 of the last 3 days"))
    }
}

