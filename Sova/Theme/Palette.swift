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

/// Vivid accents, each paired with a neighbor for a soft two-tone blend.
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

    var gradient: LinearGradient {
        LinearGradient(colors: [color, partner], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var soft: Color { color.opacity(0.18) }
}

// MARK: - Themes

/// The app's mood: an accent plus a full 3×3 mesh of colors that blends
/// behind every screen.
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

    var swatch: LinearGradient {
        LinearGradient(colors: [accent.color, companion.color], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var mesh: [UInt32] {
        switch self {
        case .ember:    [0xFF8A5C, 0xFF5E7E, 0xC86BFF,
                         0xFFB340, 0xFF7A6B, 0x8A5CFF,
                         0xFFD27A, 0xFF5E3A, 0x5B4BFF]
        case .tide:     [0x2F7BFF, 0x00B5B8, 0x5AD8FF,
                         0x6A6BFF, 0x3FA9FF, 0x30D5D8,
                         0x8A5CFF, 0x2F7BFF, 0x19C37D]
        case .moss:     [0x19C37D, 0x7BE07A, 0x00B5B8,
                         0x30D5A0, 0xA8E05F, 0x3FA9FF,
                         0x00B5B8, 0x19C37D, 0x6A6BFF]
        case .plum:     [0x5B4BFF, 0x8A5CFF, 0x00B5B8,
                         0xC86BFF, 0xFF5E9E, 0x3FA9FF,
                         0xFF3B7F, 0x8A5CFF, 0x19C37D]
        case .graphite: [0x1E1B4B, 0x3730A3, 0x5856D6,
                         0x312E81, 0x7D7AFF, 0x2F7BFF,
                         0xA855F7, 0x4338CA, 0x0E7490]
        }
    }

    /// Bright pastel in light mode, deep and glowing in dark mode.
    func meshColors(dark: Bool) -> [Color] {
        mesh.map { hex in
            let c = Color(hex: hex)
            return dark ? c.mix(with: .black, by: 0.45) : c.mix(with: .white, by: 0.42)
        }
    }

    static var current: SovaTheme {
        SovaTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .ember
    }
}
