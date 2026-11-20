import UIKit
import UserNotifications

/// Wires up what SwiftUI's App doesn't cover: the buttons on notifications,
/// and the Home Screen quick actions (long-press the app icon).
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationActions.register()
        QuickActions.install()
        WatchLink.shared.start()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let item = options.shortcutItem { QuickActions.run(item.type) }
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    // Show Sova's alerts even while Sova is open.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        let id = response.notification.request.identifier
        var info: [String: String] = [:]
        for (key, value) in response.notification.request.content.userInfo {
            if let key = key as? String, let value = value as? String { info[key] = value }
        }
        await MainActor.run {
            NotificationActions.handle(action: action, id: id, userInfo: info)
        }
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        QuickActions.run(shortcutItem.type)
        return true
    }
}

/// Long-press the app icon: New Task, New Ritual, Today.
@MainActor
enum QuickActions {
    static func install() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(type: LaunchAction.quickTask.rawValue, localizedTitle: String(localized: "New Task"),
                                      localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"),
                                      userInfo: nil),
            UIApplicationShortcutItem(type: LaunchAction.newRitual.rawValue, localizedTitle: String(localized: "New Ritual"),
                                      localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "repeat"),
                                      userInfo: nil),
            UIApplicationShortcutItem(type: LaunchAction.tasks.rawValue, localizedTitle: String(localized: "All Tasks"),
                                      localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "checklist"),
                                      userInfo: nil),
        ]
    }

    static func run(_ type: String) {
        SovaSettings.shared.set(type, forKey: SovaSettings.Key.pendingAction)
        NotificationCenter.default.post(name: .sovaPendingAction, object: nil)
    }
}

extension Notification.Name {
    static let sovaPendingAction = Notification.Name("sovaPendingAction")
}
