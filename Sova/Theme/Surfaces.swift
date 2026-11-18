import SwiftUI

// MARK: - Glass cards

extension View {
    /// A Liquid Glass card. Optionally tinted with an accent.
    func surface(cornerRadius: CGFloat = 24, padding: CGFloat = 16, tint: Color? = nil,
                 interactive: Bool = false) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(Glass.card(tint: tint, interactive: interactive),
                         in: .rect(cornerRadius: cornerRadius, style: .continuous))
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

/// The primary action: a full-width, tinted Liquid Glass capsule.
struct InkButtonStyle: ButtonStyle {
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .subheadline.weight(.semibold) : .headline)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 18 : 24)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 42 : 56)
            .glassEffect(.regular.tint(SovaTheme.current.accent.color).interactive(), in: .capsule)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A secondary action: clear glass.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .glassEffect(.regular.interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Any custom tappable thing: a small, springy press.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
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
