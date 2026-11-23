import SwiftUI
import SwiftData

// MARK: - Stickers

/// A badge as a sticker: the full art when earned; when locked, the owl's
/// faded silhouette in a dashed circle with a progress ring and a lock.
struct BadgeSticker: View {
    let badge: Badge
    var size: CGFloat = 88
    var tilt: Double = 0

    var body: some View {
        if badge.earned {
            Image(badge.sticker)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(tilt))
                .shadow(color: Color.night.opacity(0.18), radius: size * 0.07, y: size * 0.06)
        } else {
            locked
        }
    }

    private var locked: some View {
        ZStack {
            Circle()
                .stroke(Color.ink.opacity(0.07), lineWidth: size * 0.04)
            if badge.progress > 0 {
                Circle()
                    .trim(from: 0, to: badge.progress)
                    .stroke(StickerTone.indigo.fill, style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Circle()
                .fill(Color.well)
                .overlay(Circle().strokeBorder(Color.ink.opacity(0.12),
                                               style: StrokeStyle(lineWidth: 1.5, dash: [4, 5])))
                .padding(size * 0.1)
            Image(badge.silhouette)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.ink.opacity(0.16))
                .padding(size * 0.22)
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.11, weight: .bold))
                .foregroundStyle(Color.inkSecondary)
                .frame(width: size * 0.28, height: size * 0.28)
                .background(Color.surface, in: .circle)
                .shadow(color: Color.night.opacity(0.12), radius: 3, y: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - The sticker book

/// The badges as a sticker book: the next one you're close to on indigo,
/// then a dotted page of stickers with how far along each locked one is.
struct BadgeShelf: View {
    let badges: [Badge]
    let onTap: (Badge) -> Void

    var body: some View {
        let earned = badges.filter(\.earned).count
        VStack(alignment: .leading, spacing: 12) {
            SectionCaps(title: String(localized: "Badges"), count: "\(earned) / \(badges.count)")
            if let next = Badge.next(in: badges) {
                NextBadgeCard(badge: next).onTapGesture { onTap(next) }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 16) {
                ForEach(Array(badges.enumerated()), id: \.element.id) { position, badge in
                    Button { onTap(badge) } label: { cell(badge, position: position) }
                        .buttonStyle(.pressable)
                        .accessibilityLabel(badge.title)
                        .accessibilityValue(badge.earned ? String(localized: "Earned")
                                                         : String(localized: "Locked, \(badge.progressText). \(badge.howTo)"))
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            .background { page }
        }
    }

    private func cell(_ badge: Badge, position: Int) -> some View {
        VStack(spacing: 5) {
            BadgeSticker(badge: badge, size: 86, tilt: [-7.0, 5, -3, 6, -5, 4, -6, 3, -4][position % 9])
            Text(badge.title)
                .font(.allo(size: 13, weight: .heavy, relativeTo: .caption))
                .foregroundStyle(badge.earned ? Color.ink : Color.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 2)
            if badge.earned {
                Text("✓ " + String(localized: "EARNED"))
                    .font(.allo(size: 10, weight: .heavy, relativeTo: .caption2))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(StickerTone.mint.lip, in: .capsule)
            } else {
                Text(badge.progressText)
                    .font(.mono(10.5))
                    .foregroundStyle(Color.inkTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Warm paper with a faint dot grid.
    private var page: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
        return ZStack {
            shape.fill(Color(light: 0xFFFDF6, dark: 0x1A1533))
            Canvas { context, size in
                let step: CGFloat = 16
                var y: CGFloat = step / 2
                while y < size.height {
                    var x: CGFloat = step / 2
                    while x < size.width {
                        context.fill(Path(ellipseIn: CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2)),
                                     with: .color(Color.ink.opacity(0.07)))
                        x += step
                    }
                    y += step
                }
            }
            .clipShape(shape)
            shape.strokeBorder(Color.hairline, lineWidth: 1.5)
        }
        .shadow(color: Color.night.opacity(0.05), radius: 14, y: 7)
    }
}

/// "Next badge · Perfect week" on indigo with a segmented progress bar.
private struct NextBadgeCard: View {
    let badge: Badge

    var body: some View {
        HStack(spacing: 14) {
            Image(badge.sticker)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-8))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                MonoCaps(String(localized: "Next badge · \(badge.progressText)"), color: StickerTone.yellow.fill)
                    .lineLimit(1)
                Text(badge.title)
                    .font(.allo(size: 20, weight: .heavy, relativeTo: .title3))
                    .tracking(-0.4)
                    .foregroundStyle(.white)
                Text(badge.howTo)
                    .font(.allo(size: 13, weight: .bold, relativeTo: .footnote))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.16))
                        Capsule().fill(StickerTone.yellow.fill)
                            .frame(width: max(10, geo.size.width * badge.progress))
                    }
                }
                .frame(height: 9)
                .padding(.top, 4)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 18)
        .padding(.vertical, 14)
        .background(StickerTone.indigo.fill, in: .rect(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The unlock moment

/// A new badge: sunburst rays, confetti, and the sticker slapping down.
struct BadgeUnlockView: View {
    let badge: Badge
    let collected: Int
    let total: Int
    let onDone: () -> Void

    @Query private var tasks: [TaskItem]
    @Query private var routines: [Routine]
    @Query private var goals: [Goal]
    @State private var sharing = false

    @State private var landed = false
    @State private var cheers = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            StickerTone.indigo.fill.ignoresSafeArea()
            SunRays(spinning: !reduceMotion).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("★ " + String(localized: "NEW BADGE") + " ★")
                    .font(.allo(size: 14, weight: .heavy, relativeTo: .footnote))
                    .tracking(1)
                    .foregroundStyle(StickerTone.yellow.deep)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(StickerTone.yellow.fill, in: .capsule)
                    .rotationEffect(.degrees(-3))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 5)
                    .padding(.top, 40)
                Spacer(minLength: 16)
                Image(badge.sticker)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .rotationEffect(.degrees(landed ? -6 : -24))
                    .scaleEffect(landed ? 1 : 1.7)
                    .opacity(landed ? 1 : 0)
                    .shadow(color: .black.opacity(0.3), radius: 24, y: 14)
                    .overlay { SparkleBurst(trigger: cheers, radius: CGSize(width: 190, height: 170), count: 18) }
                Spacer(minLength: 16)
                Text("\(badge.title)\(Text(".").foregroundStyle(StickerTone.yellow.fill))")
                    .font(.hero(50, weight: .heavy))
                    .tracking(-2.2)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(badge.story)
                    .font(.allo(size: 17, weight: .bold, relativeTo: .body))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 28)
                HStack(spacing: 5) {
                    ForEach(0..<total, id: \.self) { index in
                        Capsule()
                            .fill(index < collected ? StickerTone.yellow.fill : Color.white.opacity(0.2))
                            .frame(width: index < collected ? 22 : 8, height: 8)
                    }
                }
                .padding(.top, 22)
                .accessibilityElement()
                .accessibilityLabel(String(localized: "\(collected) of \(total) collected"))
                Spacer(minLength: 20)
                Button(action: onDone) { Text("Add to my sticker book") }
                    .buttonStyle(.big(.yellow))
                Button { sharing = true } label: {
                    Text("Share sticker ↗")
                        .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .frame(minHeight: 44)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $sharing) {
            BadgeShareSheet(badge: badge, badges: allBadges, streak: routines.map(\.streak).max() ?? 0)
                .presentationDetents([.large])
        }
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.55)) {
                landed = true
            }
            try? await Task.sleep(for: .milliseconds(180))
            cheers += 1
            Haptics.celebrate()
            Sounds.play(.pop)
        }
    }
}

