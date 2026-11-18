import SwiftUI

// SF Pro Display for big, tight numbers and headlines; SF Mono for small
// uppercase details, times and counts.

extension Font {
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .default, weight: weight)
    }

    static func hero(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Small uppercase monospaced label.
struct MonoCaps: View {
    let text: String
    var color: Color = .inkTertiary
    var size: CGFloat = 11

    init(_ text: String, color: Color = .inkTertiary, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.mono(size))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

/// A section heading: mono caps on the left, a mono detail on the right.
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil
    var color: Color = .inkTertiary

    init(_ title: String, trailing: String? = nil, color: Color = .inkTertiary) {
        self.title = title
        self.trailing = trailing
        self.color = color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            MonoCaps(title, color: color)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.mono(10.5))
                    .foregroundStyle(Color.inkTertiary)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}
