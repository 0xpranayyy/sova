import SwiftUI
import SwiftData

/// The top of Today, drawn without a List or a tab bar so the welcome wave
/// can carry the onboarding screen into it. It does nothing on its own: the
/// wave keeps hidden copies of it mounted, and the real Today takes over as
/// soon as the wave has landed.
struct TodayIntroView: View {
    @Query(sort: \Routine.order) private var routines: [Routine]
    @AppStorage("userName") private var userName = ""

    var body: some View {
        let todays = routines.filter { $0.isScheduled(on: .now) }
        ZStack(alignment: .top) {
            Color.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                ScreenTitle(title: String(localized: "Today"),
                            subtitle: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                    CircleAction(symbol: "gearshape", label: String(localized: "Settings")) {}
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 14)

                DayStage(greeting: TodayView.greeting(for: userName),
                         done: 0, total: todays.count, streak: 0)
                    .padding(.horizontal, 16)

                if !todays.isEmpty {
                    SectionLabel(String(localized: "Rituals · 0 of \(todays.count)"))
                        .padding(.horizontal, 16)
                        .padding(.top, 28)
                        .padding(.bottom, 10)

                    HStack(spacing: 10) {
                        ForEach(Array(todays.prefix(4).enumerated()), id: \.element.id) { index, ritual in
                            RitualCard(routine: ritual, tilt: index.isMultiple(of: 2) ? -2 : 2) {}
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
