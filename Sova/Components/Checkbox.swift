import SwiftUI

/// The completion mark. Square for tasks, round for rituals. Done fills
/// solid and the check draws itself in.
struct Checkbox: View {
    var isOn: Bool
    var color: Color = SovaTheme.current.accent.color
    var round = false
    var size: CGFloat = 22
    var emphasized = false

    var body: some View {
        let radius = round ? size / 2 : size * 0.32
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            shape
                .fill(Color.white)
            shape
                .strokeBorder(emphasized ? color : Color.black.opacity(0.25), lineWidth: 1.5)
                .opacity(isOn ? 0 : 1)
            shape
                .fill(color)
                .scaleEffect(isOn ? 1 : 0.5)
                .opacity(isOn ? 1 : 0)
            CheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(Color.inkInverse, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
                .padding(size * 0.28)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isOn)
    }
}

struct CheckmarkShape: Shape {
    func path(in r: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.55))
        path.addLine(to: CGPoint(x: r.minX + r.width * 0.36, y: r.maxY - r.height * 0.06))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.08))
        return path
    }
}

/// A checkbox wrapped in a 44pt button with haptics.
struct CheckButton: View {
    var isOn: Bool
    var color: Color = SovaTheme.current.accent.color
    var round = false
    var size: CGFloat = 22
    var emphasized = false
    var label: String = ""
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Checkbox(isOn: isOn, color: color, round: round, size: size, emphasized: emphasized)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.pressable)
        .sensoryFeedback(trigger: isOn) { _, newValue in
            newValue ? .success : .impact(weight: .light)
        }
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "Done" : "Not done")
    }
}
