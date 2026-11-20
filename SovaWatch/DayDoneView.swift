import SwiftUI

/// Everything for today is done: the owl smiles and the Watch says so.
struct DayDoneView: View {
    let day: WatchDay
    let onClose: () -> Void
    @State private var hop = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                WatchOwl(happy: true)
                    .frame(width: 84, height: 84)
                    .scaleEffect(hop ? 1.06 : 0.9)
                    .offset(y: hop ? -4 : 4)
                Text("Day done!")
                    .font(.sova(26, .heavy, relativeTo: .title2))
                    .foregroundStyle(WatchPalette.yellow)
                Text(summary)
                    .font(.sova(13, .bold, relativeTo: .footnote))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                Button(action: onClose) {
                    Text("Nice!")
                        .font(.sova(16, .heavy, relativeTo: .headline))
                        .foregroundStyle(WatchTone.yellow.deep)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchPalette.yellow)
                .padding(.top, 4)
            }
            .padding(.horizontal, 6)
        }
        .background(WatchPalette.indigo.gradient)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5).repeatCount(3, autoreverses: true)) { hop = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Day done"))
    }

    private var summary: String {
        var parts: [String] = []
        let tasks = day.tasks.filter(\.done).count
        let rituals = day.rituals.filter(\.done).count
        if tasks > 0 { parts.append(String(localized: "\(tasks) tasks")) }
        if rituals > 0 { parts.append(String(localized: "\(rituals) rituals")) }
        if day.streak > 1 { parts.append(String(localized: "\(day.streak)-day streak")) }
        return parts.joined(separator: " · ")
    }
}
