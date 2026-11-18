import SwiftUI

// Following the HIG: Liquid Glass belongs to the navigation/control layer
// that floats above content. Content cards use a standard material with a
// soft accent wash instead, so glass controls stay distinct and legible.

struct CardSurface: ViewModifier {
    var tint: Color?
    var cornerRadius: CGFloat
    var padding: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape.fill(.regularMaterial)
                if let tint {
                    shape.fill(tint.opacity(scheme == .dark ? 0.16 : 0.10))
                }
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(scheme == .dark ? 0.18 : 0.6), .white.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.06), radius: 16, y: 8)
    }
}

extension View {
    func card(tint: Color? = nil, cornerRadius: CGFloat = 26, padding: CGFloat = 18) -> some View {
        modifier(CardSurface(tint: tint, cornerRadius: cornerRadius, padding: padding))
    }
}

extension Glass {
    /// Interactive glass for a control, optionally tinted.
    static func control(tint: Color? = nil) -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        return glass.interactive()
    }
}
