import SwiftUI

/// A small uppercase label, Allo heavy with open tracking ("UP NEXT").
struct MonoCaps: View {
    let text: String
    var color: Color = .inkSecondary
    var size: CGFloat = 11

    init(_ text: String, color: Color = .inkSecondary, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = min(max(size, 10), 12)
    }

    var body: some View {
        Text(text)
            .font(.allo(size: size, weight: .heavy, relativeTo: .caption))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

/// A section heading: a small uppercase label.
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil
    var color: Color = .inkSecondary

    init(_ title: String, trailing: String? = nil, color: Color = .inkSecondary) {
        self.title = title
        self.trailing = trailing
        self.color = color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            MonoCaps(title, color: color)
            Spacer()
            if let trailing {
                MonoCaps(trailing, color: .inkTertiary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A screen header: a small label and action on top, then a huge heavy
/// title that ends with a period, the way Allo sets its name.
struct ScreenTitle<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let subtitle { MonoCaps(subtitle) }
                Spacer()
                trailing
            }
            .frame(minHeight: 44)
            (Text(title).foregroundStyle(Color.ink)
                + Text(".").foregroundStyle(SovaTheme.current.accent.color))
                .font(.hero(58, weight: .heavy))
                .tracking(-2.6)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityLabel(title)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 4)
    }
}

/// A round white button for a screen's top-right action.
struct CircleAction: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(Color.surface.shadow(.drop(color: Color.night.opacity(0.08), radius: 8, y: 4)), in: .circle)
                .overlay(Circle().strokeBorder(Color.hairline, lineWidth: 1.5))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }
}

/// A section heading with a tilted sticker icon, a heavy title and a count
/// badge, as used on Today and Tasks.
struct StickerHeader: View {
    let title: String
    let symbol: String
    let tone: StickerTone
    var count: Int? = nil
    var titleColor: Color = .ink

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                .frame(width: 28, height: 28)
                .background(tone.fill, in: .rect(cornerRadius: 9, style: .continuous))
                .rotationEffect(.degrees(-6))
            Text(title)
                .font(.allo(size: 21, weight: .heavy, relativeTo: .title3))
                .tracking(-0.6)
                .foregroundStyle(titleColor)
            Spacer(minLength: 6)
            if let count {
                Text("\(count)")
                    .font(.allo(size: 13, weight: .heavy).monospacedDigit())
                    .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                    .padding(.horizontal, 9)
                    .frame(minWidth: 26, minHeight: 24)
                    .background(tone.fill.opacity(tone == .indigo ? 1 : 0.55), in: .capsule)
                    .contentTransition(.numericText(value: Double(count)))
            }
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
