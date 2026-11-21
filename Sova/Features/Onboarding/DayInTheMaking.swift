import SwiftUI

/// "Build your first day": while you answer the questions, your real Today
/// assembles itself at the top of the screen. Your name becomes the
/// greeting, each ritual you pick lands as a sticker, your goal becomes the
/// pink block and reminders show up as a bell. It's built from the same
/// pieces as Today (`DayHeaderCard`, sticker tones), so "Open Sova" lands on
/// exactly this.
struct DayInTheMaking: View {
    var name: String
    var rituals: [RitualOption]
    var goalTitle: String
    var remindersOn: Bool
    var reminderTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .heavy))
                MonoCaps(String(localized: "Your Today, so far"), color: Color.inkSecondary, size: 10)
            }
            .padding(.leading, 4)

            DayHeaderCard(greeting: TodayView.greeting(for: name), done: 0, total: rituals.count, streak: 0)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    if !goalTitle.isEmpty {
                        sticker(symbol: "flag.fill", title: goalTitle, tone: .pink)
                            .transition(.landing)
                    }
                    ForEach(rituals) { ritual in
                        sticker(symbol: ritual.symbol, title: ritual.title, tone: StickerTone(ritual.accent))
                            .transition(.landing)
                    }
                    if remindersOn {
                        sticker(symbol: "bell.fill", title: reminderTime.formatted(date: .omitted, time: .shortened), tone: .cyan)
                            .transition(.landing)
                    }
                    if rituals.isEmpty { slot(String(localized: "Rituals")) }
                    if goalTitle.isEmpty { slot(String(localized: "A goal")) }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .animation(.open(0.4), value: rituals.map(\.id))
        .animation(.open(0.4), value: goalTitle.isEmpty)
        .animation(.open(0.4), value: remindersOn)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Your Today so far"))
    }

    /// A placed choice: a small sticker in its tone, like the chips in Today.
    private func sticker(symbol: String, title: String, tone: StickerTone) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                .lineLimit(1)
        }
        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(tone.fill, in: .capsule)
        .shadow(color: tone.shadow, radius: 6, y: 3)
    }

    /// A spot still waiting for an answer.
    private func slot(_ title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .heavy))
            Text(title)
                .font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
        }
        .foregroundStyle(Color.inkTertiary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .overlay(Capsule().strokeBorder(Color.ink.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])))
        .transition(.opacity)
    }
}

private extension AnyTransition {
    /// A choice arriving from the question below: it rises into place, from
    /// 0.6 scale, never from nothing.
    static var landing: AnyTransition {
        .asymmetric(insertion: .offset(y: 46).combined(with: .scale(scale: 0.6)).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity))
    }
}
