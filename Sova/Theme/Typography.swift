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

/// A small uppercase label, Allo heavy with open tracking ("UP NEXT").
struct MonoCaps: View {
    let text: String
    var color: Color = .inkSecondary
    var size: CGFloat = 11

    init(_ text: String, color: Color = .inkSecondary, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = min(max(size, 10), 12)
    }

    var body: some View {
        Text(text)
            .font(.allo(size: size, weight: .heavy, relativeTo: .caption))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

/// A section heading: a small uppercase label.
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
            MonoCaps(title, color: color)
            Spacer()
            if let trailing {
                MonoCaps(trailing, color: .inkTertiary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A screen header: a small label and action on top, then a huge heavy
/// title that ends with a period, the way Allo sets its name.
struct ScreenTitle<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let subtitle { MonoCaps(subtitle) }
                Spacer()
                trailing
            }
            .frame(minHeight: 44)
            Text(title + ".")
                .font(.hero(58, weight: .heavy))
                .tracking(-2.6)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 4)
    }
}

/// A round white button for a screen's top-right action.
struct CircleAction: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(Color.surface, in: .circle)
                .overlay(Circle().strokeBorder(Color.hairline, lineWidth: 1.5))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }
}
