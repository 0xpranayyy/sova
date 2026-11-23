import SwiftUI

// The onboarding's shared pieces: a headline with a yellow highlighter
// stroke behind one phrase, the big underline field, and the top bar's
// indigo track.

/// Marks a run of text for the highlighter.
struct MarkerAttribute: TextAttribute {}

/// Draws a slightly tilted yellow marker stroke behind marked runs, then
/// the text on top, like a highlighter pen on paper.
struct MarkerRenderer: TextRenderer {
    var color: Color

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line where run[MarkerAttribute.self] != nil {
                let bounds: CGRect = run.typographicBounds.rect
                let height: CGFloat = bounds.height * 0.4
                let rect = CGRect(x: bounds.minX - 3, y: bounds.maxY - height - bounds.height * 0.14,
                                  width: bounds.width + 6, height: height)
                var marker = context
                marker.translateBy(x: rect.midX, y: rect.midY)
                marker.rotate(by: .degrees(-1.5))
                marker.translateBy(x: -rect.midX, y: -rect.midY)
                marker.fill(Path(roundedRect: rect, cornerRadius: height * 0.3), with: .color(color))
            }
        }
        for line in layout { context.draw(line) }
    }
}

extension Text {
    /// Builds text from a string where `*this part*` gets the highlighter.
    static func marked(_ source: String) -> Text {
        let parts: [Substring] = source.split(separator: "*", omittingEmptySubsequences: false)
        var result = Text(verbatim: "")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            let piece = Text(verbatim: String(part))
            let styled: Text = index.isMultiple(of: 2) ? piece : piece.customAttribute(MarkerAttribute())
            result = Text("\(result)\(styled)")
        }
        return result
    }
}

/// A big field that's just type on a line: what you write is the hero.
struct BigField: View {
    let placeholder: String
    @Binding var text: String
    var size: CGFloat = 44
    var contentType: UITextContentType? = nil
    var autofocus = true
    var onSubmit: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.inkTertiary), axis: .vertical)
                .font(.hero(size, weight: .heavy))
                .tracking(-size * 0.04)
                .foregroundStyle(Color.ink)
                .tint(Color(hex: 0x6E4BFF))
                .lineLimit(1...2)
                .textContentType(contentType)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.continue)
                .focused($focused)
                .onChange(of: text) { _, newValue in
                    guard newValue.contains("\n") else { return }
                    text = newValue.replacingOccurrences(of: "\n", with: "")
                    onSubmit()
                }
            Capsule()
                .fill(focused || !text.isEmpty ? StickerTone.indigo.fill : Color.hairline)
                .frame(height: 3)
        }
        .animation(.smooth(duration: 0.25), value: focused)
        .task {
            guard autofocus else { return }
            try? await Task.sleep(for: .milliseconds(550))
            focused = true
        }
    }
}

/// The onboarding progress: a slim indigo track.
struct StepTrack: View {
    var value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.ink.opacity(0.07))
                Capsule().fill(StickerTone.indigo.fill)
                    .frame(width: max(12, geo.size.width * value))
            }
        }
        .frame(height: 8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
    }
}
