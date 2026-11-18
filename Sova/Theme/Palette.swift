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
// Warm paper, soft-black ink, white hairline cards. Color comes from one
// sunlit moment per screen, never from the chrome.

extension Color {
    static let canvas = Color(hex: 0xFBFAF6)
    static let ink = Color.black.opacity(0.86)
    static let inkSecondary = Color.black.opacity(0.52)
    static let inkTertiary = Color.black.opacity(0.32)
    /// Text on black buttons and filled checks.
    static let inkInverse = Color(hex: 0xF8F8F8)
    static let well = Color.black.opacity(0.06)
    static let surface = Color.white
    static let surfaceRaised = Color.white
    static let hairline = Color.black.opacity(0.08)
    static let danger = Color(hex: 0xD9483B)
    /// The sunlight: used for highlights, never for chrome.
    static let sun = Color(hex: 0xE9B10F)
    static let sunSoft = Color(hex: 0xFCE7A4)
}

// MARK: - Accents

/// Item colors (kept for stored data and the accent setting).
enum Accent: String, CaseIterable, Identifiable {
    case ink, lime, ember, marigold, moss, lagoon, tide, plum, rose, clay, graphite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ink: "Ink"
        case .lime: "Lime"
        case .ember: "Clay"
        case .marigold: "Sun"
        case .moss: "Fern"
        case .lagoon: "Teal"
        case .tide: "Lake"
        case .plum: "Plum"
        case .rose: "Rose"
        case .clay: "Sand"
        case .graphite: "Slate"
        }
    }

    var color: Color {
        switch self {
        case .ink: Color.black
        case .lime: Color(hex: 0x7A9A1F)
        case .ember: Color(hex: 0xC4532F)
        case .marigold: Color(hex: 0xC9940A)
        case .moss: Color(hex: 0x3F7D4E)
        case .lagoon: Color(hex: 0x1F7A80)
        case .tide: Color(hex: 0x2F5FA8)
        case .plum: Color(hex: 0x6E4A9E)
        case .rose: Color(hex: 0xB8466B)
        case .clay: Color(hex: 0xA77B52)
        case .graphite: Color(hex: 0x4A4E55)
        }
    }

    var gradient: Color { color }
    var soft: Color { color.opacity(0.1) }
}

// MARK: - Themes

/// The accent used for checks, progress and the create button.
enum SovaTheme: String, CaseIterable, Identifiable {
    case ink, ember, tide, plum, moss

    var id: String { rawValue }
    var name: String { accent.name }

    var accent: Accent {
        switch self {
        case .ink: .ink
        case .ember: .ember
        case .tide: .tide
        case .plum: .plum
        case .moss: .moss
        }
    }

    var companion: Accent { accent }
    var swatch: Color { accent.color }

    static var current: SovaTheme {
        SovaTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .ink
    }
}
