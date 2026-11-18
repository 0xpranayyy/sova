import SwiftUI

struct AccentPicker: View {
    @Binding var selection: Accent

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 9), spacing: 4) {
            ForEach(Accent.allCases) { accent in
                Button {
                    withAnimation(.snappy) { selection = accent }
                } label: {
                    Circle()
                        .fill(accent.gradient)
                        .frame(width: 26, height: 26)
                        .overlay {
                            Circle()
                                .strokeBorder(accent.color, lineWidth: 2.5)
                                .padding(-5)
                                .opacity(selection == accent ? 1 : 0)
                        }
                        .scaleEffect(selection == accent ? 0.85 : 1)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.name)
                .accessibilityAddTraits(selection == accent ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

struct SymbolPicker: View {
    @Binding var selection: String
    var accent: Accent

    static let symbols = [
        "sparkles", "sun.max.fill", "leaf.fill", "drop.fill", "figure.walk", "figure.run",
        "figure.flexibility", "dumbbell.fill", "bicycle", "bed.double.fill", "moon.stars.fill", "heart.fill",
        "brain.head.profile", "book.closed.fill", "books.vertical.fill", "pencil.and.scribble", "music.note", "paintbrush.fill",
        "fork.knife", "cup.and.saucer.fill", "pills.fill", "laptopcomputer", "checklist", "phone.fill",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(Self.symbols, id: \.self) { symbol in
                let selected = selection == symbol
                Button {
                    withAnimation(.snappy) { selection = symbol }
                } label: {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .frame(width: 44, height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(selected ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

struct EmojiPicker: View {
    @Binding var selection: String
    var accent: Accent

    static let emojis = [
        "🎯", "🚀", "🏃", "📚", "💪", "🧘", "🎨", "🎸", "✍️", "💼", "💰", "🏡",
        "🌱", "🍎", "✈️", "🧠", "❤️", "🎓", "📷", "🏔️", "🌊", "⭐️", "🛠️", "🗣️",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(Self.emojis, id: \.self) { emoji in
                Button {
                    withAnimation(.snappy) { selection = emoji }
                } label: {
                    Text(emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(selection == emoji ? accent.color.opacity(0.28) : Color.primary.opacity(0.05))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(accent.color, lineWidth: 2)
                                .opacity(selection == emoji ? 1 : 0)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

struct WeekdayPicker: View {
    @Binding var selection: [Int]
    var accent: Accent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(Weekdays.ordered, id: \.self) { day in
                    let on = selection.contains(day)
                    Button {
                        withAnimation(.snappy) {
                            if on { selection.removeAll { $0 == day } } else { selection.append(day) }
                        }
                    } label: {
                        Text(Weekdays.letter(day))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(on ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background {
                                Circle()
                                    .fill(on ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(Color.primary.opacity(0.07)))
                                    .frame(width: 40, height: 40)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                presetButton("Every day", days: Array(1...7))
                presetButton("Weekdays", days: [2, 3, 4, 5, 6])
                presetButton("Weekends", days: [1, 7])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func presetButton(_ title: LocalizedStringKey, days: [Int]) -> some View {
        Button(title) {
            withAnimation(.snappy) { selection = days }
        }
        .font(.caption.weight(.semibold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Set(selection) == Set(days) ? accent.color : .secondary)
    }
}
