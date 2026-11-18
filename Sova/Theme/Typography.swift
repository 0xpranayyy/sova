import SwiftUI
import UIKit

// Display type is New York (the system serif). It gives the app an
// editorial voice. UI type stays SF Pro for clarity.

extension Font {
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}

/// Small uppercase label for sections.
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil

    init(_ title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textCase(.uppercase)
                .tracking(1.1)
            Spacer()
            if let trailing {
                Text(trailing)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.inkSecondary)
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

enum NavigationBarStyle {
    /// Serif titles in navigation bars, still scaled for Dynamic Type.
    static func apply() {
        func serif(_ style: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let font = base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
            return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        }
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: serif(.largeTitle, size: 34, weight: .regular)]
        appearance.titleTextAttributes = [.font: serif(.headline, size: 17, weight: .semibold)]
    }
}
