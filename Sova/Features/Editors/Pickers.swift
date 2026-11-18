import SwiftUI

struct AccentPicker: View {
    @Binding var selection: Accent

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Accent.allCases) { accent in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = accent }
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.ink, lineWidth: 2)
                                .padding(-5)
                                .opacity(selection == accent ? 1 : 0)
                                .scaleEffect(selection == accent ? 1 : 0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(accent.name)
                .accessibilityAddTraits(selection == accent ? .isSelected : [])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }
}

/// A grid of SF Symbols, used for routines and goals.
struct SymbolPicker: View {
    @Binding var selection: String
    var accent: Accent
    var symbols: [String]

    static let routineSymbols = [
        "sun.max", "moon", "wind", "drop", "leaf", "figure.walk",
        "figure.run", "figure.flexibility", "dumbbell", "bicycle", "bed.double", "heart",
        "book.closed", "pencil.and.scribble", "checklist", "scope", "music.note", "paintbrush.pointed",
        "fork.knife", "cup.and.saucer", "pills", "laptopcomputer", "phone", "envelope",
    ]

    static let goalSymbols = [
        "flag.checkered", "figure.run", "book.closed", "paperplane", "briefcase", "house",
        "airplane", "graduationcap", "dollarsign", "heart", "leaf", "mountain.2",
        "paintbrush.pointed", "music.note", "camera", "globe.europe.africa", "hammer", "lightbulb",
        "dumbbell", "bicycle", "brain", "trophy", "person.2", "star",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
            ForEach(symbols, id: \.self) { symbol in
                let selected = selection == symbol
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selection = symbol }
                } label: {
                    Image(systemName: symbol)
                        .font(.allo(size: 18, weight: .medium))
                        .foregroundStyle(selected ? Color.inkInverse : Color.ink)
                        .frame(width: 44, height: 44)
                        .background(selected ? SovaTheme.current.accent.color : Color.well,
                                    in: .rect(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
        .sovaFeedback(.selection, trigger: selection)
    }
}

struct WeekdayPicker: View {
    @Binding var selection: [Int]
    var accent: Accent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Weekdays.ordered, id: \.self) { day in
                    let on = selection.contains(day)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if on { selection.removeAll { $0 == day } } else { selection.append(day) }
                        }
                    } label: {
                        Text(Weekdays.letter(day))
                            .font(.allo(.subheadline, .semibold))
                            .foregroundStyle(on ? Color.inkInverse : Color.ink)
                            .frame(width: 38, height: 38)
                            .background(on ? SovaTheme.current.accent.color : Color.well, in: .circle)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                preset("Every day", days: Array(1...7))
                preset("Weekdays", days: [2, 3, 4, 5, 6])
                preset("Weekends", days: [1, 7])
            }
        }
        .sovaFeedback(.selection, trigger: selection)
    }

    private func preset(_ title: LocalizedStringKey, days: [Int]) -> some View {
        let active = Set(selection) == Set(days)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selection = days }
        } label: {
            Text(title)
                .font(.allo(.caption, .semibold))
                .foregroundStyle(active ? Color.inkInverse : Color.ink)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(active ? Color.ink : Color.well, in: .capsule)
        }
        .buttonStyle(.pressable)
    }
}
