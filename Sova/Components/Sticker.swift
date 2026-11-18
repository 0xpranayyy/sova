import SwiftUI

/// A tilted label sticker with an optional small caption above.
struct Sticker: View {
    let text: String
    var tone: StickerTone
    var caption: String? = nil
    var size: CGFloat = 18
    var tilt: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let caption {
                Text(caption)
                    .font(.allo(size: 10, weight: .bold, relativeTo: .caption2))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .opacity(0.8)
            }
            Text(text)
                .font(.allo(size: size, weight: .heavy, relativeTo: .headline))
                .tracking(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(tone.deep)
        .padding(.horizontal, size * 0.75)
        .padding(.vertical, size * 0.45)
        .background(tone.fill, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(tone.border, lineWidth: 2.5))
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tone.border.opacity(0.14)).offset(x: 3, y: 4))
        .rotationEffect(.degrees(tilt))
    }
}

/// A small icon on its tone, used for rituals and goals.
struct StickerIcon: View {
    let symbol: String
    var tone: StickerTone
    var size: CGFloat = 36
    var tilt: Double = 0

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(tone.deep)
            .frame(width: size, height: size)
            .background(tone.fill, in: .rect(cornerRadius: size * 0.33, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.33, style: .continuous).strokeBorder(tone.border, lineWidth: 2))
            .rotationEffect(.degrees(tilt))
            .accessibilityHidden(true)
    }
}

/// A starburst badge, for streaks.
struct Starburst: View {
    let value: String
    var caption: String
    var tone: StickerTone = .mint
    var size: CGFloat = 100
    var tilt: Double = 0

    var body: some View {
        ZStack {
            StarburstShape(points: 16)
                .fill(tone.fill)
            StarburstShape(points: 16)
                .stroke(tone.border, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            VStack(spacing: 0) {
                Text(value)
                    .font(.allo(size: size * 0.3, weight: .heavy, relativeTo: .title))
                    .tracking(-1)
                Text(caption)
                    .font(.allo(size: size * 0.095, weight: .bold, relativeTo: .caption2))
                    .tracking(1)
                    .textCase(.uppercase)
            }
            .foregroundStyle(tone.deep)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(tilt))
        .accessibilityElement(children: .combine)
    }
}

struct StarburstShape: Shape {
    var points: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.86
        var path = Path()
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = Double(i) * .pi / Double(points)
            let p = CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

/// A tiny tonal pill, e.g. a streak count on a row.
struct StickerChip: View {
    let text: String
    var tone: StickerTone

    var body: some View {
        Text(text)
            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
            .foregroundStyle(tone.deep)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tone.fill, in: .rect(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(tone.border, lineWidth: 1.5))
            .rotationEffect(.degrees(-4))
    }
}

/// A tilted pill sticker, as floats around the owl.
struct TiltPill: View {
    let text: String
    let tone: StickerTone
    var tilt: Double = 0
    var size: CGFloat = 15

    var body: some View {
        Text(text)
            .font(.allo(size: size, weight: .heavy, relativeTo: .subheadline))
            .tracking(-0.3)
            .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
            .padding(.horizontal, size * 0.95)
            .padding(.vertical, size * 0.6)
            .background(tone.fill, in: .capsule)
            .rotationEffect(.degrees(tilt))
            .fixedSize()
    }
}

/// A sparkle at a spot, in a color.
struct SparkleDot: View {
    let color: Color
    var size: CGFloat = 24
    @State private var twinkle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Sparkle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(twinkle ? 1 : 0.7)
            .onAppear {
                guard !reduceMotion else { twinkle = true; return }
                withAnimation(.easeInOut(duration: Double.random(in: 1.2...2.0)).repeatForever(autoreverses: true)) {
                    twinkle = true
                }
            }
    }
}


/// Sparkles that burst outward from the center with spring physics, spin a
/// little, then fade. Fires each time `trigger` changes.
struct SparkleBurst: View {
    var trigger: Int
    var colors: [Color] = [StickerTone.yellow.fill, StickerTone.mint.fill, StickerTone.pink.fill,
                           StickerTone.cyan.fill, StickerTone.lilac.fill, StickerTone.orange.fill]
    var radius: CGSize = CGSize(width: 120, height: 95)
    var count = 12

    @State private var spread: CGFloat = 0
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi + (i.isMultiple(of: 2) ? 0.2 : -0.1)
                let reach = i.isMultiple(of: 3) ? 1.0 : (i.isMultiple(of: 2) ? 0.8 : 0.65)
                Sparkle()
                    .fill(colors[i % colors.count])
                    .frame(width: 12 + CGFloat(i % 3) * 5, height: 12 + CGFloat(i % 3) * 5)
                    .rotationEffect(.degrees(Double(spread) * Double(60 + i * 9)))
                    .scaleEffect(0.4 + spread * 0.6)
                    .offset(x: cos(angle) * radius.width * reach * spread,
                            y: sin(angle) * radius.height * reach * spread)
            }
        }
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            guard !reduceMotion else { return }
            spread = 0
            visible = true
            withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) { spread = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.65)) { visible = false }
        }
    }
}
