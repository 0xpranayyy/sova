import SwiftUI
import UIKit
import CoreText

// Typeface: Allo by Josh Puckett (SIL Open Font License 1.1, see
// Resources/Fonts/Allo-OFL.txt). Every font in the app goes through these
// helpers so the whole interface speaks with one voice.

enum Allo {
    /// Registers the bundled Allo fonts for this process. Call once at launch.
    static func register() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? []
        for url in urls where url.lastPathComponent.hasPrefix("Allo-") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func name(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy: "Allo-ExtraBold"
        case .bold: "Allo-Bold"
        case .semibold: "Allo-SemiBold"
        case .medium: "Allo-Medium"
        default: "Allo-Regular"
        }
    }

    static func size(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    static func uiFont(size: CGFloat, weight: Font.Weight, style: UIFont.TextStyle) -> UIFont {
        let base = UIFont(name: name(weight), size: size) ?? .systemFont(ofSize: size)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }

    /// Allo in UIKit-drawn chrome: navigation titles.
    static func applyToUIKit() {
        let nav = UINavigationBar.appearance()
        nav.titleTextAttributes = [.font: uiFont(size: 17, weight: .semibold, style: .headline)]
        nav.largeTitleTextAttributes = [.font: uiFont(size: 34, weight: .bold, style: .largeTitle)]
    }
}

extension Font {
    /// Allo at a Dynamic Type text style.
    static func allo(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .custom(Allo.name(style == .headline && weight == .regular ? .semibold : weight),
                size: Allo.size(style), relativeTo: style)
    }

    /// Allo at a specific size that still scales with Dynamic Type.
    static func allo(size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(Allo.name(weight), size: size, relativeTo: style)
    }

    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .allo(style, weight)
    }

    /// Big numbers and headlines.
    static func hero(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .allo(size: size, weight: weight, relativeTo: .largeTitle)
    }

    /// Times and counts: Allo with tabular figures, so digits line up.
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .allo(size: size, weight: weight, relativeTo: .caption).monospacedDigit()
    }
}

/// A tiny uppercase monospaced label, used sparingly on cards
/// ("UP NEXT · 14:00", "01 · 21 DAYS LEFT").
struct MonoCaps: View {
    let text: String
    var color: Color = .black.opacity(0.45)
    var size: CGFloat = 10.5

    init(_ text: String, color: Color = .black.opacity(0.45), size: CGFloat = 10.5) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .regular, design: .monospaced))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

/// A section heading: quiet, sentence case.
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil
    var color: Color = .inkSecondary

    init(_ title: String, trailing: String? = nil, color: Color = .inkSecondary) {
        self.title = title
        self.trailing = trailing
        self.color = color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.allo(.subheadline, .medium))
                .foregroundStyle(color)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.mono(13, weight: .regular))
                    .foregroundStyle(Color.inkTertiary)
                    .contentTransition(.numericText())
            }
        }
        .textCase(nil)
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}
