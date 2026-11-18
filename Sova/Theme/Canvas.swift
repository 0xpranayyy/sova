import SwiftUI

/// Warm paper.
struct CanvasBackground: View {
    var glow: Double = 0

    var body: some View {
        Color.canvas
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// The signature moment: sunlight falling through leaves, ending in a
/// wide soft arc into the paper below.
struct SunHero<Content: View>: View {
    var height: CGFloat
    /// How far the arc rises from the bottom edge.
    var arcDepth: CGFloat = 64
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .top) {
            Image("Sunlight")
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            content
        }
        .frame(height: height)
        .clipShape(ArcBottom(depth: arcDepth))
    }
}

/// A rectangle whose bottom edge is a gentle upward arc.
struct ArcBottom: Shape {
    var depth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control: CGPoint(x: rect.midX, y: rect.maxY - depth * 2))
        path.closeSubpath()
        return path
    }
}

/// The floating pill at the top of each tab: the owl, the name, and one
/// action on the right.
struct SovaNavPill<Trailing: View>: View {
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 7) {
            OwlMark(size: 22, blinks: true)
            Text("Sova")
                .font(.allo(size: 18, weight: .medium, relativeTo: .headline))
                .tracking(-0.4)
                .foregroundStyle(Color.ink)
            Spacer()
            trailing
                .foregroundStyle(Color.ink)
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(height: 48)
        .background(Color(hex: 0xF8F8F8).opacity(0.94), in: .capsule)
        .shadow(color: .black.opacity(0.04), radius: 0, y: 1)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        .padding(.horizontal, 16)
    }
}
