import SwiftUI

/// An SF Symbol on a small rounded square. Neutral by default; lights up
/// with the accent when `active`.
struct IconTile: View {
    let symbol: String
    var accent: Accent = .graphite
    var size: CGFloat = 38
    var filled = false
    var active = false

    var body: some View {
        let tint = SovaTheme.current.accent.color
        Image(systemName: symbol)
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(filled ? Color.inkInverse : (active ? tint : Color.inkSecondary))
            .frame(width: size, height: size)
            .background(filled ? tint : (active ? tint.opacity(0.12) : Color.surfaceRaised),
                        in: .rect(cornerRadius: size * 0.29, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Metadata as plain text, joined with a middle dot.
struct MetaLine: View {
    struct Part {
        var text: String
        var color: Color = .inkTertiary
    }

    var parts: [Part]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 { Text("·").foregroundStyle(Color.inkTertiary) }
                Text(part.text).foregroundStyle(part.color)
            }
        }
        .font(.footnote)
        .lineLimit(1)
    }
}

/// Rows on one card, with hairlines between them.
struct GroupedList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    var inset: CGFloat = 60
    @ViewBuilder var row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.leading, inset)
                }
            }
        }
        .surface(cornerRadius: 20, padding: 0)
    }
}

struct EmptyState: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            OwlMark(size: 44, blinks: true)
                .padding(.bottom, 8)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.inkCompact)
                    .padding(.top, 10)
            }
        }
        .surface(cornerRadius: 24, padding: 22)
    }
}

/// The accent choices, as swatches.
struct ThemeSwatches: View {
    @Binding var themeRaw: String

    private var selected: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .lime }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SovaTheme.allCases) { option in
                Button {
                    withAnimation(.smooth(duration: 0.5)) { themeRaw = option.rawValue }
                } label: {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(option.accent.color)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.ink, lineWidth: 1.5)
                                    .padding(-6)
                                    .opacity(option == selected ? 1 : 0)
                                    .scaleEffect(option == selected ? 1 : 0.85)
                            }
                        Text(option.name)
                            .font(.mono(10.5))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(option == selected ? Color.ink : Color.inkTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 76)
                    .contentShape(.rect)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(option == selected ? .isSelected : [])
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: themeRaw)
        .sensoryFeedback(.selection, trigger: themeRaw)
    }
}
