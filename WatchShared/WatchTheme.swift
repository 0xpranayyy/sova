import SwiftUI
import CoreText

// Sova's look on the Watch: the sticker palette and the Allo typeface.
// (The iPhone's Shared/Theme isn't compiled here, so this mirrors it.)

extension Color {
    init(watchHex hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// The eight sticker tones, by the names the iPhone sends.
enum WatchTone: String {
    case yellow, mint, lilac, pink, orange, cyan, lime, indigo

    init(name: String) { self = WatchTone(rawValue: name) ?? .yellow }

    var fill: Color {
        switch self {
        case .yellow: Color(watchHex: 0xFFE94D)
        case .mint: Color(watchHex: 0x4DF2B0)
        case .lilac: Color(watchHex: 0xD9CEFF)
        case .pink: Color(watchHex: 0xFF5C93)
        case .orange: Color(watchHex: 0xFFA03A)
        case .cyan: Color(watchHex: 0x3DCBFF)
        case .lime: Color(watchHex: 0xC2F53A)
        case .indigo: Color(watchHex: 0x3B26A6)
        }
    }

    /// Text and glyphs on the fill.
    var deep: Color {
        switch self {
        case .yellow: Color(watchHex: 0x5E4A00)
        case .mint: Color(watchHex: 0x0B5A3C)
        case .lilac: Color(watchHex: 0x4423B8)
        case .pink: Color(watchHex: 0x5E0A26)
        case .orange: Color(watchHex: 0x6B3400)
        case .cyan: Color(watchHex: 0x063F73)
        case .lime: Color(watchHex: 0x2F5A00)
        case .indigo: Color(watchHex: 0xFFE94D)
        }
    }
}

enum WatchPalette {
    static let night = Color(watchHex: 0x15102E)
    static let indigo = Color(watchHex: 0x2B1677)
    static let yellow = Color(watchHex: 0xFFE94D)
    static let belly = Color(watchHex: 0xFFF4A8)
    static let pink = Color(watchHex: 0xFF5C93)
    static let orange = Color(watchHex: 0xFFA03A)
}

/// Typeface: Allo by Josh Puckett (SIL Open Font License 1.1, see
/// WatchShared/Fonts/Allo-OFL.txt).
enum WatchAllo {
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
}

extension Font {
    /// Allo at a size that still follows the Watch's text size setting.
    static func sova(_ size: CGFloat, _ weight: Font.Weight = .bold, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(WatchAllo.name(weight), size: size, relativeTo: style)
    }
}
