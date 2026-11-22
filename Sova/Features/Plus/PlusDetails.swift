import SwiftUI
import StoreKit

/// Below the plans, for anyone who wants the whole story: how the free
/// week works, free vs Plus, Sova's promise, and the small print Apple asks
/// every subscription to show.
struct PlusDetails: View {
    let trial: Product.SubscriptionOffer?
    let store: PlusStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let trial { timeline(trial) }
            comparison
            promise
            smallPrint
        }
    }

    // MARK: Free week

    private func timeline(_ trial: Product.SubscriptionOffer) -> some View {
        let days = PlusStore.days(in: trial.period)
        let length = PlusStore.describe(trial.period)
        return VStack(alignment: .leading, spacing: 0) {
            MonoCaps(String(localized: "How your free \(length) works"))
                .padding(.bottom, 12)
            step(symbol: "lock.open.fill", tone: .yellow, day: String(localized: "Today"),
                 text: String(localized: "Everything in Plus unlocks. Nothing to pay."), last: false)
            if days > 2 {
                step(symbol: "bell.fill", tone: .lilac, day: String(localized: "Day \(days - 2)"),
                     text: String(localized: "We'll remind you the trial is ending."), last: false)
            }
            step(symbol: "star.fill", tone: .mint, day: String(localized: "Day \(days)"),
                 text: String(localized: "Your yearly plan starts. Cancel anytime before, and you won't pay."),
                 last: true)
        }
        .surface(cornerRadius: 24, padding: 16)
    }

    private func step(symbol: String, tone: StickerTone, day: String, text: String, last: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tone.deep)
                    .frame(width: 30, height: 30)
                    .background(tone.fill, in: .circle)
                if !last {
                    Capsule()
                        .fill(LinearGradient(colors: [tone.fill, Color.well], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4, height: 18)
                        .padding(.vertical, 3)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(day)
                    .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                    .foregroundStyle(Color.ink)
                Text(text)
                    .font(.allo(size: 14, weight: .medium, relativeTo: .footnote))
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 5)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Free vs Plus

    private var comparison: some View {
        VStack(spacing: 0) {
            HStack {
                MonoCaps(String(localized: "Free vs Plus"))
                Spacer()
                Text(String(localized: "Free"))
                    .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 54)
                Text(String(localized: "Plus"))
                    .font(.allo(size: 13, weight: .heavy, relativeTo: .footnote))
                    .foregroundStyle(StickerTone.yellow.deep)
                    .frame(width: 54, height: 24)
                    .background(StickerTone.yellow.fill, in: .capsule)
            }
            .padding(.bottom, 6)
            row(String(localized: "Tasks"), free: "∞", plus: "∞")
            row(String(localized: "Rituals"), free: "\(PlusGate.freeRituals)", plus: "∞")
            row(String(localized: "Active goals"), free: "\(PlusGate.freeGoals)", plus: "∞")
            row(String(localized: "Widgets & Siri"), free: "✓", plus: "✓")
            row(String(localized: "iCloud sync"), free: "–", plus: "✓")
            row(String(localized: "App icons"), free: "1", plus: "7", last: true)
        }
        .surface(cornerRadius: 24, padding: 16)
    }

    private func row(_ title: String, free: String, plus: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text(free)
                    .font(.allo(size: 15, weight: .heavy, relativeTo: .footnote).monospacedDigit())
                    .foregroundStyle(Color.inkTertiary)
                    .frame(width: 54)
                Text(plus)
                    .font(.allo(size: 16, weight: .heavy).monospacedDigit())
                    .foregroundStyle(StickerTone.indigo.fill)
                    .frame(width: 54)
            }
            .padding(.vertical, 8)
            if !last { Rectangle().fill(Color.hairline).frame(height: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(String(localized: "Free")) \(free), \(String(localized: "Plus")) \(plus)")
    }

    // MARK: Promise

    private var promise: some View {
        HStack(spacing: 14) {
            let symbols = ["hand.raised.fill", "eye.slash.fill", "person.crop.circle.badge.xmark"]
            let titles = [String(localized: "No ads"), String(localized: "No tracking"), String(localized: "No account")]
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: 5) {
                    Image(systemName: symbols[i]).font(.system(size: 11, weight: .bold))
                    Text(titles[i]).font(.allo(size: 12, weight: .heavy, relativeTo: .caption2))
                }
                .foregroundStyle(Color.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Small print (App Store Guideline 3.1.2)

    private var smallPrint: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(terms)
                .font(.allo(size: 12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(Color.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                Link(String(localized: "Terms of Use"), destination: Links.terms)
                Link(String(localized: "Privacy Policy"), destination: Links.privacy)
                Button(String(localized: "Restore Purchases")) { Task { await store.restore() } }
            }
            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
            .foregroundStyle(Color.inkSecondary)
        }
        .padding(.horizontal, 4)
    }

    private var terms: String {
        var lines: [String] = []
        if let yearly = store.yearlyProduct, let monthly = store.monthlyProduct {
            lines.append(String(localized: "Sova Plus Yearly (\(yearly.displayPrice) a year) and Monthly (\(monthly.displayPrice) a month) are auto-renewing subscriptions."))
        }
        if trial != nil {
            lines.append(String(localized: "The free trial turns into the yearly plan when it ends, unless you cancel before."))
        }
        lines.append(String(localized: "Payment is charged to your Apple Account. A subscription renews automatically unless it's cancelled at least 24 hours before the end of the current period. Manage or cancel it anytime in Settings > Apple Account > Subscriptions."))
        if let lifetime = store.lifetimeProduct {
            lines.append(String(localized: "Lifetime (\(lifetime.displayPrice)) is a single payment, not a subscription."))
        }
        return lines.joined(separator: " ")
    }
}
