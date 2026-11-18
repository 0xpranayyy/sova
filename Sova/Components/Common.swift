import SwiftUI

/// A symbol on a soft square of its accent.
struct IconTile: View {
    let symbol: String
    let accent: Accent
    var size: CGFloat = 40
    var filled = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(filled ? Color.white : accent.color)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(filled ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(accent.soft))
            }
            .accessibilityHidden(true)
    }
}

/// Metadata as plain text, joined with a middle dot.
struct MetaLine: View {
    struct Part {
        var text: String
        var color: Color = .inkSecondary
    }

    var parts: [Part]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text("·").foregroundStyle(Color.inkTertiary)
                }
                Text(part.text).foregroundStyle(part.color)
            }
        }
        .font(.footnote)
        .lineLimit(1)
    }
}

/// A list of rows on one surface, with hairlines between them.
struct GroupedList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    var inset: CGFloat = 60
    @ViewBuilder var row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Color.hairline)
                        .frame(height: 1)
                        .padding(.leading, inset)
                }
            }
        }
        .surface(cornerRadius: 24, padding: 0)
    }
}

struct EmptyState: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            OwlMark(size: 56)
                .padding(.bottom, 4)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.inkCompact)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .surface(cornerRadius: 28, padding: 0)
    }
}

/// The five themes as swatches. Used in onboarding and Settings.
struct ThemeSwatches: View {
    @Binding var themeRaw: String

    private var selected: SovaTheme { SovaTheme(rawValue: themeRaw) ?? .ember }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SovaTheme.allCases) { option in
                Button {
                    withAnimation(.smooth(duration: 0.6)) { themeRaw = option.rawValue }
                } label: {
                    VStack(spacing: 10) {
                        Circle()
                            .fill(option.swatch)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.ink, lineWidth: 2)
                                    .padding(-6)
                                    .opacity(option == selected ? 1 : 0)
                                    .scaleEffect(option == selected ? 1 : 0.85)
                            }
                        Text(option.name)
                            .font(.caption.weight(option == selected ? .semibold : .regular))
                            .foregroundStyle(option == selected ? Color.ink : Color.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
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
