import SwiftUI

// Content is either a white card with a soft ring, or a flat block of one
// Allo color with tonal text. Liquid Glass stays on the system tab bar,
// sheets and the undo bar.

extension View {
    /// A white card. Pass `tint` to fill it with a flat color instead.
    func surface(cornerRadius: CGFloat = 24, padding: CGFloat = 16, tint: Color? = nil,
                 interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: max(cornerRadius, 22), style: .continuous)
        return self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((tint ?? Color.surface).shadow(.drop(color: Color.night.opacity(0.06), radius: 14, y: 7)), in: shape)
            .overlay(shape.strokeBorder(Color.hairline, lineWidth: tint == nil ? 1.5 : 0))
    }

    /// A flat block in one Allo tone.
    func block(_ tone: StickerTone, cornerRadius: CGFloat = 30, padding: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
            .background {
                // A sticker: its color, a soft shadow in a deeper shade of
                // itself, a gentle sheen from the top, and a bright top edge.
                shape.fill(tone.fill.shadow(.drop(color: tone.shadow, radius: 16, y: 9)))
                shape.fill(LinearGradient(colors: [Color.white.opacity(0.22), .clear, Color.black.opacity(0.04)],
                                          startPoint: .top, endPoint: .bottom))
                shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.55), .clear],
                                                  startPoint: .top, endPoint: .center), lineWidth: 1.2)
            }
    }
}

extension Glass {
    static func card(tint: Color? = nil, interactive: Bool = false) -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint.opacity(0.22)) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}

// MARK: - Buttons

/// The main action on a screen: a tall capsule in one tone, heavy text, a
/// soft sheen and a thin darker lip it sinks onto when pressed. One per
/// screen; everything else is quiet, tonal or glass.
struct BigButtonStyle: ButtonStyle {
    var tone: StickerTone = .indigo
    var height: CGFloat = 60
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let lip: CGFloat = 2.5
        configuration.label
            .font(.allo(size: height >= 58 ? 18 : 16, weight: .heavy, relativeTo: .headline))
            .tracking(-0.3)
            .foregroundStyle(tone.deep)
            .padding(.horizontal, 22)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background {
                Capsule().fill(tone.fill)
                // Light from above, and a crisp highlight on the top edge.
                Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.2), .clear],
                                              startPoint: .top, endPoint: .center))
                Capsule().strokeBorder(LinearGradient(colors: [Color.white.opacity(0.45), .clear],
                                                      startPoint: .top, endPoint: .center), lineWidth: 1)
            }
            .offset(y: pressed ? lip : 0)
            .background {
                Capsule().fill(tone.lip)
                    .offset(y: lip)
                    .shadow(color: tone.shadow.opacity(pressed ? 0.5 : 0.8), radius: pressed ? 3 : 8, y: pressed ? 2 : 5)
            }
            .padding(.bottom, lip)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(.hoverEffect, Capsule())
            .hoverEffect(.highlight)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
    }
}

/// The quiet partner of a big button: a white capsule with a clear ring.
struct QuietButtonStyle: ButtonStyle {
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: height)
            .background(Color.surface.shadow(.drop(color: Color.night.opacity(0.06), radius: 6, y: 3)), in: .capsule)
            .overlay(Capsule().strokeBorder(Color.ink.opacity(0.12), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .contentShape(.hoverEffect, Capsule())
            .hoverEffect(.highlight)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A second action that sits on a colored block: a frosted white capsule
/// with the block's deep ink, so it reads as a button without competing
/// with the main one.
struct TonalButtonStyle: ButtonStyle {
    var tone: StickerTone
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
            .foregroundStyle(tone.deep)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Color.white.opacity(configuration.isPressed ? 0.5 : 0.62), in: .capsule)
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.9), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .contentShape(.hoverEffect, Capsule())
            .hoverEffect(.highlight)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Any custom tappable thing: a small, springy press, and a lift under an
/// iPad pointer.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .hoverEffect(.lift)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// Kept names for existing call sites.
typealias InkButtonStyle = BigButtonStyle

extension BigButtonStyle {
    init(compact: Bool, ember: Bool = false) {
        self.init(tone: .indigo, height: compact ? 50 : 60, fullWidth: !compact)
    }
}

extension ButtonStyle where Self == BigButtonStyle {
    static var big: BigButtonStyle { BigButtonStyle() }
    static func big(_ tone: StickerTone, height: CGFloat = 60) -> BigButtonStyle {
        BigButtonStyle(tone: tone, height: height)
    }
    static var ink: BigButtonStyle { BigButtonStyle() }
    static var inkCompact: BigButtonStyle { BigButtonStyle(tone: .indigo, height: 50, fullWidth: false) }
    static var ember: BigButtonStyle { BigButtonStyle() }
    static var emberCompact: BigButtonStyle { BigButtonStyle(tone: .indigo, height: 50, fullWidth: false) }
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}

extension ButtonStyle where Self == TonalButtonStyle {
    static func tonal(_ tone: StickerTone, height: CGFloat = 50) -> TonalButtonStyle {
        TonalButtonStyle(tone: tone, height: height)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}
