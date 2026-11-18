# Sova

A native iOS app for **daily tasks, goals and routines**, built with SwiftUI and iOS 26's **Liquid Glass**.

## Design

Bold, modern and colorful, built on the palette and type of [Allo](https://allo.joshpuckett.me/).

- **Allo's palette as flat blocks.** Sunny yellow, mint, lilac, hot pink, orange, cyan, lime and deep indigo on a near-white page. Text on each block is a deep shade of the same color, so every block reads as one piece.
- **Allo, set big.** Huge heavy titles that end with a period ("Today.", "Goals.", "Sova."), small uppercase labels with open tracking ("UP NEXT · IN 48 MIN"), and big heavy numbers.
- **Big, pretty buttons.** 60pt rounded buttons with heavy text, like indigo with yellow text. Checkboxes take the color of their ritual.
- **Today.** A huge "Today." title, then an indigo stage where the owl sits inside a yellow ring that fills as you finish things, with "3 of 8 done" and streak stickers and twinkling sparkles. Below it, a yellow **Up next** block with big **Done** and **Tomorrow** buttons and the owl perched on top saying "This one's next!", a swipeable row of tilted ritual tiles, and tasks as white cards with swipe actions.
- **Goals.** An indigo season summary with the owl and a "done 🏆" sticker, then each goal as a block in its own color: a tilted icon, a big percentage, chunky step segments, and the next step with a check you can tap right on the card.
- **Insights.** The 30-day number on indigo with the happy owl and fat week bars, tilted pink and orange stat blocks, a "Most consistent" card with each ritual's bar in its color, and a mint heatmap.
- **Rituals.** Every ritual is a block in its own color with its last seven days and a big check.
- **The owl** has a belly, wings, orange feet and pink cheeks. It blinks, follows your finger on the welcome screen and smiles when your day is done. The app icon is the owl as a tilted sticker on Allo yellow, with two sparkles.

![Today](screenshots/3-today.png)

## Feel

Small, physical details everywhere:

- **The owl is alive.** It breathes, glances around on its own, leans toward where it's looking, double-blinks now and then, and flaps its wings when happy. Tap it and it squishes, hops with spring physics and squints happily. Its cheeks glow when it's pleased.
- **Celebrations.** Finishing your whole day or a whole goal bursts sparkles outward with spring physics while the owl hops and flaps, timed to a rolling haptic flourish.
- **Two waves, used sparingly.** Tapping "Open Sova" at the end of onboarding sends a wave in Sova's sticker colors up from the button, carrying the welcome screen into Today. Finishing the whole day (once a day) sends a ring out from the owl into a "Day done!" summary with the day's tasks, rituals and streak. Both use Distortion Waves and become a simple crossfade with Reduce Motion.
- **Haptics with intent.**
  - A soft press on every big button.
  - A tick when switching tabs.
  - A success tap when you check something off, and a warning buzz on delete.
  - A crisp pop for "move to tomorrow".
  - A "pop pop pop" as the welcome stickers land.
  - A tick when quick capture recognizes a date or priority.
- **Tactile pieces.** Buttons squish slightly darker when pressed, ritual tiles wiggle and swell when checked, and checkmarks draw themselves in. Every motion respects Reduce Motion.
- **Little sounds.** Tiny tones made in code, with no audio files:
  - a rising "ding" when you check something off, and a soft low note when you uncheck it
  - an arpeggio when the day is done
  - a "hoo-hoo" when you poke the owl
  - pops as the welcome stickers land

  They follow the silent switch, mix with your music, and can be turned off in Settings.
- **Dark mode.** A deep indigo night page with dark indigo cards, so the Allo colors glow. The owl turns into a yellow night owl, and there's a matching dark app icon. It follows the iPhone by default, or you can pick System, Light or Dark in Settings.
- **Rituals.** The week on indigo: day columns fill with yellow, the owl perches on today, and your best streak sits on a mint starburst. Rituals are grouped under Morning, Afternoon, Evening and Anytime pills, each a color block with a 7-day dot track, a 🔥 streak and a big check that wiggles.

## Onboarding

Short, colorful steps with big buttons and a chunky progress bar. Swipe right to go back.

1. **Welcome.** The owl on an indigo stage, with tilted stickers of a Sova day popping in around it, then a huge "Sova.".
2. **How it works.** Tasks, rituals (mint) and goals (pink), with a live task you can tick.
3. **Your name.** The owl asks in a speech bubble ("Hi, I'm Sova! What should I call you?") and smiles once you answer.
4. **Rituals.** Tiles fill with their color and tilt when you choose them; each becomes a real ritual.
5. **A goal**, written yourself or picked from tilted, colorful suggestions. It gets 90 days.
6. **Reminders.** A preview of the real notification, then morning and evening blocks with their times.
7. **All set.** The owl hops and smiles among twinkling sparkles, with your rituals, reminders and goal as blocks.

Onboarding creates only what you choose; there is no sample or placeholder data. Inside the app, TipKit carries on teaching: first quick capture, then swiping.

## Everyday UX

- **Quick capture.** The "+" in the tab bar opens a small sheet that reads natural language as you type and highlights the date and priority it found: `Call Mom tomorrow 6pm !!` becomes a high-priority task due tomorrow at 6 PM. Return adds the task and keeps the field open for the next one.
- **Swipe actions.** On Today's timeline, swipe right to finish a task or ritual, and swipe left to push a task to tomorrow or delete it.
- **Undo, everywhere.** Completing, moving or deleting a task shows a brief Undo bar floating above the tab bar.

## Features

| Area | What it does |
| --- | --- |
| **Today** | A greeting, the owl inside a progress ring for the day, an Up Next card, today's rituals as tiles, overdue and open tasks, and what you finished today |
| **Tasks** | Quick capture reads natural language (`Call Mom tomorrow 6pm !!`, `Water plants every Sunday`). Tasks can repeat (daily, weekdays, weekly, monthly, yearly) and alert at their time or a few minutes before |
| **Goals** | Goal cards with steps, progress and a deadline; linked tasks; archiving |
| **Rituals** | Habits grouped by time of day with weekday schedules, streaks 🔥 and a week view on an indigo stage |
| **Insights** | This week's bars, stats, a 17-week activity calendar and 30-day ritual consistency |
| **Widgets** | Today (owl and progress ring, Up Next), interactive Rituals (tick right from the Home Screen) and Lock Screen widgets |
| **Siri & Shortcuts** | "Add a task in Sova", "Tick off a ritual in Sova", "Show my day in Sova" |
| **Sova Plus** | Unlimited rituals and goals (free: 3 rituals, 1 active goal), iCloud sync, extra app icons. Monthly, yearly (7-day trial) or lifetime, using StoreKit 2 |
| **Settings** | Appearance, theme, app icon, sounds, haptics, week start, alert timing, overdue badge, reminders, iCloud sync, help and legal links |

Data lives in a SwiftData store in the App Group container, shared with the widgets. With Plus and iCloud sync on, it mirrors to the user's private CloudKit database.

## Requirements

- Xcode 26 or later
- iOS / iPadOS 26 or later

## Run

1. Open `Sova.xcodeproj`.
2. Under *Signing & Capabilities*, choose your Team for both **Sova** and **SovaWidgetsExtension**. Xcode then registers the App Group `group.app.sova.Sova`, the iCloud container `iCloud.app.sova.Sova` and Push Notifications.
3. Run the **Sova** scheme. It uses `Sova.storekit`, so you can test purchases in the simulator without App Store Connect.

The project uses Xcode's synchronized folders, so files you add under `Sova/`, `Shared/` or `SovaWidgets/` are picked up automatically. A `project.yml` for [XcodeGen](https://github.com/yonaskolb/XcodeGen) is included too.

## Publishing

Follow `marketing/app-store/PUBLISHING.md`, a step-by-step checklist covering:
- accounts and agreements
- the two placeholders to fill in
- GitHub Pages for the privacy and support pages
- signing and the CloudKit production schema
- in-app purchase setup
- App Store Connect fields
- App Privacy answers
- ready-to-paste review notes

## Structure

```
Sova/           the app: App, Features, Components, Theme, Support, Intents
Shared/         used by the app and the widgets: models, store, settings,
                palette, fonts, quick parse, task alerts, App Intents
SovaWidgets/    WidgetKit extension: Today, Rituals, Lock Screen
Config/         entitlements and the app's extra Info.plist keys
docs/           the Sova website (GitHub Pages): home, support, privacy, terms,
                press kit, acknowledgments, 404, sitemap.xml and robots.txt
marketing/      launch film, App Store screenshots, banner and listing copy
```

## Credits

Typeface: [Allo](https://github.com/joshpuckett/allo) by Josh Puckett, used under the SIL Open Font License 1.1. The license ships in `Shared/Fonts/Allo-OFL.txt`.

Transitions: [Distortion Waves](https://github.com/Jakubantalik/Libraries.dev) (`DistortionWavesKit`) by Jakub Antalik, from libraries.dev, used under the MIT License through Swift Package Manager, pinned to a fixed revision.
