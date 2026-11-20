import StoreKit
import Observation
import UserNotifications
import UIKit

/// Why the paywall opened, so the owl can say something that fits.
enum PlusReason: String, Hashable {
    case general, rituals, goals, sync, icons

    var line: String {
        switch self {
        case .general: String(localized: "Unlock everything Sova can do.")
        case .rituals: String(localized: "You've got \(PlusGate.freeRituals) rituals going! Add as many as you like with Plus.")
        case .goals: String(localized: "Dreaming bigger? Unlock unlimited goals with Plus.")
        case .sync: String(localized: "Keep your day in sync on all your devices with iCloud.")
        case .icons: String(localized: "Make Sova yours with extra app icons.")
        }
    }
}

extension PlusReason: Identifiable {
    var id: String { rawValue }
}

/// What's free, and what Plus unlocks.
enum PlusGate {
    static let freeRituals = 5
    static let freeGoals = 3
    /// How many rituals onboarding offers, leaving room on the free plan to
    /// add your own before Plus comes up.
    static let starterRituals = 3

    static func canAddRitual(existing: Int) -> Bool { SovaSettings.isPlus || existing < freeRituals }
    static func canAddGoal(existing: Int) -> Bool { SovaSettings.isPlus || existing < freeGoals }
}

/// Sova Plus purchases with StoreKit 2.
@MainActor
@Observable
final class PlusStore {
    static let monthly = "app.sova.plus.monthly"
    static let yearly = "app.sova.plus.yearly"
    static let lifetime = "app.sova.plus.lifetime"
    static let subscriptionIDs = [yearly, monthly]
    static let allIDs: Set<String> = [monthly, yearly, lifetime]

    private(set) var isPlus = SovaSettings.isPlus
    /// Plus bought once, for good. There's no subscription to manage.
    private(set) var isLifetime = false
    private(set) var lifetimeProduct: Product?
    private(set) var isPurchasing = false
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await TrialReminder.scheduleIfNeeded(for: transaction)
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { [weak self] in
            await self?.refresh()
            await self?.loadProducts()
        }
    }

    /// Plus is active if any current entitlement is one of ours: a live
    /// subscription (including a free trial or billing grace period) or the
    /// lifetime purchase, and not refunded.
    func refresh() async {
        var active = false
        var lifetime = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded,
                  Self.allIDs.contains(transaction.productID) else { continue }
            active = true
            if transaction.productID == Self.lifetime { lifetime = true }
        }
        isPlus = active
        isLifetime = lifetime
        SovaSettings.isPlus = active
        // Plus ended (expired or refunded): put the regular icon back.
        if !active, UIApplication.shared.supportsAlternateIcons, UIApplication.shared.alternateIconName != nil {
            try? await UIApplication.shared.setAlternateIconName(nil)
        }
    }

    /// Whether the yearly plan would start with the free week for this
    /// Apple Account. False once someone has used a trial in this group.
    func isEligibleForTrial() async -> Bool {
        guard let product = try? await Product.products(for: [Self.yearly]).first,
              let subscription = product.subscription,
              subscription.introductoryOffer != nil else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    func loadProducts() async {
        lifetimeProduct = try? await Product.products(for: [Self.lifetime]).first
    }

    /// Buys lifetime Plus through SwiftUI's purchase action, which shows
    /// the App Store sheet in the right window.
    @discardableResult
    func buyLifetime(using purchase: PurchaseAction) async -> Bool {
        guard let product = lifetimeProduct else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        guard let result = try? await purchase(product) else { return false }
        switch result {
        case .success(.verified(let transaction)):
            await transaction.finish()
            await refresh()
            return true
        default:
            // Cancelled, pending (Ask to Buy) or unverified: nothing unlocks
            // now; a pending purchase arrives later through Transaction.updates.
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }
}

/// The paywall promises a heads-up before a free trial turns into a paid
/// plan. This keeps that promise: one notification, two days before.
enum TrialReminder {
    static let id = "sova.trial.reminder"

    static func scheduleIfNeeded(for transaction: Transaction) async {
        guard transaction.offer?.type == .introductory,
              let end = transaction.expirationDate else { return }
        let fire = end.addingTimeInterval(-2 * 86_400)
        guard fire > .now else { return }
        await TaskAlerts.requestPermissionIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your Sova Plus trial ends in 2 days")
        content.body = String(localized: "Nothing to do if you'd like to keep Plus. You can cancel anytime in Settings.")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
