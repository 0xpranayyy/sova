import SwiftUI

/// Tonal sticker colors: a saturated fill, with text and outline in a deep
/// shade of the same hue. Borrowed in spirit from the Allo type specimen.
enum StickerTone: String, CaseIterable {
    case yellow, mint, lilac, pink, orange, cyan, lime, indigo

    var fill: Color {
        switch self {
        case .yellow: Color(hex: 0xFFE94D)
        case .mint: Color(hex: 0x4DF2B0)
        case .lilac: Color(hex: 0xD9CEFF)
        case .pink: Color(hex: 0xFF5C93)
        case .orange: Color(hex: 0xFFA03A)
        case .cyan: Color(hex: 0x3DCBFF)
        case .lime: Color(hex: 0xC2F53A)
        case .indigo: Color(light: 0x2B1677, dark: 0x3B26A6)
        }
    }

    /// Text and glyphs on the fill.
    var deep: Color {
        switch self {
        case .yellow: Color(hex: 0x5E4A00)
        case .mint: Color(hex: 0x0B5A3C)
        case .lilac: Color(hex: 0x4423B8)
        case .pink: Color(hex: 0x5E0A26)
        case .orange: Color(hex: 0x6B3400)
        case .cyan: Color(hex: 0x063F73)
        case .lime: Color(hex: 0x2F5A00)
        case .indigo: Color(hex: 0xFFE94D)
        }
    }

    /// A soft shadow in a deeper shade of the tone.
    var shadow: Color {
        self == .indigo ? Color(hex: 0x120840).opacity(0.35) : deep.opacity(0.22)
    }

    /// The darker edge a chunky button sits on.
    var lip: Color {
        switch self {
        case .yellow: Color(hex: 0xE3C620)
        case .mint: Color(hex: 0x25C98C)
        case .lilac: Color(hex: 0xB3A2F2)
        case .pink: Color(hex: 0xE03D76)
        case .orange: Color(hex: 0xE07F17)
        case .cyan: Color(hex: 0x16A6DB)
        case .lime: Color(hex: 0x9CD11A)
        case .indigo: Color(hex: 0x1A0B4F)
        }
    }

    var border: Color { self == .indigo ? Color(light: 0x1A0B4F, dark: 0x5A45C8) : deep }

    /// A stable tone for an item's stored accent.
    init(_ accent: Accent) {
        switch accent {
        case .plum: self = .lilac
        case .lagoon: self = .mint
        case .ember, .clay: self = .orange
        case .tide: self = .cyan
        case .graphite, .ink: self = .indigo
        case .marigold: self = .yellow
        case .rose: self = .pink
        case .moss, .lime: self = .lime
        }
    }
}
