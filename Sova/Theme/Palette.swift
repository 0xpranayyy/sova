import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Per-item accent colors. Each pairs with a neighbor for a soft gradient.
enum Accent: String, CaseIterable, Identifiable {
    case iris, orchid, rose, coral, peach, lime, mint, lagoon, sky

    var id: String { rawValue }

    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .iris: Color(hex: 0x7B6CFF)
        case .orchid: Color(hex: 0xC06BFF)
        case .rose: Color(hex: 0xFF5C8A)
        case .coral: Color(hex: 0xFF7A59)
        case .peach: Color(hex: 0xFFAA4C)
        case .lime: Color(hex: 0x8FD14F)
        case .mint: Color(hex: 0x2FD39A)
        case .lagoon: Color(hex: 0x1FBFB8)
        case .sky: Color(hex: 0x3BA8F5)
        }
    }

    /// Gradient partner, slightly shifted in hue.
    var partner: Color {
        switch self {
        case .iris: Color(hex: 0xA77BFF)
        case .orchid: Color(hex: 0xFF7EDB)
        case .rose: Color(hex: 0xFF8E6B)
        case .coral: Color(hex: 0xFFB04C)
        case .peach: Color(hex: 0xFFD45C)
        case .lime: Color(hex: 0x3DD68C)
        case .mint: Color(hex: 0x2EC4D6)
        case .lagoon: Color(hex: 0x3B9CF5)
        case .sky: Color(hex: 0x7B6CFF)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [color, partner], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// App-wide background themes. Each is a 3×3 mesh of hand-picked colors.
enum AuroraTheme: String, CaseIterable, Identifiable {
    case aurora, sunset, lagoon, twilight, bloom

    var id: String { rawValue }

    var name: String {
        switch self {
        case .aurora: "Aurora"
        case .sunset: "Sunset"
        case .lagoon: "Lagoon"
        case .twilight: "Twilight"
        case .bloom: "Bloom"
        }
    }

    var symbol: String {
        switch self {
        case .aurora: "sparkles"
        case .sunset: "sun.horizon.fill"
        case .lagoon: "water.waves"
        case .twilight: "moon.stars.fill"
        case .bloom: "camera.macro"
        }
    }

    var tint: Color {
        switch self {
        case .aurora: Accent.iris.color
        case .sunset: Accent.coral.color
        case .lagoon: Accent.lagoon.color
        case .twilight: Accent.orchid.color
        case .bloom: Accent.rose.color
        }
    }

    /// Colors for the progress ring on Today.
    var ringColors: [Color] {
        switch self {
        case .aurora: [Accent.iris.color, Accent.orchid.color, Accent.lagoon.color]
        case .sunset: [Accent.coral.color, Accent.rose.color, Accent.peach.color]
        case .lagoon: [Accent.lagoon.color, Accent.sky.color, Accent.mint.color]
        case .twilight: [Accent.iris.color, Accent.orchid.color, Accent.rose.color]
        case .bloom: [Accent.rose.color, Accent.orchid.color, Accent.peach.color]
        }
    }

    private var base: [UInt32] {
        switch self {
        case .aurora:   [0x3A2A9E, 0x6A4CFF, 0x22B8C9,
                         0x7B6CFF, 0xC06BFF, 0x3BA8F5,
                         0xFF5C8A, 0x6C4BFF, 0x2FD39A]
        case .sunset:   [0xFF7A59, 0xFF5C8A, 0xB86BFF,
                         0xFFAA4C, 0xFF8FA3, 0x7B6CFF,
                         0xFFD27A, 0xFF7A59, 0x5B3FD9]
        case .lagoon:   [0x0E7C86, 0x1FBFB8, 0x3BA8F5,
                         0x2FD39A, 0x5EE0D0, 0x3A86FF,
                         0x8FD14F, 0x1FBFB8, 0x7B6CFF]
        case .twilight: [0x1B1446, 0x3A2A8C, 0x6A4CFF,
                         0x4C2A85, 0xC06BFF, 0x3A86FF,
                         0xFF5C8A, 0x5B3FD9, 0x1E2A78]
        case .bloom:    [0xFF8FA3, 0xFFB3C7, 0xC06BFF,
                         0xFFAA4C, 0xFFD0DC, 0xB8A1FF,
                         0xFF5C8A, 0xF29CFF, 0x7B6CFF]
        }
    }

    /// Pastel in light mode, deep and saturated in dark mode.
    func meshColors(dark: Bool) -> [Color] {
        base.map { hex in
            let c = Color(hex: hex)
            return dark ? c.mix(with: .black, by: 0.42) : c.mix(with: .white, by: 0.5)
        }
    }
}
