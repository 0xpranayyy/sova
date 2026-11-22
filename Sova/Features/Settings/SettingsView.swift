import SwiftUI
import SwiftData
import UserNotifications
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(PlusStore.self) private var store

    @AppStorage("userName") private var userName = ""
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("soundsOn") private var soundsOn = true
    @AppStorage("hasOnboarded") private var hasOnboarded = true
    @AppStorage("morningReminderOn") private var morningOn = false
    @AppStorage("morningReminderMinutes") private var morningMinutes = 8 * 60
    @AppStorage("eveningReminderOn") private var eveningOn = false
    @AppStorage("eveningReminderMinutes") private var eveningMinutes = 21 * 60
    @AppStorage(SovaSettings.Key.weekStart, store: SovaSettings.shared) private var weekStart = 0
    @AppStorage(SovaSettings.Key.alertOffset, store: SovaSettings.shared) private var alertOffset = 0
    @AppStorage(SovaSettings.Key.badgeOverdue, store: SovaSettings.shared) private var badgeOverdue = true
    @AppStorage(SovaSettings.Key.haptics) private var hapticsOn = true
    @AppStorage(SovaSettings.Key.iCloudSync, store: SovaSettings.shared) private var iCloudSync = false
    @State private var showSyncNote = false

    @State private var notificationsDenied = false
    @State private var confirmErase = false
    @State private var plusReason: PlusReason?
    @State private var showManage = false
    @State private var iconName: String? = UIApplication.shared.alternateIconName
    @State private var backupURL: URL?
    @State private var versionTaps = 0
    @State private var secret = 0
    @Query private var allTasks: [TaskItem]
    @Query private var allRoutines: [Routine]

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        hero
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        plusRow
                    }

                    Section {
                        Toggle(isOn: syncBinding) {
                            SettingsLabel(String(localized: "Sync with iCloud"), symbol: "icloud.fill", tone: .cyan,
                                          locked: !store.isPlus)
                        }
                    } footer: {
                        Text("Keep your tasks, rituals and goals on all your devices, privately in your own iCloud.")
                    }

                    Section(header: SettingsHeader(String(localized: "Your name"))) {
                        TextField("Used in your greeting", text: $userName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                    }

                    Section(header: SettingsHeader(String(localized: "Appearance"))) {
                        AppearanceTiles(selection: $appearanceRaw)
                            .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    }

                    Section(header: SettingsHeader(String(localized: "Theme"))) {
                        ThemeSwatches(themeRaw: $themeRaw)
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }

                    Section(header: SettingsHeader(String(localized: "App icon"))) {
                        iconPicker
                            .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                    }

                    Section {
                        Toggle(isOn: $soundsOn) {
                            SettingsLabel(String(localized: "Little sounds"), symbol: "speaker.wave.2.fill", tone: .pink)
                        }
                        .onChange(of: soundsOn) { if soundsOn { Sounds.play(.tick) } }
                        Toggle(isOn: $hapticsOn) {
                            SettingsLabel(String(localized: "Haptics"), symbol: "hand.tap.fill", tone: .orange)
                        }
                        .onChange(of: hapticsOn) { if hapticsOn { Haptics.pop(0.7) } }
                    } footer: {
                        Text("Soft taps and sounds when you check things off. Sounds follow your silent switch.")
                    }

                    Section(header: SettingsHeader(String(localized: "Calendar & alerts"))) {
                        Picker(selection: $weekStart) {
                            Text("System").tag(0)
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                        } label: {
                            SettingsLabel(String(localized: "Week starts on"), symbol: "calendar", tone: .lilac)
                        }
                        Picker(selection: $alertOffset) {
                            Text("At the time").tag(0)
                            Text("5 min before").tag(5)
                            Text("15 min before").tag(15)
                            Text("30 min before").tag(30)
                            Text("1 hour before").tag(60)
                        } label: {
                            SettingsLabel(String(localized: "Task alerts"), symbol: "bell.fill", tone: .yellow)
                        }
                        .onChange(of: alertOffset) { Task { await TaskAlerts.resync(in: context) } }
                        Toggle(isOn: $badgeOverdue) {
                            SettingsLabel(String(localized: "Overdue count on icon"), symbol: "app.badge.fill", tone: .pink)
                        }
                        .onChange(of: badgeOverdue) { SovaRefresh.updateBadge(context) }
                    }

                    Section {
                        reminderRow(title: String(localized: "Morning plan"), symbol: "sun.max.fill", accent: .marigold,
                                    isOn: $morningOn, minutes: $morningMinutes)
                        reminderRow(title: String(localized: "Evening review"), symbol: "moon.stars.fill", accent: .plum,
                                    isOn: $eveningOn, minutes: $eveningMinutes)
                    } header: {
                        SettingsHeader(String(localized: "Reminders"))
                    } footer: {
                        if notificationsDenied {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notifications are turned off for Sova.")
                                Button("Open iPhone Settings") {
                                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                                }
                                .font(.allo(.footnote, .semibold))
                            }
                        } else {
                            Text("Two quiet notes a day, at the times you choose. Nothing else.")
                        }
                    }

                    Section {
                        if let backupURL {
                            ShareLink(item: backupURL) {
                                SettingsLabel(String(localized: "Export a backup"), symbol: "square.and.arrow.up", tone: .mint)
                            }
                            .foregroundStyle(Color.ink)
                        } else {
                            SettingsLabel(String(localized: "Preparing backup…"), symbol: "hourglass", tone: .mint)
                                .foregroundStyle(Color.inkTertiary)
                        }
                    } header: {
                        SettingsHeader(String(localized: "Your data"))
                    } footer: {
                        Text("A readable file of all your tasks, rituals and goals. Save it to Files or send it anywhere.")
                    }

                    Section(header: SettingsHeader(String(localized: "Help"))) {
                        Button {
                            if Links.hasSupportEmail, let mail = URL(string: "mailto:\(Links.supportEmail)?subject=Sova%20feedback") {
                                openURL(mail)
                            } else {
                                openURL(Links.support)
                            }
                        } label: {
                            SettingsLabel(String(localized: "Help & feedback"), symbol: "envelope.fill", tone: .cyan)
                        }
                        Button {
                            if let url = Links.writeReview { openURL(url) } else { requestReview() }
                        } label: {
                            SettingsLabel(String(localized: "Rate Sova"), symbol: "star.fill", tone: .yellow)
                        }
                        Button {
                            Task { await store.restore() }
                        } label: {
                            SettingsLabel(String(localized: "Restore purchases"), symbol: "arrow.clockwise", tone: .lime)
                        }
                        Button { openURL(Links.privacy) } label: {
                            SettingsLabel(String(localized: "Privacy policy"), symbol: "hand.raised.fill", tone: .lilac)
                        }
                        Button { openURL(Links.terms) } label: {
                            SettingsLabel(String(localized: "Terms of use"), symbol: "doc.text.fill", tone: .lilac)
                        }
                    }
                    .foregroundStyle(Color.ink)

                    Section {
                        Button {
                            dismiss()
                            withAnimation(.smooth(duration: 0.6)) { hasOnboarded = false }
                        } label: {
                            SettingsLabel(String(localized: "Replay Welcome"), symbol: "hand.wave.fill", tone: .orange)
                        }
                        .foregroundStyle(Color.ink)
                    }

                    Section {
                        Button(role: .destructive) { confirmErase = true } label: {
                            SettingsLabel(String(localized: "Erase All Data"), symbol: "trash.fill", tone: .pink, titleColor: .ember)
                        }
                    } footer: {
                        Text(iCloudSync && store.isPlus ? "This erases your data everywhere it syncs."
                                                        : "Everything you add stays on this iPhone.")
                    }
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .background { CanvasBackground() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { dismiss() }
                }
            }
            .sheet(item: $plusReason) { PlusView(reason: $0) }
            .alert(iCloudSync ? "iCloud sync is on" : "iCloud sync is off", isPresented: $showSyncNote) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("It takes effect the next time you open Sova.")
            }
            .manageSubscriptionsSheet(isPresented: $showManage)
            .confirmationDialog("Erase everything?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase All Data", role: .destructive, action: eraseAll)
            } message: {
                Text("All tasks, goals and routines will be deleted. This can’t be undone.")
            }
            .onChange(of: morningOn) { applyReminders() }
            .onChange(of: eveningOn) { applyReminders() }
            .onChange(of: morningMinutes) { applyReminders() }
            .onChange(of: eveningMinutes) { applyReminders() }
            .task {
                await refreshPermission()
                backupURL = try? Backup.write(from: context)
            }
        }
        .tint((SovaTheme(rawValue: themeRaw) ?? .ember).accent.color)
    }

    // MARK: Hero

    /// You and Sova at a glance: the owl, your name and a few numbers.
    private var hero: some View {
        let done = allTasks.filter(\.isDone).count
        let streak = allRoutines.map(\.streak).max() ?? 0
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    MonoCaps(store.isPlus ? String(localized: "Sova Plus") : String(localized: "Sova"),
                             color: StickerTone.indigo.deep)
                    Text(userName.isEmpty ? String(localized: "Hello!") : String(localized: "Hi, \(userName)!"))
                        .font(.hero(34, weight: .heavy))
                        .tracking(-1.2)
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Button {
                        versionTaps += 1
                        Haptics.pop(0.4)
                        if versionTaps == 7 {
                            versionTaps = 0
                            secret += 1
                            Haptics.owl()
                            Haptics.celebrate()
                        }
                    } label: {
                        Text(secret > 0 ? String(localized: "🦉 Hoo! You found the owl's office.")
                             : versionTaps >= 3 ? String(localized: "\(7 - versionTaps) more…")
                             : String(localized: "Version \(version)"))
                            .font(.allo(.footnote, .bold))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .contentTransition(.numericText())
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                OwlMark(size: 70, happy: versionTaps > 0 || streak > 1, bodyColor: StickerTone.yellow.fill,
                        eyeColor: StickerTone.indigo.fill, pupilColor: StickerTone.yellow.fill,
                        bellyColor: Color.owlBelly, celebrate: secret)
                    .rotationEffect(.degrees(8))
                    .overlay { SparkleBurst(trigger: secret, radius: CGSize(width: 110, height: 90), count: 14) }
            }
            HStack(spacing: 8) {
                TiltPill(text: String(localized: "\(done) tasks done"), tone: .yellow, tilt: -3, size: 12)
                if streak > 1 {
                    TiltPill(text: String(localized: "🔥 \(streak)-day streak"), tone: .mint, tilt: 3, size: 12)
                }
                TiltPill(text: String(localized: "\(allRoutines.count) rituals"), tone: .pink, tilt: -2, size: 12)
            }
        }
        .padding(20)
        .background(StickerTone.indigo.fill.shadow(.drop(color: StickerTone.indigo.shadow, radius: 18, y: 10)),
                    in: .rect(cornerRadius: Radius.hero, style: .continuous))
        .overlay(alignment: .topLeading) {
            SparkleDot(color: StickerTone.pink.fill, size: 13).padding(.leading, 210).padding(.top, 18)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: versionTaps)
    }

    // MARK: Plus

    private var syncBinding: Binding<Bool> {
        Binding(
            get: { iCloudSync && store.isPlus },
            set: { on in
                if on && !store.isPlus { plusReason = .sync; return }
                iCloudSync = on
                showSyncNote = true
            }
        )
    }

    private var plusRow: some View {
        Button {
            if store.isLifetime { return }
            if store.isPlus { showManage = true } else { plusReason = .general }
        } label: {
            HStack(spacing: 14) {
                OwlMark(size: 34, happy: store.isPlus, blinks: false,
                        bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly)
                    .frame(width: 52, height: 52)
                    .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Sova").font(.display(.title3)).foregroundStyle(Color.ink)
                        TiltPill(text: "Plus", tone: .yellow, tilt: -5, size: 12)
                    }
                    Text(store.isLifetime ? String(localized: "Lifetime. Thank you! 💛")
                         : store.isPlus ? String(localized: "Active. Tap to manage. 💛")
                                      : String(localized: "Unlimited rituals and goals, iCloud sync, app icons"))
                        .font(.allo(.footnote, .medium))
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.heavy))
                    .foregroundStyle(Color.inkTertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    // MARK: App icon

    private var iconPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 18) {
                iconTile(name: nil, preview: "IconPreview-Default", title: String(localized: "Sova"))
                iconTile(name: "AppIcon-Indigo", preview: "IconPreview-Indigo", title: String(localized: "Sunny"))
                iconTile(name: "AppIcon-NightOwl", preview: "IconPreview-NightOwl", title: String(localized: "Night Owl"))
                iconTile(name: "AppIcon-Shades", preview: "IconPreview-Shades", title: String(localized: "Shades"))
                iconTile(name: "AppIcon-Scholar", preview: "IconPreview-Scholar", title: String(localized: "Scholar"))
                iconTile(name: "AppIcon-Party", preview: "IconPreview-Party", title: String(localized: "Party"))
                iconTile(name: "AppIcon-Royal", preview: "IconPreview-Royal", title: String(localized: "Royal"))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func iconTile(name: String?, preview: String, title: String) -> some View {
        let selected = iconName == name
        let locked = name != nil && !store.isPlus
        return Button {
            guard !selected else { return }
            if locked { plusReason = .icons; return }
            UIApplication.shared.setAlternateIconName(name) { error in
                if error == nil { iconName = name }
            }
        } label: {
            VStack(spacing: 6) {
                Image(preview)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(.rect(cornerRadius: 15, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? Color.ink : .clear, lineWidth: 3)
                            .padding(-5)
                    }
                    .overlay(alignment: .topTrailing) {
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(StickerTone.indigo.deep)
                                .padding(5)
                                .background(StickerTone.indigo.fill, in: .circle)
                                .offset(x: 6, y: -6)
                        }
                    }
                Text(title)
                    .font(.allo(.caption, .bold))
                    .foregroundStyle(selected ? Color.ink : Color.inkSecondary)
            }
            .padding(.top, 6)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func reminderRow(title: String, symbol: String, accent: Accent,
                             isOn: Binding<Bool>, minutes: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Toggle(isOn: isOn.animation(.smooth)) {
                SettingsLabel(title, symbol: symbol, tone: StickerTone(accent))
            }
            if isOn.wrappedValue {
                DatePicker(title, selection: timeBinding(minutes), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .transition(.opacity)
            }
        }
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { Reminders.time(hour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60) },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }

    private func applyReminders() {
        let morning = morningOn ? Reminders.time(hour: morningMinutes / 60, minute: morningMinutes % 60) : nil
        let evening = eveningOn ? Reminders.time(hour: eveningMinutes / 60, minute: eveningMinutes % 60) : nil
        guard morning != nil || evening != nil else {
            Reminders.schedule(morning: nil, evening: nil)
            return
        }
        Task {
            let granted = await Reminders.enable(morning: morning, evening: evening)
            if !granted {
                morningOn = false
                eveningOn = false
                notificationsDenied = true
            }
        }
    }

    private func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsDenied = settings.authorizationStatus == .denied
    }

    private func eraseAll() {
        try? context.delete(model: TaskItem.self)
        try? context.delete(model: Milestone.self)
        try? context.delete(model: Goal.self)
        try? context.delete(model: Routine.self)
        try? context.save()
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("sova.task.") || $0.hasPrefix("sova.ritual.") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
        SovaRefresh.changed(context)
    }
}

