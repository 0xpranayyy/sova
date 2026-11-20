import SwiftUI
import SwiftData

/// The top of Today, drawn without a List or a tab bar so the welcome wave
/// can carry the onboarding screen into it. It does nothing on its own: the
/// wave keeps hidden copies of it mounted, and the real Today takes over as
/// soon as the wave has landed.
///
/// The wave's stage spans the whole screen and passes no safe area down, so
/// this lays itself out with the screen's own width and safe area.
struct TodayIntroView: View {
    @Environment(WaveDirector.self) private var waves
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("userName") private var userName = ""

    var body: some View {
        let todays = routines.filter { $0.isScheduled(on: .now) }
        GeometryReader { geo in
            let width = geo.size.width
            // Same column as the real Today, so the swap is invisible on iPad too.
            let side = 16 + ReadableLayout.margin(for: width)
            let inner = max(0, width - 2 * side)
            VStack(alignment: .leading, spacing: 0) {
                ScreenTitle(title: String(localized: "Today"),
                            subtitle: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                    CircleAction(symbol: "gearshape", label: String(localized: "Settings")) {}
                }
                .frame(width: inner)
                .padding(.top, 4)
                .padding(.bottom, 14)

                DayHeaderCard(greeting: TodayView.greeting(for: userName),
                         done: 0, total: todays.count, streak: 0)
                    .frame(width: inner)

                if !todays.isEmpty {
                    SectionLabel(String(localized: "Rituals · 0 of \(todays.count)"))
                        .frame(width: inner, alignment: .leading)
                        .padding(.top, 28)
                        .padding(.bottom, 10)

                    HStack(spacing: 10) {
                        ForEach(Array(todays.prefix(4).enumerated()), id: \.element.id) { index, ritual in
                            RitualCard(routine: ritual, tilt: index.isMultiple(of: 2) ? -2 : 2) {}
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(width: inner, alignment: .leading)
                }
            }
            .padding(.top, waves.insets.top)
            .padding(.horizontal, side)
            .frame(width: width, height: geo.size.height, alignment: .topLeading)
            .clipped()
        }
        .background(Color.canvas)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
