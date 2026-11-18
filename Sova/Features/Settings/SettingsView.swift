import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    @AppStorage("userName") private var userName = ""
    @AppStorage("theme") private var themeRaw = SovaTheme.lime.rawValue
    @AppStorage("hasOnboarded") private var hasOnboarded = true
    @AppStorage("morningReminderOn") private var morningOn = false
    @AppStorage("morningReminderMinutes") private var morningMinutes = 8 * 60
    @AppStorage("eveningReminderOn") private var eveningOn = false
    @AppStorage("eveningReminderMinutes") private var eveningMinutes = 21 * 60

    @State private var notificationsDenied = false
    @State private var confirmErase = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        OwlMark(size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sova").font(.display(.title2)).foregroundStyle(Color.ink)
                            Text("Version \(version)").font(.allo(.footnote)).foregroundStyle(Color.inkSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Your name") {
                    TextField("Used in your greeting", text: $userName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                }

                Section("Theme") {
                    ThemeSwatches(themeRaw: $themeRaw)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
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
                    Button("Replay Welcome", systemImage: "hand.wave") {
                        dismiss()
                        withAnimation(.smooth(duration: 0.6)) { hasOnboarded = false }
                    }
                    .foregroundStyle(Color.ink)
                }

                Section {
                    Button("Erase All Data", systemImage: "trash", role: .destructive) { confirmErase = true }
                } footer: {
                    Text("Everything you add stays on this iPhone.")
                }
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
            .confirmationDialog("Erase everything?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase All Data", role: .destructive, action: eraseAll)
            } message: {
                Text("All tasks, goals and routines will be deleted. This can’t be undone.")
            }
            .onChange(of: morningOn) { applyReminders() }
            .onChange(of: eveningOn) { applyReminders() }
            .onChange(of: morningMinutes) { applyReminders() }
            .onChange(of: eveningMinutes) { applyReminders() }
            .task { await refreshPermission() }
        }
        .tint((SovaTheme(rawValue: themeRaw) ?? .lime).accent.color)
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
    }
}