// MARK: - Pieces

/// A settings row label with a small tilted sticker icon in Sova's colors.
struct SettingsLabel: View {
    let title: String
    let symbol: String
    let tone: StickerTone
    var locked = false
    var titleColor: Color = .ink

    init(_ title: String, symbol: String, tone: StickerTone, locked: Bool = false, titleColor: Color = .ink) {
        self.title = title
        self.symbol = symbol
        self.tone = tone
        self.locked = locked
        self.titleColor = titleColor
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                .frame(width: 32, height: 32)
                .background(tone.fill.shadow(.drop(color: tone.shadow, radius: 4, y: 2)),
                            in: .rect(cornerRadius: 10, style: .continuous))
                .rotationEffect(.degrees(-4))
            Text(title)
                .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                .tracking(-0.2)
                .foregroundStyle(titleColor)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(StickerTone.indigo.deep)
                    .padding(4)
                    .background(StickerTone.indigo.fill, in: .circle)
                    .accessibilityLabel(String(localized: "Sova Plus"))
            }
        }
    }
}

/// A section header in Sova's caps voice.
struct SettingsHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        MonoCaps(title)
            .padding(.leading, -4)
    }
}

/// System, Light or Dark, as three little screen previews.
private struct AppearanceTiles: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Appearance.allCases) { option in
                let on = selection == option.rawValue
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selection = option.rawValue }
                } label: {
                    VStack(spacing: 8) {
                        preview(option)
                            .frame(height: 74)
                            .clipShape(.rect(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(on ? Color.ink : .clear, lineWidth: 2.5)
                                    .padding(-4)
                            }
                            .scaleEffect(on ? 1 : 0.96)
                        Text(option.name)
                            .font(.allo(size: 13, weight: .heavy, relativeTo: .caption))
                            .foregroundStyle(on ? Color.ink : Color.inkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }

    @ViewBuilder
    private func preview(_ option: Appearance) -> some View {
        switch option.rawValue {
        case Appearance.light.rawValue: mini(paper: Color(hex: 0xFCFCFA), card: .white, ink: Color(hex: 0x15102E))
        case Appearance.dark.rawValue: mini(paper: Color(hex: 0x0E0B1F), card: Color(hex: 0x1B1636), ink: Color(hex: 0xF4F1FF))
        default:
            HStack(spacing: 0) {
                mini(paper: Color(hex: 0xFCFCFA), card: .white, ink: Color(hex: 0x15102E))
                mini(paper: Color(hex: 0x0E0B1F), card: Color(hex: 0x1B1636), ink: Color(hex: 0xF4F1FF))
            }
        }
    }

    /// A tiny Today screen: a title bar, the indigo stage and two cards.
    private func mini(paper: Color, card: Color, ink: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Capsule().fill(ink.opacity(0.8)).frame(width: 26, height: 5)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(StickerTone.indigo.fill)
                .frame(height: 22)
                .overlay(Circle().fill(StickerTone.yellow.fill).frame(width: 10, height: 10))
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(card).frame(height: 8)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(StickerTone.yellow.fill).frame(height: 8)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(paper)
    }
}
