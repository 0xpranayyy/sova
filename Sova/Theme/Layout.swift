import SwiftUI

// iPad and wide windows: Sova reads like a page, not a stretched phone.
// Every screen keeps its cards in one comfortable column, centered, while
// the canvas, glows and horizontal strips still run edge to edge.

enum Layout {
    /// The widest a column of cards gets.
    static let readable: CGFloat = 700

    /// The extra side margin that centers a readable column in `width`.
    static func margin(for width: CGFloat) -> CGFloat {
        max(0, ((width - readable - 32) / 2).rounded())
    }
}

extension EnvironmentValues {
    /// Extra side margin for List rows on wide screens (0 on iPhone).
    @Entry var readableMargin: CGFloat = 0
}

/// Measures the view's width and tells its List rows how far to step in.
private struct ReadableMargins: ViewModifier {
    @State private var margin: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .environment(\.readableMargin, margin)
            .onGeometryChange(for: CGFloat.self) { proxy in
                Layout.margin(for: proxy.size.width)
            } action: { newMargin in
                if newMargin != margin { margin = newMargin }
            }
    }
}

/// Side padding that grows by the readable margin.
private struct ReadablePadding: ViewModifier {
    let base: CGFloat
    @Environment(\.readableMargin) private var margin

    func body(content: Content) -> some View {
        content.padding(.horizontal, base + margin)
    }
}

/// List row insets that grow by the readable margin.
private struct ReadableRowInsets: ViewModifier {
    let top: CGFloat
    let bottom: CGFloat
    let side: CGFloat
    @Environment(\.readableMargin) private var margin

    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: top, leading: side + margin, bottom: bottom, trailing: side + margin))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    /// Put on a List: its rows center themselves in a readable column.
    func readableMargins() -> some View { modifier(ReadableMargins()) }

    /// Horizontal padding of `base`, plus the readable margin inside a List.
    func readablePadding(_ base: CGFloat = 16) -> some View { modifier(ReadablePadding(base: base)) }

    /// A chrome-free List row with standard side margins, centered on iPad.
    func readableRow(top: CGFloat = 0, bottom: CGFloat = 0, side: CGFloat = 16) -> some View {
        modifier(ReadableRowInsets(top: top, bottom: bottom, side: side))
    }

    /// Put on the content of a ScrollView: one centered, readable column.
    func readableColumn(_ maxWidth: CGFloat = Layout.readable) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}
