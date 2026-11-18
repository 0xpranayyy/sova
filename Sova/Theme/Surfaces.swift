import SwiftUI

// Content sits on quiet, near-transparent cards with hairline edges.
// Liquid Glass is reserved for what floats: the tab bar, toolbar buttons,
// sheets and the quick-capture card.

extension View {
    /// A content card. `tint` gives it a faint accent edge and fill, for
    /// the one thing on screen that deserves attention.
    func surface(cornerRadius: CGFloat = 22, padding: CGFloat = 16, tint: Color? = nil,
                 interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: min(cornerRadius, 16), style: .continuous)
        return self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.map { $0.opacity(0.06) } ?? Color.surface, in: shape)
            .overlay(shape.strokeBorder(tint.map { $0.opacity(0.3) } ?? Color.hairline, lineWidth: 1))
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

/// The primary action: a solid black pill.
struct InkButtonStyle: ButtonStyle {
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .allo(.subheadline, .medium) : .allo(.body, .medium))
            .foregroundStyle(Color.inkInverse)
            .padding(.horizontal, compact ? 18 : 24)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 44 : 52)
            .background(Color.black, in: .capsule)
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A secondary action: a quiet capsule.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.allo(.subheadline, .medium))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(Color.white, in: .capsule)
            .overlay(Capsule().strokeBorder(Color.black.opacity(0.12)))
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
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}
