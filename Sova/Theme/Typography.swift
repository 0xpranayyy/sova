import SwiftUI

// SF Pro throughout. Headlines are bold and tight, the way Apple's own
// apps set them.

extension Font {
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .default, weight: weight)
    }
}

/// A section heading: bold title with an optional count on the right.
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil

    init(_ title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.inkSecondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}
