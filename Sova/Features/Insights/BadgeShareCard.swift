import SwiftUI

/// What a shared badge looks like: a designed image, not just the sticker.
enum BadgeShareFormat: String, CaseIterable, Identifiable {
    case story, book
    var id: String { rawValue }
    var title: String {
        switch self {
        case .story: String(localized: "New badge")
        case .book: String(localized: "Sticker book")
        }
    }
}

/// The share sheet: a live preview of the image, a switch between the
/// two designs, and the iOS share sheet.
struct BadgeShareSheet: View {
    let badge: Badge
    let badges: [Badge]
    let streak: Int

    @AppStorage("userName") private var userName = ""
    @State private var format: BadgeShareFormat = .story
    @State private var rendered: Image?
    @Environment(\.dismiss) private var dismiss

    private var name: String { userName.trimmingCharacters(in: .whitespaces) }

    private var message: String {
        let line = String(localized: "I just earned “\(badge.title)” in Sova 🦉")
        guard let link = Links.appPage else { return line }
        return line + " " + link.absoluteString
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Picker(String(localized: "Design"), selection: $format) {
                    ForEach(BadgeShareFormat.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                card
                    .scaleEffect(0.72)
                    .frame(width: 360 * 0.72, height: 640 * 0.72)
                    .shadow(color: Color.night.opacity(0.2), radius: 20, y: 12)
                    .animation(.smooth(duration: 0.3), value: format)

                Spacer(minLength: 0)

                if let rendered {
                    ShareLink(item: rendered, message: Text(message),
                              preview: SharePreview(badge.title, image: rendered)) {
                        Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.big(.indigo))
                } else {
                    ProgressView().frame(height: 60)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background { CanvasBackground() }
            .navigationTitle(String(localized: "Share"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(role: .close) { dismiss() } }
            }
        }
        .task(id: format) { render() }
    }

    @ViewBuilder
    private var card: some View {
        switch format {
        case .story:
            StoryShareCard(badge: badge, name: name,
                           collected: badges.filter(\.earned).count, total: badges.count)
        case .book:
            BookShareCard(badges: badges, name: name, streak: streak)
        }
    }

    /// Draws the card at 3× (1080 × 1920) for a sharp image.
    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = 3
        if let image = renderer.uiImage { rendered = Image(uiImage: image) }
    }
}

// MARK: - The designs (drawn at 360 × 640 points)

/// The unlock scene as a story: sunburst, confetti, the sticker, your name
/// and collection, and an App Store tag.
struct StoryShareCard: View {
    let badge: Badge
    let name: String
    let collected: Int
    let total: Int

    var body: some View {
        ZStack {
            StickerTone.indigo.fill
            ShareRays(color: Color.white.opacity(0.05), center: UnitPoint(x: 0.5, y: 0.39))
            Confetti()
            VStack(spacing: 0) {
                ShareHeader(dark: true)
                Text("★ " + String(localized: "NEW BADGE") + " ★")
                    .font(.allo(size: 12, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(StickerTone.yellow.deep)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 6)
                    .background(StickerTone.yellow.fill, in: .capsule)
                    .rotationEffect(.degrees(-3))
                    .padding(.top, 24)
                Image(badge.sticker)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 214, height: 214)
                    .rotationEffect(.degrees(-6))
                    .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
                    .padding(.top, 14)
                Text("\(badge.title)\(Text(".").foregroundStyle(StickerTone.yellow.fill))")
                    .font(.hero(44, weight: .heavy))
                    .tracking(-2)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 14)
                Text(badge.story)
                    .font(.allo(size: 15, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 34)
                    .padding(.top, 6)
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { index in
                        Capsule()
                            .fill(index < collected ? StickerTone.yellow.fill : Color.white.opacity(0.2))
                            .frame(width: index < collected ? 18 : 7, height: 7)
                    }
                }
                .padding(.top, 16)
                Text(name.isEmpty ? String(localized: "\(collected) of \(total) stickers collected")
                                  : String(localized: "\(name) · \(collected) of \(total) stickers collected"))
                    .font(.allo(size: 12, weight: .heavy))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .padding(.top, 8)
                Spacer(minLength: 0)
                AppStoreTag(title: String(localized: "Plan your day with Sova"), dark: false)
            }
            .padding(18)
        }
        .frame(width: 360, height: 640)
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
    }
}

/// The whole collection on a dotted page, with the rest as "?".
struct BookShareCard: View {
    let badges: [Badge]
    let name: String
    let streak: Int

