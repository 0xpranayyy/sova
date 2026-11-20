import SwiftUI

/// One plan on the paywall: a radio, the name and a short line, the price.
/// The picked plan turns sunny yellow with a deep ring; the others are
/// white cards.
struct PlanCard: View {
    let title: String
    let detail: String
    let price: String
    let per: String
    var badge: String? = nil
    var trial: String? = nil
    let selected: Bool
    let action: () -> Void

    private let tone = StickerTone.yellow
    private var ink: Color { selected ? tone.deep : Color.ink }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                radio
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(title)
                            .font(.allo(size: 18, weight: .heavy, relativeTo: .headline))
                            .tracking(-0.4)
                        if let trial {
                            Text(trial)
                                .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(StickerTone.mint.fill, in: .capsule)
                                .foregroundStyle(StickerTone.mint.deep)
                                .lineLimit(1)
                        }
                    }
                    Text(detail)
                        .font(.allo(size: 13, weight: .bold, relativeTo: .caption))
                        .opacity(0.7)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.allo(size: 19, weight: .heavy, relativeTo: .headline).monospacedDigit())
                        .tracking(-0.4)
                    Text(per)
                        .font(.allo(size: 12, weight: .bold, relativeTo: .caption2))
                        .opacity(0.6)
                }
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .background { background }
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.allo(size: 11, weight: .heavy, relativeTo: .caption2))
                        .tracking(0.8)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(StickerTone.pink.fill, in: .capsule)
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(4))
                        .offset(x: -14, y: -10)
                }
            }
            .contentShape(.rect(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var radio: some View {
        ZStack {
            Circle()
                .strokeBorder(selected ? tone.deep : Color.ink.opacity(0.22), lineWidth: 2.5)
            if selected {
                Circle().fill(tone.deep)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(tone.fill)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 26, height: 26)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        if selected {
            shape.fill(tone.fill.shadow(.drop(color: tone.shadow, radius: 12, y: 6)))
            shape.fill(LinearGradient(colors: [Color.white.opacity(0.24), .clear], startPoint: .top, endPoint: .center))
            shape.strokeBorder(tone.deep, lineWidth: 2.5)
        } else {
            shape.fill(Color.surface.shadow(.drop(color: Color.night.opacity(0.05), radius: 8, y: 4)))
            shape.strokeBorder(Color.hairline, lineWidth: 1.5)
        }
    }

    /// A grey stand-in while the App Store answers.
    static var placeholder: some View {
        PlanCard(title: "Yearly plan", detail: "Loading the price", price: "$00.00", per: "/year",
                 selected: false) {}
            .redacted(reason: .placeholder)
            .disabled(true)
    }
}