extension BadgeUnlockView {
    /// Every badge, for the sticker-book share image.
    fileprivate var allBadges: [Badge] {
        let index = ActivityIndex(tasks: tasks, routines: routines, days: 7)
        return Badge.all(index: index, routines: routines, goals: goals, weekKept: Badge.weekKept(routines))
    }
}

/// Soft sunburst rays behind the sticker, slowly turning.
private struct SunRays: View {
    var spinning: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !spinning)) { timeline in
            let angle: Double = spinning ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 120) * 3 : 0
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
                let reach: CGFloat = max(size.width, size.height) * 1.2
                for index in 0..<20 {
                    let start = Angle.degrees(Double(index) * 18 + angle).radians
                    let end = start + Angle.degrees(9).radians
                    var ray = Path()
                    ray.move(to: center)
                    ray.addLine(to: CGPoint(x: center.x + reach * cos(start), y: center.y + reach * sin(start)))
                    ray.addLine(to: CGPoint(x: center.x + reach * cos(end), y: center.y + reach * sin(end)))
                    ray.closeSubpath()
                    context.fill(ray, with: .color(Color.white.opacity(0.05)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Noticing

/// On Today, until you've looked: "New sticker! On fire 🔥".
struct NewStickerBanner: View {
    let badge: Badge
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Image(badge.sticker)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(-10))
                    .shadow(color: Color.night.opacity(0.18), radius: 5, y: 3)
                VStack(alignment: .leading, spacing: 2) {
                    MonoCaps(String(localized: "New sticker!"), color: StickerTone.yellow.deep)
                    Text(badge.title)
                        .font(.allo(size: 19, weight: .heavy, relativeTo: .headline))
                        .tracking(-0.3)
                        .foregroundStyle(StickerTone.yellow.deep)
                }
                Spacer(minLength: 4)
                Text("Open")
                    .font(.allo(size: 14, weight: .heavy, relativeTo: .footnote))
                    .foregroundStyle(StickerTone.yellow.deep)
                    .padding(.horizontal, 13)
                    .frame(height: 34)
                    .background(Color.white.opacity(0.55), in: .capsule)
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .background(StickerTone.yellow.fill.shadow(.drop(color: StickerTone.yellow.shadow, radius: 14, y: 8)),
                        in: .rect(cornerRadius: Radius.tile, style: .continuous))
        }
        .buttonStyle(.pressable)
    }
}

