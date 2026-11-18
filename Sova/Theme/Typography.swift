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
            Text(title + ".")
                .font(.hero(58, weight: .heavy))
                .tracking(-2.6)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
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
                .background(Color.surface, in: .circle)
                .overlay(Circle().strokeBorder(Color.hairline, lineWidth: 1.5))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }
}
