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

/// A small secondary label (name kept for existing call sites).
struct MonoCaps: View {
    let text: String
    var color: Color = .inkSecondary
    var size: CGFloat = 13

    init(_ text: String, color: Color = .inkSecondary, size: CGFloat = 13) {
        self.text = text
        self.color = color
        self.size = max(size, 12)
    }

    var body: some View {
        Text(text)
            .font(.allo(size: size, weight: .semibold, relativeTo: .footnote))
            .foregroundStyle(color)
    }
}

/// A section heading: bold, night.
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil
    var color: Color = .ink

    init(_ title: String, trailing: String? = nil, color: Color = .ink) {
        self.title = title
        self.trailing = trailing
        self.color = color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.allo(.subheadline, .bold))
                .foregroundStyle(color)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.allo(.footnote, .semibold).monospacedDigit())
                    .foregroundStyle(Color.inkSecondary)
                    .contentTransition(.numericText())
            }
        }
        .textCase(nil)
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A big, tight, heavy screen title.
struct ScreenTitle<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.hero(34, weight: .heavy))
                    .tracking(-1.4)
                    .foregroundStyle(Color.ink)
                Spacer()
                trailing
            }
            if let subtitle {
                Text(subtitle)
                    .font(.allo(.subheadline, .semibold))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// A round white button for the top-right action of a screen.
struct CircleAction: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 42, height: 42)
                .background(Color.white, in: .circle)
                .shadow(color: Color.night.opacity(0.06), radius: 6, y: 2)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }
}
