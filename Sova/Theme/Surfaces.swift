import SwiftUI

// Content sits on quiet, near-transparent cards with hairline edges.
// Liquid Glass is reserved for what floats: the tab bar, toolbar buttons,
// sheets and the quick-capture card.

extension View {
    /// A content card. `tint` gives it a faint accent edge and fill, for
    /// the one thing on screen that deserves attention.
    func surface(cornerRadius: CGFloat = 22, padding: CGFloat = 16, tint: Color? = nil,
                 interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: max(cornerRadius, 20), style: .continuous)
        return self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint ?? Color.surface, in: shape)
            .shadow(color: Color.night.opacity(0.05), radius: 0, y: 1)
            .shadow(color: Color.night.opacity(0.05), radius: 9, y: 6)
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

/// The primary action: a solid night pill, or ember for the moments that
/// start something.
struct InkButtonStyle: ButtonStyle {
    var compact = false
    var ember = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .allo(.subheadline, .bold) : .allo(.body, .bold))
            .foregroundStyle(ember ? Color.white : Color.inkInverse)
            .padding(.horizontal, compact ? 18 : 24)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 44 : 54)
            .background(ember ? Color.ember : Color.night, in: .capsule)
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A secondary action: a quiet capsule.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.allo(.subheadline, .bold))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(Color.white, in: .capsule)
            .shadow(color: Color.night.opacity(0.06), radius: 6, y: 2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Any custom tappable thing: a small, springy press.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InkButtonStyle {
    static var ink: InkButtonStyle { InkButtonStyle() }
    static var inkCompact: InkButtonStyle { InkButtonStyle(compact: true) }
    static var ember: InkButtonStyle { InkButtonStyle(ember: true) }
    static var emberCompact: InkButtonStyle { InkButtonStyle(compact: true, ember: true) }
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}
