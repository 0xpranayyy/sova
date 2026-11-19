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
    @State private var float = false

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
        .containerBackground(for: .subscriptionStoreFullHeight) { CanvasBackground() }
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
            comparison
            timeline
            lifetime
            promise
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Stage

    private var stage: some View {
        ZStack {
            StickerTone.indigo.fill
            RadialGradient(colors: [Color(hex: 0x5B44D6).opacity(0.85), .clear],
                           center: UnitPoint(x: 0.5, y: 0.32), startRadius: 0, endRadius: 230)

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
                    // A soft halo behind the owl.
                    Circle()
                        .fill(StickerTone.yellow.fill.opacity(0.28))
                        .frame(width: 130, height: 130)
                        .blur(radius: 24)
                        .padding(.top, 10)
                    OwlMark(size: 96, happy: true, bodyColor: StickerTone.yellow.fill, eyeColor: Color(hex: 0x2B1677),
                            pupilColor: StickerTone.yellow.fill, bellyColor: Color(hex: 0xFFF4A8), celebrate: cheers)
                        .padding(.top, 22)
                    Crown()
                        .fill(LinearGradient(colors: [Color(hex: 0xFFE94D), Color(hex: 0xFFA03A)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(Crown().stroke(StickerTone.orange.deep, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
                        .overlay(alignment: .bottom) {
                            HStack(spacing: 6) {
                                Circle().fill(StickerTone.pink.fill).frame(width: 5, height: 5)
                                Circle().fill(StickerTone.cyan.fill).frame(width: 5, height: 5)
                                Circle().fill(StickerTone.mint.fill).frame(width: 5, height: 5)
                            }
                            .padding(.bottom, 5)
                        }
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(.white)
                                .offset(x: 8, y: -6)
                                .opacity(float ? 1 : 0.3)
                        }
                        .frame(width: 44, height: 30)
                        .rotationEffect(.degrees(-10))
                        .offset(x: 6)
                }
                .offset(y: float ? -4 : 2)
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
                .offset(y: float ? -3 : 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 74).padding(.leading, 18)
            TiltPill(text: "☁️ iCloud", tone: .cyan, tilt: 8, size: 13)
                .offset(y: float ? 3 : -3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 112).padding(.trailing, 14)
            TiltPill(text: "∞ goals", tone: .pink, tilt: 6, size: 12)
                .offset(y: float ? -2 : 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 40).padding(.leading, 22)
        }
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .shadow(color: StickerTone.indigo.shadow, radius: 20, y: 12)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { float = true }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Perks

    private var perks: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            perk("infinity", String(localized: "Unlimited"), String(localized: "rituals and goals"), .mint, tilt: -1.5, order: 0)
            perk("icloud.fill", String(localized: "iCloud sync"), String(localized: "on all your devices"), .cyan, tilt: 1.5, order: 1)
            perk("app.badge.fill", String(localized: "App icons"), String(localized: "make Sova yours"), .pink, tilt: 1.2, order: 2)
            perk("heart.fill", String(localized: "Indie love"), String(localized: "support a tiny team"), .orange, tilt: -1.2, order: 3)
        }
    }

    private func perk(_ symbol: String, _ title: String, _ subtitle: String, _ tone: StickerTone, tilt: Double,
                      order: Int) -> some View {
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
        .background {
            let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
            shape.fill(tone.fill.shadow(.drop(color: tone.shadow, radius: 12, y: 7)))
            shape.fill(LinearGradient(colors: [Color.white.opacity(0.24), .clear], startPoint: .top, endPoint: .center))
            shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.55), .clear],
                                              startPoint: .top, endPoint: .center), lineWidth: 1.2)
        }
        .rotationEffect(.degrees(tilt))
        .modifier(PopIn(delay: Double(order) * 0.08))
        .accessibilityElement(children: .combine)
    }

    // MARK: Free vs Plus

    private var comparison: some View {
        VStack(spacing: 0) {
            HStack {
                MonoCaps(String(localized: "What you get"))
                Spacer()
                Text(String(localized: "Free"))
                    .font(.allo(size: 13, weight: .heavy))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 58)
                Text(String(localized: "Plus"))
                    .font(.allo(size: 13, weight: .heavy))
                    .foregroundStyle(StickerTone.yellow.deep)
                    .frame(width: 58, height: 26)
                    .background(StickerTone.yellow.fill, in: .capsule)
            }
            .padding(.bottom, 8)
            compareRow(String(localized: "Tasks"), free: "∞", plus: "∞")
            compareRow(String(localized: "Rituals"), free: "\(PlusGate.freeRituals)", plus: "∞")
            compareRow(String(localized: "Active goals"), free: "\(PlusGate.freeGoals)", plus: "∞")
            compareRow(String(localized: "Widgets & Siri"), free: "✓", plus: "✓")
            compareRow(String(localized: "iCloud sync"), free: "–", plus: "✓")
            compareRow(String(localized: "App icons"), free: "1", plus: "2", last: true)
        }
        .surface(cornerRadius: 24, padding: 16)
    }

    private func compareRow(_ title: String, free: String, plus: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text(free)
                    .font(.allo(size: 15, weight: .heavy).monospacedDigit())
                    .foregroundStyle(Color.inkTertiary)
                    .frame(width: 58)
                Text(plus)
                    .font(.allo(size: 16, weight: .heavy).monospacedDigit())
                    .foregroundStyle(StickerTone.indigo.fill)
                    .frame(width: 58)
            }
            .padding(.vertical, 9)
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
                    Text(titles[i]).font(.allo(size: 12, weight: .heavy))
                }
                .foregroundStyle(Color.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
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
                .background(Color.surface.shadow(.drop(color: Color.night.opacity(0.07), radius: 12, y: 6)),
                            in: .rect(cornerRadius: 22, style: .continuous))
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

/// Springs a perk tile in from slightly smaller, a beat after the last.
private struct PopIn: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown || reduceMotion ? 1 : 0.7)
            .opacity(shown || reduceMotion ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.15 + delay)) { shown = true }
            }
    }
}
