import SwiftUI

struct SectionHeader: View {
    let title: String
    var symbol: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.tint)
            }
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

struct StatPill: View {
    let symbol: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(tint.gradient, in: .circle)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct EmptyCard: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.tint)
                .symbolEffect(.breathe)
                .padding(.bottom, 4)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.glassProminent)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .card(cornerRadius: 28, padding: 22)
    }
}

/// Small rounded label used for metadata (due date, goal, etc).
struct MetaChip: View {
    let text: String
    var symbol: String? = nil
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol) }
            Text(text).lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: .capsule)
    }
}

struct ThemeMenu: View {
    @AppStorage("theme") private var themeRaw = AuroraTheme.aurora.rawValue

    var body: some View {
        Menu {
            Picker("Theme", selection: $themeRaw.animation(.easeInOut(duration: 0.8))) {
                ForEach(AuroraTheme.allCases) { theme in
                    Label(theme.name, systemImage: theme.symbol).tag(theme.rawValue)
                }
            }
        } label: {
            Label("Theme", systemImage: "paintpalette")
        }
    }
}
