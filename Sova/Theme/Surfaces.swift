import SwiftUI

// Liquid Glass is kept for the navigation and control layer (tab bar,
// toolbars, the bottom accessory, sheets, floating back buttons), as the HIG
// asks. Content sits on solid, quiet surfaces.

struct Surface: ViewModifier {
    var cornerRadius: CGFloat = 22
    var padding: CGFloat = 16
    var fill: Color = .surface
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: shape)
            .overlay(shape.strokeBorder(Color.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.035), radius: 1, y: 1)
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.045), radius: 14, y: 8)
    }
}

extension View {
    func surface(cornerRadius: CGFloat = 22, padding: CGFloat = 16, fill: Color = .surface) -> some View {
        modifier(Surface(cornerRadius: cornerRadius, padding: padding, fill: fill))
    }
}

// MARK: - Button styles

/// The primary action: a solid ink capsule.
struct InkButtonStyle: ButtonStyle {
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .subheadline.weight(.semibold) : .body.weight(.semibold))
            .foregroundStyle(Color.inkInverse)
            .padding(.horizontal, compact ? 18 : 24)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 40 : 56)
            .background(Color.ink, in: .capsule)
            .opacity(isEnabled ? 1 : 0.3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.smooth, value: isEnabled)
    }
}

/// A quiet secondary action on a surface.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .background(Color.well, in: .capsule)
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
            .opacity(configuration.isPressed ? 0.9 : 1)
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