    var body: some View {
        let earned = badges.filter(\.earned).count
        VStack(alignment: .leading, spacing: 0) {
            ShareHeader(dark: false)
            Text.marked(name.isEmpty ? String(localized: "My\n*sticker book*.")
                                     : String(localized: "\(name)'s\n*sticker book*."))
                .font(.hero(40, weight: .heavy))
                .tracking(-1.8)
                .foregroundStyle(Color(hex: 0x15102E))
                .textRenderer(MarkerRenderer(color: StickerTone.yellow.fill))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, 26)
            Text(streak > 1 ? String(localized: "\(earned) of \(badges.count) collected · 🔥 \(streak)-day streak")
                            : String(localized: "\(earned) of \(badges.count) collected"))
                .font(.allo(size: 13, weight: .heavy))
                .foregroundStyle(Color(hex: 0x15102E).opacity(0.5))
                .padding(.top, 8)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 14) {
                ForEach(Array(badges.enumerated()), id: \.element.id) { position, badge in
                    if badge.earned {
                        Image(badge.sticker)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .rotationEffect(.degrees([-7.0, 5, -3, 6, -5, 4, -6, 3, -4][position % 9]))
                            .shadow(color: Color(hex: 0x120840).opacity(0.18), radius: 6, y: 4)
                    } else {
                        Circle()
                            .strokeBorder(Color(hex: 0x15102E).opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .frame(width: 88, height: 88)
                            .overlay {
                                Text("?").font(.hero(26, weight: .heavy))
                                    .foregroundStyle(Color(hex: 0x15102E).opacity(0.15))
                            }
                    }
                }
            }
            .padding(.top, 22)
            Spacer(minLength: 0)
            AppStoreTag(title: String(localized: "Collect them with Sova"), dark: true)
        }
        .padding(18)
        .frame(width: 360, height: 640, alignment: .topLeading)
        .background {
            ZStack {
                Color(hex: 0xFFFDF6)
                Canvas { context, size in
                    var y: CGFloat = 8
                    while y < size.height {
                        var x: CGFloat = 8
                        while x < size.width {
                            context.fill(Path(ellipseIn: CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2)),
                                         with: .color(Color(hex: 0x15102E).opacity(0.07)))
                            x += 16
                        }
                        y += 16
                    }
                }
            }
        }
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Pieces

/// The Sova mark: the owl on an indigo tile, and the name.
private struct ShareHeader: View {
    let dark: Bool

    var body: some View {
        HStack(spacing: 8) {
            SovaTile(size: 30)
            Text("Sova")
                .font(.allo(size: 17, weight: .heavy))
                .tracking(-0.3)
                .foregroundStyle(dark ? Color.white : Color(hex: 0x15102E))
            Spacer()
            Text(Date.now.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                .font(.mono(10))
                .foregroundStyle(dark ? Color.white.opacity(0.55) : Color(hex: 0x15102E).opacity(0.45))
        }
    }
}

/// The app icon, drawn: the yellow owl on indigo.
private struct SovaTile: View {
    let size: CGFloat

    var body: some View {
        OwlMark(size: size * 0.62, blinks: false, bodyColor: StickerTone.yellow.fill, eyeColor: StickerTone.indigo.fill,
                pupilColor: StickerTone.yellow.fill, bellyColor: Color.owlBelly, reactsToTap: false)
            .frame(width: size, height: size)
            .background(Color(hex: 0x2B1677), in: .rect(cornerRadius: size * 0.23, style: .continuous))
    }
}

/// "Plan your day with Sova · Free on the App Store · GET".
private struct AppStoreTag: View {
    let title: String
    let dark: Bool

    var body: some View {
        HStack(spacing: 10) {
            SovaTile(size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.allo(size: 15, weight: .heavy))
                    .foregroundStyle(dark ? Color.white : Color(hex: 0x15102E))
                Text(String(localized: "Free on the App Store")).font(.allo(size: 11, weight: .bold))
                    .foregroundStyle(dark ? Color.white.opacity(0.55) : Color(hex: 0x15102E).opacity(0.5))
            }
            Spacer(minLength: 4)
            Text("GET")
                .font(.allo(size: 12, weight: .heavy))
                .foregroundStyle(dark ? StickerTone.yellow.deep : Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(dark ? StickerTone.yellow.fill : Color(hex: 0x2B1677), in: .capsule)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(dark ? Color(hex: 0x2B1677) : Color.white, in: .rect(cornerRadius: 18, style: .continuous))
    }
}

/// Still sunburst rays, for images.
private struct ShareRays: View {
    let color: Color
    let center: UnitPoint

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width * center.x, y: size.height * center.y)
            let reach: CGFloat = max(size.width, size.height) * 1.5
            for index in 0..<20 {
                let start: Double = Angle.degrees(Double(index) * 18).radians
                let end: Double = start + Angle.degrees(9).radians
                var ray = Path()
                ray.move(to: origin)
                ray.addLine(to: CGPoint(x: origin.x + reach * cos(start), y: origin.y + reach * sin(start)))
                ray.addLine(to: CGPoint(x: origin.x + reach * cos(end), y: origin.y + reach * sin(end)))
                ray.closeSubpath()
                context.fill(ray, with: .color(color))
            }
        }
    }
}

/// A few flat confetti pieces in sticker colors.
private struct Confetti: View {
    private let pieces: [(CGFloat, CGFloat, CGFloat, CGFloat, StickerTone, Double)] = [
        (50, 120, 10, 16, .yellow, 20), (300, 150, 8, 14, .mint, -30), (40, 330, 9, 15, .pink, 40),
        (310, 360, 10, 10, .cyan, 15), (30, 470, 7, 12, .lilac, -20), (270, 90, 8, 12, .orange, 30),
    ]

    var body: some View {
        Canvas { context, _ in
            for (x, y, w, h, tone, angle) in pieces {
                var piece = context
                piece.translateBy(x: x, y: y)
                piece.rotate(by: .degrees(angle))
                piece.fill(Path(roundedRect: CGRect(x: 0, y: 0, width: w, height: h), cornerRadius: 3),
                           with: .color(tone.fill))
            }
        }
    }
}
