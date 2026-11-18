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
// Near-white page, deep ink, and Allo's palette (see Components/Sticker.swift)
// used as big flat blocks with tonal text.

extension Color {
    static let ink = Color(hex: 0x15102E)
    static let night = Color.ink
    /// Priority marks and overdue text.
    static let ember = Color(hex: 0xE63E2E)

    static let canvas = Color(hex: 0xFCFCFA)
    static let inkSecondary = Color.ink.opacity(0.5)
    static let inkTertiary = Color.ink.opacity(0.3)
    static let inkInverse = Color.white
    static let well = Color.ink.opacity(0.06)
    static let surface = Color.white
    static let surfaceRaised = Color.white
    static let hairline = Color.ink.opacity(0.07)
    static let danger = Color.ember

    static let skyMorning = StickerTone.orange.fill
    static let skyAfternoon = StickerTone.yellow.fill
    static let skyEvening = StickerTone.lilac.fill

    static func sky(for date: Date = .now) -> Color {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: .skyMorning
        case 12..<17: .skyAfternoon
        default: .skyEvening
        }
    }

    static func sky(for period: DayPeriod) -> Color {
        switch period {
        case .morning: .skyMorning
        case .afternoon, .anytime: .skyAfternoon
        case .evening: .skyEvening
        }
    }
}

// MARK: - Accents

/// Item colors (kept for stored data and the accent setting).
enum Accent: String, CaseIterable, Identifiable {
    case ink, lime, ember, marigold, moss, lagoon, tide, plum, rose, clay, graphite

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ink: "Night"
        case .lime: "Lime"
        case .ember: "Ember"
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
        case .ink: Color.ink
        case .lime: Color(hex: 0x6E9A1F)
        case .ember: StickerTone.orange.fill
        case .marigold: Color(hex: 0xE0A100)
        case .moss: Color(hex: 0x2E9E6B)
        case .lagoon: Color(hex: 0x14919A)
        case .tide: Color(hex: 0x3E6FE0)
        case .plum: Color(hex: 0x7B57D6)
        case .rose: Color(hex: 0xE0457B)
        case .clay: Color(hex: 0xB9825A)
        case .graphite: Color(hex: 0x4A4E55)
        }
    }

    var gradient: Color { color }
    var soft: Color { color.opacity(0.12) }
}

// MARK: - Themes

/// The accent for checks, progress and the create button.
enum SovaTheme: String, CaseIterable, Identifiable {
    case ember, plum, tide, moss, ink

    var id: String { rawValue }
    var name: String { accent.name }

    var accent: Accent {
        switch self {
        case .ember: .ember
        case .plum: .plum
        case .tide: .tide
        case .moss: .moss
        case .ink: .ink
        }
    }

    var companion: Accent { accent }
    var swatch: Color { accent.color }

    static var current: SovaTheme {
        SovaTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .ember
    }
}
