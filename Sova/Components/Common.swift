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
            .background(filled ? accent.color : accent.soft,
                        in: .rect(cornerRadius: size * 0.3, style: .continuous))
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
        .surface(cornerRadius: 22, padding: 0)
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
                .font(.display(.title2))
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
        .surface(cornerRadius: 26, padding: 0)
    }
}

/// Theme and app-level options, in the toolbar.
struct SettingsMenu: View {
    @AppStorage("theme") private var themeRaw = SovaTheme.ember.rawValue
    @AppStorage("hasOnboarded") private var hasOnboarded = true

    var body: some View {
        Menu {
            Picker("Theme", selection: $themeRaw.animation(.smooth(duration: 0.6))) {
                ForEach(SovaTheme.allCases) { theme in
                    Text(theme.name).tag(theme.rawValue)
                }
            }
            Divider()
            Button("Replay Welcome", systemImage: "hand.wave") {
                withAnimation(.smooth(duration: 0.6)) { hasOnboarded = false }
            }
        } label: {
            Label("Settings", systemImage: "circle.lefthalf.filled")
        }
    }
}
