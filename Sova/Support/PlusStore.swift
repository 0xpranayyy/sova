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
    private(set) var yearlyProduct: Product?
    private(set) var monthlyProduct: Product?
    private(set) var lifetimeProduct: Product?
    private(set) var productsState: ProductsState = .loading
    private(set) var isPurchasing = false

    enum ProductsState: Equatable { case loading, loaded, failed }

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

    /// Loads the three plans. Safe to call again after a failure.
    func loadProducts() async {
        if productsState != .loaded { productsState = .loading }
        do {
            let products = try await Product.products(for: Self.allIDs)
            yearlyProduct = products.first { $0.id == Self.yearly }
            monthlyProduct = products.first { $0.id == Self.monthly }
            lifetimeProduct = products.first { $0.id == Self.lifetime }
            productsState = products.isEmpty ? .failed : .loaded
        } catch {
            productsState = .failed
        }
    }

    /// Buys a plan through SwiftUI's purchase action, which shows the App
    /// Store sheet in the right window. True once Plus is unlocked.
    @discardableResult
    func buy(_ product: Product, using purchase: PurchaseAction) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        guard let result = try? await purchase(product) else { return false }
        switch result {
        case .success(.verified(let transaction)):
            await TrialReminder.scheduleIfNeeded(for: transaction)
            await transaction.finish()
            await refresh()
            return true
        default:
            // Cancelled, pending (Ask to Buy) or unverified: nothing unlocks
            // now; a pending purchase arrives later through Transaction.updates.
            return false
        }
    }

    // MARK: Honest numbers for the paywall

    /// The yearly plan's free trial, if it has one.
    var trialOffer: Product.SubscriptionOffer? {
        guard let offer = yearlyProduct?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer
    }

    /// How much a year costs less than twelve months, rounded down so it's
    /// never overstated. Works in any currency.
    var yearlySavingsPercent: Int? {
        guard let yearly = yearlyProduct, let monthly = monthlyProduct, monthly.price > 0 else { return nil }
        let twelveMonths = monthly.price * 12
        guard twelveMonths > yearly.price else { return nil }
        let saving = (twelveMonths - yearly.price) / twelveMonths * 100
        let percent = Int(NSDecimalNumber(decimal: saving).doubleValue.rounded(.down))
        return percent >= 5 ? percent : nil
    }

    /// The yearly price spread over twelve months, in the store's currency.
    func monthlyEquivalent(of product: Product) -> String {
        (product.price / 12).formatted(product.priceFormatStyle)
    }

    /// "1 week", "3 days", "1 month".
    static func describe(_ period: Product.SubscriptionPeriod) -> String {
        let n = period.value
        switch period.unit {
        case .day: return n == 1 ? String(localized: "1 day") : String(localized: "\(n) days")
        case .week: return n == 1 ? String(localized: "1 week") : String(localized: "\(n) weeks")
        case .month: return n == 1 ? String(localized: "1 month") : String(localized: "\(n) months")
        case .year: return n == 1 ? String(localized: "1 year") : String(localized: "\(n) years")
        @unknown default: return String(localized: "\(n) days")
        }
    }

    /// The trial's length in days, for the "how it works" timeline.
    static func days(in period: Product.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: period.value
        case .week: period.value * 7
        case .month: period.value * 30
        case .year: period.value * 365
        @unknown default: period.value
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
