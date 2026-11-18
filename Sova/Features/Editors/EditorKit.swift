import SwiftUI

// The pieces the ritual and goal editors are built from: white cards with a
// caps label, sticker-colored choices, and a big button docked at the bottom.
// Everything picks up the color being chosen, so the screen previews itself.

/// A white card with a caps label above it.
struct EditorCard<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoCaps(title)
                .padding(.horizontal, 6)
            content
                .surface(cornerRadius: 26, padding: 14)
            if let footer {
                Text(footer)
                    .font(.allo(.footnote, .semibold))
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.horizontal, 6)
                    .contentTransition(.opacity)
            }
        }
    }
}

/// The sticker colors, as the accents they're stored as.
enum ToneChoice {
    static let accents: [Accent] = [.marigold, .ember, .rose, .plum, .tide, .lagoon, .lime, .ink]
}

/// Round sticker swatches, the chosen one ringed and lifted.
struct TonePicker: View {
    @Binding var selection: Accent

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ToneChoice.accents) { accent in
                let tone = StickerTone(accent)
                let on = StickerTone(selection) == tone
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { selection = accent }
                } label: {
                    Circle()
                        .fill(tone.fill)
                        .frame(width: 30, height: 30)
                        .overlay {
                            if on {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Color.ink, lineWidth: 2.5)
                                .padding(-5)
                                .opacity(on ? 1 : 0)
                        }
                        .scaleEffect(on ? 1.08 : 1)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(.rect)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(accent.name)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }
}

/// Morning, afternoon, evening or anytime, as four sky-colored tiles.
struct PeriodTiles: View {
    @Binding var selection: DayPeriod
    let tone: StickerTone

    private func sky(_ period: DayPeriod) -> StickerTone {
        switch period {
        case .morning: .orange
        case .afternoon: .yellow
        case .evening: .lilac
        case .anytime: .mint
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DayPeriod.allCases) { period in
                let on = selection == period
                let sky = sky(period)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = period }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: period.symbol)
                            .font(.system(size: 19, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.bounce, value: on)
                        Text(period.name)
                            .font(.allo(size: 12, weight: .heavy, relativeTo: .caption))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(on ? sky.deep : Color.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(on ? sky.fill : Color.well, in: .rect(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(sky.deep.opacity(on ? 0.9 : 0), lineWidth: 2)
                    }
                    .rotationEffect(.degrees(on ? -2 : 0))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(period.name)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }
}

/// Seven day bubbles in the chosen color, with quick presets.
struct ToneWeekdays: View {
    @Binding var selection: [Int]
    let tone: StickerTone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Weekdays.ordered, id: \.self) { day in
                    let on = selection.contains(day)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if on { selection.removeAll { $0 == day } } else { selection.append(day) }
                        }
                    } label: {
                        Text(Weekdays.letter(day))
                            .font(.allo(size: 15, weight: .heavy, relativeTo: .subheadline))
                            .foregroundStyle(on ? (tone == .indigo ? Color.white : tone.deep) : Color.inkSecondary)
                            .frame(width: 40, height: 40)
                            .background(on ? tone.fill : Color.well, in: .circle)
                            .scaleEffect(on ? 1 : 0.92)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                preset(String(localized: "Every day"), days: Array(1...7))
                preset(String(localized: "Weekdays"), days: [2, 3, 4, 5, 6])
                preset(String(localized: "Weekends"), days: [1, 7])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }

    private func preset(_ title: String, days: [Int]) -> some View {
        let active = Set(selection) == Set(days)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selection = days }
        } label: {
            Text(title)
                .font(.allo(size: 13, weight: .heavy, relativeTo: .caption))
                .foregroundStyle(active ? Color.inkInverse : Color.ink)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(active ? Color.ink : Color.well, in: .capsule)
        }
        .buttonStyle(.pressable)
    }
}

/// A grid of icons; the chosen one sits in the chosen color.
struct ToneSymbolGrid: View {
    @Binding var selection: String
    let tone: StickerTone
    let symbols: [String]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(symbols, id: \.self) { symbol in
                let on = selection == symbol
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = symbol }
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(on ? (tone == .indigo ? Color.white : tone.deep) : Color.ink.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(on ? tone.fill : Color.well, in: .rect(cornerRadius: 14, style: .continuous))
                        .rotationEffect(.degrees(on ? -4 : 0))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }
}

/// A row of tappable ideas for an empty name.
struct SuggestionChips: View {
    struct Idea: Identifiable {
        let title: String
        let symbol: String
        let accent: Accent
        var id: String { title }
    }

    let ideas: [Idea]
    let onPick: (Idea) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ideas) { idea in
                    let tone = StickerTone(idea.accent)
                    Button { onPick(idea) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: idea.symbol).font(.system(size: 13, weight: .bold))
                            Text(idea.title).font(.allo(size: 14, weight: .heavy, relativeTo: .subheadline))
                        }
                        .foregroundStyle(tone == .indigo ? Color.white : tone.deep)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(tone.fill, in: .capsule)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16)
    }
}

/// The main button, docked above the keyboard and the home indicator.
struct EditorSaveBar: View {
    let title: String
    let tone: StickerTone
    let enabled: Bool
    var hint: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if let hint, !enabled {
                Text(hint)
                    .font(.allo(.footnote, .bold))
                    .foregroundStyle(Color.inkSecondary)
                    .transition(.opacity)
            }
            Button(action: action) {
                HStack(spacing: 8) {
                    Text(title)
                    Image(systemName: "arrow.right").font(.system(size: 16, weight: .heavy))
                }
            }
            .buttonStyle(.big(tone))
            .disabled(!enabled)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background {
            LinearGradient(colors: [Color.canvas.opacity(0), Color.canvas, Color.canvas],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .animation(.smooth(duration: 0.25), value: enabled)
    }
}

/// The close button for an editor's toolbar.
struct EditorCloseButton: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close, action: action)
        }
    }
}
