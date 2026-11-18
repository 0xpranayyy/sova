import SwiftUI
import StoreKit

/// The Sova Plus paywall: Apple's native subscription controls under an
/// owl stage and a sticker list of what Plus unlocks.
struct PlusView: View {
    var reason: PlusReason = .general

    @Environment(PlusStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var cheers = 0

    var body: some View {
        SubscriptionStoreView(productIDs: PlusStore.subscriptionIDs) {
            header
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .cancellation)
        .storeButton(.visible, for: .policies)
        .subscriptionStorePolicyDestination(url: Links.privacy, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: Links.terms, for: .termsOfService)
        .containerBackground(Color.canvas, for: .subscriptionStoreFullHeight)
        .tint(StickerTone.indigo.fill)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                await store.refresh()
                Haptics.celebrate()
                cheers += 1
                try? await Task.sleep(for: .milliseconds(700))
                dismiss()
            }
        }
        .onChange(of: store.isPlus) { _, plus in if plus { dismiss() } }
    }

    private var header: some View {
        VStack(spacing: 18) {
            ZStack {
                StickerTone.indigo.fill
                SparkleDot(color: StickerTone.pink.fill, size: 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(22)
                SparkleDot(color: StickerTone.mint.fill, size: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(26)
                VStack(spacing: 10) {
                    OwlMark(size: 86, happy: true, bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                            pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8), celebrate: cheers)
                        .overlay { SparkleBurst(trigger: cheers) }
                    HStack(spacing: 8) {
                        Text("Sova")
                            .font(.hero(44, weight: .heavy))
                            .foregroundStyle(.white)
                        TiltPill(text: "Plus", tone: .yellow, tilt: -6, size: 20)
                    }
                    Text(reason.line)
                        .font(.allo(.subheadline, .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 26)
            }
            .clipShape(.rect(cornerRadius: 34, style: .continuous))

            VStack(spacing: 8) {
                perk("infinity", String(localized: "Unlimited rituals and goals"), .mint)
                perk("icloud.fill", String(localized: "iCloud sync on all your devices"), .cyan)
                perk("app.badge.fill", String(localized: "Extra app icons"), .pink)
                perk("heart.fill", String(localized: "Support a tiny indie app"), .orange)
            }

            if let lifetime = store.lifetimeProduct {
                Button {
                    Task { await store.buyLifetime() }
                } label: {
                    Text("Or pay once: \(lifetime.displayPrice) for life")
                        .font(.allo(.subheadline, .heavy))
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.well, in: .capsule)
                }
                .buttonStyle(.pressable)
                .disabled(store.isPurchasing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func perk(_ symbol: String, _ text: String, _ tone: StickerTone) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tone.deep)
                .frame(width: 36, height: 36)
                .background(tone.fill, in: .rect(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-5))
            Text(text)
                .font(.allo(size: 16, weight: .heavy, relativeTo: .body))
                .foregroundStyle(Color.ink)
            Spacer()
        }
        .padding(10)
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.hairline, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}