/// Watches your progress from anywhere in the app. The moment a badge is
/// earned, it plays the unlock and marks it new for the Insights tab.
struct BadgeWatcher: ViewModifier {
    @Environment(AppRouter.self) private var router
    @Query private var tasks: [TaskItem]
    @Query private var routines: [Routine]
    @Query private var goals: [Goal]

    /// Changes whenever anything a badge counts changes.
    private var signature: String {
        let done = tasks.filter(\.isDone).count
        let checks = routines.reduce(0) { $0 + $1.completions.count }
        let goalsDone = goals.filter { $0.progress >= 1 }.count
        return "\(done)-\(checks)-\(goalsDone)"
    }

    func body(content: Content) -> some View {
        content
            .task(id: signature) {
                try? await Task.sleep(for: .milliseconds(900))
                guard !Task.isCancelled else { return }
                check()
            }
            .onAppear { router.newBadges = BadgeBook.unseen.count }
    }

    private func check() {
        let index = ActivityIndex(tasks: tasks, routines: routines, days: 7)
        let badges = Badge.all(index: index, routines: routines, goals: goals, weekKept: Badge.weekKept(routines))
        let fresh = BadgeBook.sync(Set(badges.filter(\.earned).map(\.id)))
        router.newBadges = BadgeBook.unseen.count
        guard let first = badges.first(where: { fresh.contains($0.id) }) else { return }
        router.badgeCollection = (badges.filter(\.earned).count, badges.count)
        router.unlockedBadge = first
    }
}
