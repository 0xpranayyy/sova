import SwiftUI

/// A small palette of one hue: a soft solid, the tints that sit on it, and
/// text tinted from the same color, so everything on a card blends instead
/// of shouting. Used for Today's time-of-day hero.
struct Harmony: Equatable {
    var bg: Color
    /// A step deeper: the far hill.
    var top: Color
    /// A step lighter: the near hill and chips.
    var pill: Color
    var soft: Color
    /// Main text.
    var ink: Color
    /// Secondary text.
    var mute: Color
    /// Progress and the name's period.
    var accent: Color
    /// Whether the card is dark (pale text on it).
    var isDark: Bool

    /// Builds a light harmony from a hue (0…1): a soft pastel with plum-ish
    /// text of the same hue and Sova indigo for the accent.
    static func light(hue: Double, saturation: Double, lightness: Double) -> Harmony {
        Harmony(bg: .hsl(hue, saturation, lightness),
                top: .hsl(hue, saturation - 0.08, lightness - 0.07),
                pill: .hsl(hue, saturation, min(lightness + 0.07, 0.97)),
                soft: .hsl(hue, saturation, min(lightness + 0.11, 0.98)),
                ink: .hsl(hue, 0.40, 0.27),
                mute: .hsl(hue, 0.24, 0.42),
                accent: StickerTone.indigo.fill,
                isDark: false)
    }

    /// Night is the app icon: Sova indigo, white text and yellow accents.
    static let night = Harmony(bg: Color(hex: 0x2B1677), top: Color(hex: 0x22105F), pill: Color(hex: 0x3A2595),
                               soft: Color(hex: 0x4A35A8), ink: .white, mute: Color(hex: 0xB9AEF0),
                               accent: StickerTone.yellow.fill, isDark: true)
}

/// The part of the day, for the hero's color, scene and greeting.
enum DayPart: CaseIterable {
    case dawn, morning, afternoon, evening, night

    static func at(_ date: Date) -> DayPart {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<8: .dawn
        case 8..<12: .morning
        case 12..<17: .afternoon
        case 17..<21: .evening
        default: .night
        }
    }

    static var current: DayPart { at(.now) }

    var harmony: Harmony {
        switch self {
        case .dawn: .light(hue: 0.14, saturation: 0.80, lightness: 0.84)
        case .morning: .light(hue: 0.07, saturation: 0.85, lightness: 0.83)
        case .afternoon: .light(hue: 0.43, saturation: 0.48, lightness: 0.80)
        case .evening: .light(hue: 0.55, saturation: 0.62, lightness: 0.80)
        case .night: .night
        }
    }

    var greeting: String {
        switch self {
        case .dawn: String(localized: "Rise and shine")
        case .morning: String(localized: "Good morning")
        case .afternoon: String(localized: "Good afternoon")
        case .evening: String(localized: "Good evening")
        case .night: Calendar.current.component(.hour, from: .now) < 5 ? String(localized: "Still up")
                                                                      : String(localized: "Good evening")
        }
    }

    var isNight: Bool { self == .night }
}

extension Color {
    /// A color from hue, saturation and lightness (each 0…1).
    static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double) -> Color {
        let s = min(max(saturation, 0), 1), l = min(max(lightness, 0), 1)
        let v = l + s * min(l, 1 - l)
        let sv = v == 0 ? 0 : 2 * (1 - l / v)
        return Color(hue: hue, saturation: sv, brightness: v)
    }
}
