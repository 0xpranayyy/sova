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
                            Label {
                                HStack(spacing: 6) {
                                    Text("Sync with iCloud")
                                    if !store.isPlus {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2.weight(.heavy))
                                            .foregroundStyle(Color.inkTertiary)
                                    }
                                }
                            } icon: {
                                Image(systemName: "icloud")
                            }
                        }
                    } footer: {
                        Text("Keep your tasks, rituals and goals on all your devices, privately in your own iCloud.")
                    }

                    Section("Your name") {
                        TextField("Used in your greeting", text: $userName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                    }

                    Section("Appearance") {
                        Picker("Appearance", selection: $appearanceRaw) {
                            ForEach(Appearance.allCases) { Text($0.name).tag($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .sovaFeedback(.selection, trigger: appearanceRaw)
                    }

                    Section("Theme") {
                        ThemeSwatches(themeRaw: $themeRaw)
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }

                    Section("App icon") {
                        iconPicker
                            .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                    }

                    Section {
                        Toggle(isOn: $soundsOn) {
                            Label("Little sounds", systemImage: "speaker.wave.2")
                        }
                        .onChange(of: soundsOn) { if soundsOn { Sounds.play(.tick) } }
                        Toggle(isOn: $hapticsOn) {
                            Label("Haptics", systemImage: "hand.tap")
                        }
                        .onChange(of: hapticsOn) { if hapticsOn { Haptics.pop(0.7) } }
                    } footer: {
                        Text("Soft taps and sounds when you check things off. Sounds follow your silent switch.")
                    }

                    Section("Calendar & alerts") {
                        Picker(selection: $weekStart) {
                            Text("System").tag(0)
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                        } label: {
                            Label("Week starts on", systemImage: "calendar")
                        }
                        Picker(selection: $alertOffset) {
                            Text("At the time").tag(0)
                            Text("5 min before").tag(5)
                            Text("15 min before").tag(15)
                            Text("30 min before").tag(30)
                            Text("1 hour before").tag(60)
                        } label: {
                            Label("Task alerts", systemImage: "bell")
                        }
                        .onChange(of: alertOffset) { Task { await TaskAlerts.resync(in: context) } }
                        Toggle(isOn: $badgeOverdue) {
                            Label("Overdue count on icon", systemImage: "app.badge")
                        }
                        .onChange(of: badgeOverdue) { SovaRefresh.updateBadge(context) }
                    }

                    Section {
                        reminderRow(title: String(localized: "Morning plan"), symbol: "sun.max", accent: .marigold,
                                    isOn: $morningOn, minutes: $morningMinutes)
                        reminderRow(title: String(localized: "Evening review"), symbol: "moon", accent: .plum,
                                    isOn: $eveningOn, minutes: $eveningMinutes)
                    } header: {
                        Text("Reminders")
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
                                Label("Export a backup", systemImage: "square.and.arrow.up")
                            }
                            .foregroundStyle(Color.ink)
                        } else {
                            Label("Preparing backup…", systemImage: "square.and.arrow.up")
                                .foregroundStyle(Color.inkTertiary)
                        }
                    } header: {
                        Text("Your data")
                    } footer: {
                        Text("A readable file of all your tasks, rituals and goals. Save it to Files or send it anywhere.")
                    }

                    Section("Help") {
                        Button("Help & feedback", systemImage: "envelope") {
                            if Links.hasSupportEmail, let mail = URL(string: "mailto:\(Links.supportEmail)?subject=Sova%20feedback") {
                                openURL(mail)
                            } else {
                                openURL(Links.support)
                            }
                        }
                        Button("Rate Sova", systemImage: "star") {
                            if let url = Links.writeReview { openURL(url) } else { requestReview() }
                        }
                        Button("Restore purchases", systemImage: "arrow.clockwise") {
                            Task { await store.restore() }
                        }
                        Button("Privacy policy", systemImage: "hand.raised") { openURL(Links.privacy) }
                        Button("Terms of use", systemImage: "doc.text") { openURL(Links.terms) }
                    }
                    .foregroundStyle(Color.ink)

                    Section {
                        Button("Replay Welcome", systemImage: "hand.wave") {
                            dismiss()
                            withAnimation(.smooth(duration: 0.6)) { hasOnboarded = false }
                        }
                        .foregroundStyle(Color.ink)
                    }

                    Section {
                        Button("Erase All Data", systemImage: "trash", role: .destructive) { confirmErase = true }
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
                        bellyColor: Color(hex: 0xFFF4A8), celebrate: secret)
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
        .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 30, style: .continuous))
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
            if store.isPlus { showManage = true } else { plusReason = .general }
        } label: {
            HStack(spacing: 14) {
                OwlMark(size: 34, happy: store.isPlus, blinks: false,
                        bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8))
                    .frame(width: 52, height: 52)
                    .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Sova").font(.display(.title3)).foregroundStyle(Color.ink)
                        TiltPill(text: "Plus", tone: .yellow, tilt: -5, size: 12)
                    }
                    Text(store.isPlus ? String(localized: "Active. Thank you! 💛")
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
        HStack(spacing: 18) {
            iconTile(name: nil, preview: "IconPreview-Default", title: String(localized: "Sova"))
            iconTile(name: "AppIcon-Indigo", preview: "IconPreview-Indigo", title: String(localized: "Sunny"))
            Spacer()
        }
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
            IconTile(symbol: symbol, accent: accent, size: 32)
            Toggle(title, isOn: isOn.animation(.smooth))
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
