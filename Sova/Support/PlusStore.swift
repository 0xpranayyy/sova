import StoreKit
import Observation

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

/// What's free, and what Plus unlocks.
enum PlusGate {
    static let freeRituals = 3
    static let freeGoals = 1

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
    private(set) var lifetimeProduct: Product?
    private(set) var isPurchasing = false
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refresh()
            }
        }
        Task { [weak self] in
            await self?.refresh()
            await self?.loadProducts()
        }
    }

    /// Plus is active if any current entitlement is one of ours.
    func refresh() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               Self.allIDs.contains(transaction.productID) {
                active = true
            }
        }
        isPlus = active
        SovaSettings.isPlus = active
    }

    func loadProducts() async {
        lifetimeProduct = try? await Product.products(for: [Self.lifetime]).first
    }

    @discardableResult
    func buyLifetime() async -> Bool {
        guard let product = lifetimeProduct else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        guard let result = try? await product.purchase() else { return false }
        if case .success(.verified(let transaction)) = result {
            await transaction.finish()
            await refresh()
            return true
        }
        return false
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }
}
