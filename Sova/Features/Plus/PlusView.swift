import SwiftUI
import StoreKit

/// The Sova Plus paywall. What you'd want to know first comes first: what
/// Plus is in one line, the three plans with real prices, and one button.
/// The details and the small print follow for anyone who scrolls.
struct PlusView: View {
    var reason: PlusReason = .general

    @Environment(PlusStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.purchase) private var purchase
    @State private var plan: PlusPlan = .yearly
    /// Only promise the free week to someone who can still get it.
    @State private var trialEligible = false
    @State private var cheers = 0
    @State private var celebrating = false
    @State private var nothingToRestore = false

    private var trial: Product.SubscriptionOffer? { trialEligible ? store.trialOffer : nil }

    private var selectedProduct: Product? {
        switch plan {
        case .yearly: store.yearlyProduct
        case .monthly: store.monthlyProduct
        case .lifetime: store.lifetimeProduct
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    perks
                    plans
                    PlusDetails(trial: trial, store: store)
                        .padding(.top, 18)
                }
                .readableColumn(560)
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background { CanvasBackground() }
            .safeAreaInset(edge: .bottom) { buyBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: "Restore")) { Task { await restore() } }
                        .font(.allo(.subheadline, .heavy))
                        .disabled(store.isPurchasing)
                }
            }
            .alert(String(localized: "Nothing to restore"), isPresented: $nothingToRestore) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text("We couldn't find a Sova Plus purchase on this Apple Account.")
            }
        }
        .tint(Color.ink)
        // Restoring an earlier purchase, or one approved later: close.
        .onChange(of: store.isPlus) { _, plus in if plus && !celebrating { dismiss() } }
        .task {
            if store.productsState != .loaded { await store.loadProducts() }
            trialEligible = await store.isEligibleForTrial()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack(alignment: .top) {
                OwlMark(size: 58, happy: true, bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                        pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly, celebrate: cheers)
                    .padding(.top, 16)
                PlusCrown()
                    .frame(width: 30, height: 21)
                    .rotationEffect(.degrees(-10))
                    .offset(x: 5, y: 2)
            }
            .frame(width: 84, height: 84)
            .background(StickerTone.indigo.fill, in: .rect(cornerRadius: 26, style: .continuous))
            .rotationEffect(.degrees(-3))
            .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 130, height: 100)) }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text("Sova")
                        .font(.hero(34, weight: .heavy))
                        .tracking(-1.2)
                        .foregroundStyle(Color.ink)
                    TiltPill(text: "Plus", tone: .yellow, tilt: -6, size: 17)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Text(reason.line)
                    .font(.allo(size: 15, weight: .bold, relativeTo: .subheadline))
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }

    // MARK: Perks

    private var perks: some View {
        HStack(spacing: 8) {
            perk("infinity", String(localized: "Unlimited"), .mint)
            perk("icloud.fill", String(localized: "iCloud sync"), .cyan)
            perk("app.badge.fill", String(localized: "App icons"), .pink)
        }
    }

    private func perk(_ symbol: String, _ title: String, _ tone: StickerTone) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tone == .pink ? Color.white : tone.deep)
                .frame(width: 30, height: 30)
                .background(tone.fill, in: .circle)
            Text(title)
                .font(.allo(size: 13, weight: .heavy, relativeTo: .caption))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }

    // MARK: Plans

    @ViewBuilder
    private var plans: some View {
        switch store.productsState {
        case .loading:
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in PlanCard.placeholder }
            }
            .accessibilityLabel(String(localized: "Loading plans"))
        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
                Text("Couldn't reach the App Store")
                    .font(.allo(.headline, .heavy))
                    .foregroundStyle(Color.ink)
                Text("Check your connection and try again.")
                    .font(.allo(.subheadline, .medium))
                    .foregroundStyle(Color.inkSecondary)
                Button(String(localized: "Try again")) { Task { await store.loadProducts() } }
                    .buttonStyle(.quiet)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .surface(cornerRadius: 24, padding: 22)
        case .loaded:
            VStack(spacing: 10) {
                if let yearly = store.yearlyProduct {
                    PlanCard(title: String(localized: "Yearly"),
                             detail: String(localized: "Just \(store.monthlyEquivalent(of: yearly)) a month"),
                             price: yearly.displayPrice, per: String(localized: "/year"),
                             badge: store.yearlySavingsPercent.map { String(localized: "SAVE \($0)%") },
                             trial: trial.map { String(localized: "\(PlusStore.describe($0.period)) free") },
                             selected: plan == .yearly) { pick(.yearly) }
                }
                if let monthly = store.monthlyProduct {
                    PlanCard(title: String(localized: "Monthly"),
                             detail: String(localized: "Flexible, cancel anytime"),
                             price: monthly.displayPrice, per: String(localized: "/month"),
                             selected: plan == .monthly) { pick(.monthly) }
                }
                if let lifetime = store.lifetimeProduct {
                    PlanCard(title: String(localized: "Lifetime"),
                             detail: String(localized: "Pay once, keep forever"),
                             price: lifetime.displayPrice, per: String(localized: "once"),
                             selected: plan == .lifetime) { pick(.lifetime) }
                }
            }
            .disabled(store.isPurchasing)
            .sovaFeedback(.selection, trigger: plan)
            .onAppear(perform: pickAvailablePlan)
        }
    }

    private func pick(_ newPlan: PlusPlan) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { plan = newPlan }
    }

    /// If yearly didn't load for some reason, select a plan that did.
    private func pickAvailablePlan() {
        guard selectedProduct == nil else { return }
        if store.monthlyProduct != nil { plan = .monthly } else if store.lifetimeProduct != nil { plan = .lifetime }
    }

    // MARK: Buy bar

    private var ctaTitle: String {
        guard let product = selectedProduct else { return String(localized: "Continue") }
        switch plan {
        case .yearly:
            return trial != nil ? String(localized: "Start my free week")
                                : String(localized: "Continue · \(product.displayPrice)/year")
        case .monthly: return String(localized: "Continue · \(product.displayPrice)/month")
        case .lifetime: return String(localized: "Buy once · \(product.displayPrice)")
        }
    }

    private var ctaNote: String {
        guard let product = selectedProduct else { return " " }
        switch plan {
        case .yearly:
            if let trial {
                return String(localized: "Free for \(PlusStore.describe(trial.period)), then \(product.displayPrice)/year. Cancel anytime.")
            }
            return String(localized: "Renews yearly. Cancel anytime.")
        case .monthly: return String(localized: "Renews monthly. Cancel anytime.")
        case .lifetime: return String(localized: "One payment. No subscription.")
        }
    }

    private var buyBar: some View {
        VStack(spacing: 8) {
            Button {
                Task { await buy() }
            } label: {
                ZStack {
                    Text(ctaTitle)
                        .contentTransition(.opacity)
                        .opacity(store.isPurchasing ? 0 : 1)
                    if store.isPurchasing { ProgressView().tint(StickerTone.indigo.deep) }
                }
                .animation(.smooth(duration: 0.2), value: ctaTitle)
            }
            .buttonStyle(.big)
            .disabled(selectedProduct == nil || store.isPurchasing)

            Text(ctaNote)
                .font(.allo(size: 12, weight: .bold, relativeTo: .caption))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.smooth(duration: 0.2), value: ctaNote)
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(colors: [Color.canvas.opacity(0), Color.canvas.opacity(0.94), Color.canvas],
                           startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35))
                .ignoresSafeArea()
        }
    }

    // MARK: Actions

    private func buy() async {
        guard let product = selectedProduct else { return }
        celebrating = true
        if await store.buy(product, using: purchase) {
            Haptics.celebrate()
            cheers += 1
            try? await Task.sleep(for: .milliseconds(1100))
            dismiss()
        } else {
            celebrating = false
        }
    }

    private func restore() async {
        await store.restore()
        if !store.isPlus { nothingToRestore = true }
    }
}

enum PlusPlan: Hashable {
    case yearly, monthly, lifetime
}

/// A little crown for the Plus owl.
struct PlusCrown: View {
    var body: some View {
        CrownShape()
            .fill(LinearGradient(colors: [Color(hex: 0xFFE94D), Color(hex: 0xFFA03A)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(CrownShape().stroke(StickerTone.orange.deep, style: StrokeStyle(lineWidth: 2, lineJoin: .round)))
    }
}

private struct CrownShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.06, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.22))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.55))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.3, y: r.minY + r.height * 0.55))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.22))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.06, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
