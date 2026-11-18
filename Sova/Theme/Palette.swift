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
}

// MARK: - Semantic tokens
//
// Sova is dark-first: a near-black canvas, warm-white ink, hairlines at a
// few percent white, and one electric accent used sparingly.

extension Color {
    static let canvas = Color(hex: 0x08080A)
    static let ink = Color(hex: 0xF5F5F7)
    static let inkSecondary = Color(hex: 0xEBEBF5, opacity: 0.56)
    static let inkTertiary = Color(hex: 0xEBEBF5, opacity: 0.30)
    /// Text and glyphs placed on the accent or on the white pill.
    static let inkInverse = Color(hex: 0x08080A)
    static let well = Color.white.opacity(0.08)
    static let surface = Color.white.opacity(0.04)
    static let surfaceRaised = Color.white.opacity(0.06)
    static let hairline = Color.white.opacity(0.07)
    static let danger = Color(hex: 0xFF6B4A)
}

// MARK: - Accents

/// Item colors, tuned to glow on near-black.
enum Accent: String, CaseIterable, Identifiable {
    case lime, ember, marigold, moss, lagoon, tide, plum, rose, clay, graphite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .lime: "Lime"
        case .ember: "Coral"
        case .marigold: "Amber"
        case .moss: "Mint"
        case .lagoon: "Teal"
        case .tide: "Ice"
        case .plum: "Violet"
        case .rose: "Pink"
        case .clay: "Sand"
        case .graphite: "Steel"
        }
    }

    var color: Color {
        switch self {
        case .lime: Color(hex: 0xC8FF4D)
        case .ember: Color(hex: 0xFF6B4A)
        case .marigold: Color(hex: 0xFFC24D)
        case .moss: Color(hex: 0x4DE0B0)
        case .lagoon: Color(hex: 0x4DD4E0)
        case .tide: Color(hex: 0x7CC8FF)
        case .plum: Color(hex: 0xB18CFF)
        case .rose: Color(hex: 0xFF7EB0)
        case .clay: Color(hex: 0xE8C9A0)
        case .graphite: Color(hex: 0xA0A6B5)
        }
    }

    /// Kept for older call sites; always a single flat color.
    var gradient: Color { color }
    var soft: Color { color.opacity(0.14) }
}

// MARK: - Themes

/// The one electric accent the whole app is built around.
enum SovaTheme: String, CaseIterable, Identifiable {
    case lime, ember, tide, plum, moss

    var id: String { rawValue }

    var name: String { accent.name }

    var accent: Accent {
        switch self {
        case .lime: .lime
        case .ember: .ember
        case .tide: .tide
        case .plum: .plum
        case .moss: .moss
        }
    }

    var companion: Accent { accent }
    var swatch: Color { accent.color }

    static var current: SovaTheme {
        SovaTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .lime
    }
}
