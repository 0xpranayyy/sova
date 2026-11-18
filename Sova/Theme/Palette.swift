import SwiftUI
import UIKit

// MARK: - Color primitives

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: opacity))
    }

    /// A color that resolves differently in light and dark appearance.
    init(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

// MARK: - Semantic tokens
//
// A warm paper canvas and an ink that's never pure black. Everything else
// is built from these plus a single accent at a time.

extension Color {
    /// The page. Warm off-white / deep warm black.
    static let canvas = Color(light: 0xF6F3EE, dark: 0x0F0E0D)
    /// Raised content: cards, grouped lists.
    static let surface = Color(light: 0xFFFFFF, dark: 0x1A1917)
    /// Recessed fills: tracks, unselected tiles.
    static let well = Color(light: 0x1B1915, dark: 0xF3EFE8, lightAlpha: 0.05, darkAlpha: 0.07)
    /// Primary text and the primary button.
    static let ink = Color(light: 0x1B1915, dark: 0xF3EFE8)
    /// Text on top of `ink`.
    static let inkInverse = Color(light: 0xF6F3EE, dark: 0x141311)
    /// Secondary text, a touch warmer than system gray.
    static let inkSecondary = Color(light: 0x1B1915, dark: 0xF3EFE8, lightAlpha: 0.56, darkAlpha: 0.58)
    static let inkTertiary = Color(light: 0x1B1915, dark: 0xF3EFE8, lightAlpha: 0.32, darkAlpha: 0.34)
    /// 1px separators and card edges.
    static let hairline = Color(light: 0x1B1915, dark: 0xFFFFFF, lightAlpha: 0.08, darkAlpha: 0.08)
}

// MARK: - Accents

/// A short, curated set of flat accents. Each is tuned separately for dark
/// mode rather than just being made lighter.
enum Accent: String, CaseIterable, Identifiable {
    case ember, marigold, moss, lagoon, tide, plum, rose, clay, graphite

    var id: String { rawValue }

    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .ember: Color(light: 0xE0532F, dark: 0xFF6B47)
        case .marigold: Color(light: 0xD98E1C, dark: 0xF5B145)
        case .moss: Color(light: 0x4C8A57, dark: 0x6DB07A)
        case .lagoon: Color(light: 0x16918F, dark: 0x2DB5B0)
        case .tide: Color(light: 0x2B63D9, dark: 0x5A8BFF)
        case .plum: Color(light: 0x7448B5, dark: 0xA27BE6)
        case .rose: Color(light: 0xD24A73, dark: 0xF06A93)
        case .clay: Color(light: 0xA9714F, dark: 0xCC926F)
        case .graphite: Color(light: 0x4A4E55, dark: 0xA4A9B1)
        }
    }

    /// Low-contrast tint for icon tiles and selected rows.
    var soft: Color { color.opacity(0.13) }
}

// MARK: - Themes

/// The app's overall mood: an accent, plus a companion that colors the
/// soft light at the top of the canvas.
enum SovaTheme: String, CaseIterable, Identifiable {
    case ember, tide, moss, plum, graphite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ember: "Ember"
        case .tide: "Tide"
        case .moss: "Moss"
        case .plum: "Plum"
        case .graphite: "Ink"
        }
    }

    var accent: Accent {
        switch self {
        case .ember: .ember
        case .tide: .tide
        case .moss: .moss
        case .plum: .plum
        case .graphite: .graphite
        }
    }

    var companion: Accent {
        switch self {
        case .ember: .marigold
        case .tide: .lagoon
        case .moss: .marigold
        case .plum: .rose
        case .graphite: .clay
        }
    }

    static var current: SovaTheme {
        SovaTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .ember
    }
}
