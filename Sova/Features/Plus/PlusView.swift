import SwiftUI
import StoreKit

/// The Sova Plus paywall: an owl stage with a slowly turning sunburst,
/// perks as colorful tiles, an honest "how your free week works" timeline,
/// and Apple's native subscription controls underneath.
struct PlusView: View {
    var reason: PlusReason = .general

    @Environment(PlusStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cheers = 0
    @State private var celebrating = false
    @State private var spin = false

    var body: some View {
        SubscriptionStoreView(productIDs: PlusStore.subscriptionIDs) {
            marketing
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(Color.surface)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .cancellation)
        .storeButton(.visible, for: .policies)
        .subscriptionStorePolicyDestination(url: Links.privacy, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: Links.terms, for: .termsOfService)
        .containerBackground(Color.canvas, for: .subscriptionStoreFullHeight)
        .tint(StickerTone.indigo.fill)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success(let verification)) = result {
                celebrating = true
                if case .verified(let transaction) = verification {
                    await TrialReminder.scheduleIfNeeded(for: transaction)
                }
                await store.refresh()
                Haptics.celebrate()
                cheers += 1
                try? await Task.sleep(for: .milliseconds(1100))
                dismiss()
            }
        }
        // Restoring an earlier purchase: close right away.
        .onChange(of: store.isPlus) { _, plus in if plus && !celebrating { dismiss() } }
    }

    private var marketing: some View {
        VStack(spacing: 14) {
            stage
            perks
            timeline
            lifetime
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Stage

    private var stage: some View {
        ZStack {
            StickerTone.indigo.fill

            StarburstShape(points: 18)
                .fill(Color.white.opacity(0.07))
                .frame(width: 560, height: 560)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .offset(y: -20)

            SparkleDot(color: StickerTone.pink.fill, size: 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(22)
            SparkleDot(color: StickerTone.mint.fill, size: 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(24)
            SparkleDot(color: StickerTone.yellow.fill, size: 11)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 70).padding(.trailing, 40)

            VStack(spacing: 10) {
                ZStack(alignment: .top) {
                    OwlMark(size: 96, happy: true, bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                            pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8), celebrate: cheers)
                        .padding(.top, 22)
                    Crown()
                        .fill(StickerTone.orange.fill)
                        .overlay(Crown().stroke(StickerTone.orange.deep, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
                        .frame(width: 44, height: 30)
                        .rotationEffect(.degrees(-10))
                        .offset(x: 6)
                }
                .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 150, height: 110)) }

                HStack(spacing: 8) {
                    Text("Sova")
                        .font(.hero(42, weight: .heavy))
                        .tracking(-1.5)
                        .foregroundStyle(.white)
                    TiltPill(text: "Plus", tone: .yellow, tilt: -6, size: 20)
                }
                Text(reason.line)
                    .font(.allo(.subheadline, .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }
            .padding(.vertical, 24)

            // Floating stickers, like the website hero.
            TiltPill(text: "∞ rituals", tone: .mint, tilt: -9, size: 13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 74).padding(.leading, 18)
            TiltPill(text: "☁️ iCloud", tone: .cyan, tilt: 8, size: 13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 112).padding(.trailing, 14)
        }
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) { spin = true }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Perks

    private var perks: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            perk("infinity", String(localized: "Unlimited"), String(localized: "rituals and goals"), .mint, tilt: -1.5)
            perk("icloud.fill", String(localized: "iCloud sync"), String(localized: "on all your devices"), .cyan, tilt: 1.5)
            perk("app.badge.fill", String(localized: "App icons"), String(localized: "make Sova yours"), .pink, tilt: 1.2)
            perk("heart.fill", String(localized: "Indie love"), String(localized: "support a tiny team"), .orange, tilt: -1.2)
        }
    }

    private func perk(_ symbol: String, _ title: String, _ subtitle: String, _ tone: StickerTone, tilt: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tone.fill)
                .frame(width: 38, height: 38)
                .background(tone.deep, in: .rect(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-6))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                    .tracking(-0.4)
                Text(subtitle)
                    .font(.allo(size: 13, weight: .bold, relativeTo: .caption))
                    .opacity(0.75)
            }
        }
        .foregroundStyle(tone.deep)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tone.fill, in: .rect(cornerRadius: 24, style: .continuous))
        .rotationEffect(.degrees(tilt))
        .accessibilityElement(children: .combine)
    }

    // MARK: Free week timeline

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoCaps(String(localized: "How your free week works"))
                .padding(.bottom, 12)
            step(symbol: "lock.open.fill", tone: .yellow, day: String(localized: "Today"),
                 text: String(localized: "Everything in Plus unlocks."), last: false)
            step(symbol: "bell.fill", tone: .lilac, day: String(localized: "Day 5"),
                 text: String(localized: "We'll remind you the trial is ending."), last: false)
            step(symbol: "star.fill", tone: .mint, day: String(localized: "Day 7"),
                 text: String(localized: "Your yearly plan starts. Cancel anytime before."), last: true)
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
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
                        .fill(Color.well)
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
            }
            .padding(.top, 5)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Lifetime

    @ViewBuilder
    private var lifetime: some View {
        if let product = store.lifetimeProduct {
            Button {
                Task {
                    celebrating = true
                    if await store.buyLifetime() {
                        Haptics.celebrate()
                        cheers += 1
                        try? await Task.sleep(for: .milliseconds(1100))
                        dismiss()
                    } else {
                        celebrating = false
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text("∞")
                        .font(.hero(24, weight: .heavy))
                        .foregroundStyle(StickerTone.yellow.deep)
                        .frame(width: 40, height: 40)
                        .background(StickerTone.yellow.fill, in: .rect(cornerRadius: 13, style: .continuous))
                        .rotationEffect(.degrees(-6))
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("Lifetime")
                                .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
                            Text("PAY ONCE")
                                .font(.allo(size: 10, weight: .heavy, relativeTo: .caption2))
                                .tracking(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(StickerTone.mint.fill, in: .capsule)
                                .foregroundStyle(StickerTone.mint.deep)
                        }
                        Text("Keep Plus forever, no subscription")
                            .font(.allo(size: 13, weight: .medium, relativeTo: .caption))
                            .foregroundStyle(Color.inkSecondary)
                    }
                    Spacer(minLength: 4)
                    Text(product.displayPrice)
                        .font(.allo(size: 17, weight: .heavy, relativeTo: .headline))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Color.inkTertiary)
                }
                .foregroundStyle(Color.ink)
                .padding(12)
                .background(Color.surface, in: .rect(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
            }
            .buttonStyle(.pressable)
            .disabled(store.isPurchasing)
        }
    }
}

/// A little crown for the Plus owl.
private struct Crown: Shape {
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
