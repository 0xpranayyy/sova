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

/// Big, pretty buttons: tall rounded blocks of one tone with heavy text.
struct BigButtonStyle: ButtonStyle {
    var tone: StickerTone = .indigo
    var height: CGFloat = 60
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let lip: CGFloat = 4
        configuration.label
            .font(.allo(size: height >= 58 ? 18 : 16, weight: .heavy, relativeTo: .headline))
            .tracking(-0.3)
            .foregroundStyle(tone.deep)
            .padding(.horizontal, 22)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background {
                Capsule().fill(tone.fill)
                Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.28), .clear],
                                              startPoint: .top, endPoint: .center))
                    .padding(2)
            }
            .offset(y: pressed ? lip : 0)
            // The lip underneath: a darker shade the button sinks onto.
            .background {
                Capsule().fill(tone.lip)
                    .offset(y: lip)
                    .shadow(color: tone.shadow, radius: pressed ? 4 : 10, y: pressed ? 3 : 7)
            }
            .padding(.bottom, lip)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
            .sovaFeedback(.impact(flexibility: .soft, intensity: 0.55), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// The quiet partner of a big button: white with a soft ring.
struct QuietButtonStyle: ButtonStyle {
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.allo(size: 16, weight: .heavy, relativeTo: .headline))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: height)
            .background(Color.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
            .sovaFeedback(.impact(flexibility: .soft, intensity: 0.4), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Any custom tappable thing: a small, springy press.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
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

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}
