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
// System label colors, so text stays vibrant and legible on Liquid Glass
// in both appearances.

extension Color {
    static let ink = Color(uiColor: .label)
    static let inkSecondary = Color(uiColor: .secondaryLabel)
    static let inkTertiary = Color(uiColor: .tertiaryLabel)
    static let inkInverse = Color(uiColor: .systemBackground)
    static let canvas = Color(uiColor: .systemBackground)
    /// Translucent fill for things sitting on glass: tracks, idle chips.
    static let well = Color(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.07, darkAlpha: 0.12)
    /// A frosted fill, for the few places glass can't be used.
    static let surface = Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.6, darkAlpha: 0.1)
    static let hairline = Color(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.08, darkAlpha: 0.12)
}

// MARK: - Accents

/// Vivid, flat accents. Used as solid fills, never blended.
enum Accent: String, CaseIterable, Identifiable {
    case ember, marigold, moss, lagoon, tide, plum, rose, clay, graphite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ember: "Coral"
        case .marigold: "Amber"
        case .moss: "Mint"
        case .lagoon: "Teal"
        case .tide: "Blue"
        case .plum: "Violet"
        case .rose: "Pink"
        case .clay: "Peach"
        case .graphite: "Indigo"
        }
    }

    var color: Color {
        switch self {
        case .ember: Color(light: 0xFF5E3A, dark: 0xFF7155)
        case .marigold: Color(light: 0xFF9F0A, dark: 0xFFB340)
        case .moss: Color(light: 0x19C37D, dark: 0x30D98F)
        case .lagoon: Color(light: 0x00B5B8, dark: 0x30D5D8)
        case .tide: Color(light: 0x2F7BFF, dark: 0x5A9BFF)
        case .plum: Color(light: 0x8A5CFF, dark: 0xA88BFF)
        case .rose: Color(light: 0xFF3B7F, dark: 0xFF6198)
        case .clay: Color(light: 0xFF8A5C, dark: 0xFFA37F)
        case .graphite: Color(light: 0x5856D6, dark: 0x7D7AFF)
        }
    }

    var partner: Color {
        switch self {
        case .ember: Accent.rose.color
        case .marigold: Accent.ember.color
        case .moss: Accent.lagoon.color
        case .lagoon: Accent.tide.color
        case .tide: Accent.plum.color
        case .plum: Accent.rose.color
        case .rose: Accent.plum.color
        case .clay: Accent.marigold.color
        case .graphite: Accent.tide.color
        }
    }

    /// Solid fill as a ShapeStyle. (Named for history; it is intentionally
    /// a single flat color.)
    var gradient: Color { color }

    var soft: Color { color.opacity(0.18) }
}

// MARK: - Themes

/// The app's mood: one accent, and a flat page tinted with it.
enum SovaTheme: String, CaseIterable, Identifiable {
    case ember, tide, moss, plum, graphite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ember: "Sunset"
        case .tide: "Ocean"
        case .moss: "Meadow"
        case .plum: "Aurora"
        case .graphite: "Midnight"
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
        case .moss: .lagoon
        case .plum: .rose
        case .graphite: .plum
        }
    }

    var swatch: Color { accent.color }

    /// A flat page color: a whisper of the accent in light mode, a deep
    /// tinted near-black in dark mode.
    func canvas(dark: Bool) -> Color {
        let base = accent.color
        return dark ? base.mix(with: .black, by: 0.84) : base.mix(with: .white, by: 0.88)
    }

    static var current: SovaTheme {
        SovaTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .ember
    }
}
