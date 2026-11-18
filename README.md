# Sova

A native iOS app for **daily tasks, goals and routines**, built with SwiftUI and iOS 26's **Liquid Glass**.

## Design

Bold, modern and colorful, built on the palette and type of [Allo](https://allo.joshpuckett.me/).

- **Allo's palette as flat blocks.** Sunny yellow, mint, lilac, hot pink, orange, cyan, lime and deep indigo on a near-white page. Text on each block is a deep shade of the same color, so every block reads as one piece.
- **Allo, set big.** Huge heavy titles that end with a period ("Today.", "Goals.", "Sova."), small uppercase labels with open tracking ("UP NEXT · IN 48 MIN"), and big heavy numbers.
- **Big, pretty buttons.** 60pt rounded buttons with heavy text, like indigo with yellow text. Checkboxes take the color of their ritual.
- **Today.** A yellow progress block (3/8 with chunky ticks and the owl), an indigo **Up next** block with **Done** and **Tomorrow**, then rituals as blocks in their own color and tasks as white cards, all with swipe actions.
- **Goals, Rituals, Insights.** Every goal and ritual has its own color. Insights shows the 30-day number on indigo with fat week bars, big stat blocks and a mint heatmap.
- **The owl** has a belly, wings, orange feet and pink cheeks. It blinks, follows your finger on the welcome screen and smiles when your day is done. The app icon is the owl as a tilted sticker on Allo yellow, with two sparkles.

![Today](screenshots/3-today.png)

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
- **Settings.** Change your name, accent and reminder times, replay the welcome, or erase all data.

## Features

| Tab | What it does |
| --- | --- |
| **Today** | A greeting, a progress ring for the day, a row of routine buttons to tick off, tasks due today or earlier (sorted by priority), your focus goal, upcoming tasks and a list of what you finished today |
| **Goals** | Goal cards with an emoji, gradient progress and a deadline countdown. The detail screen has milestones (progress is calculated from them) or a manual progress slider, plus linked tasks and archiving |
| **Routines** | Habits grouped by Morning, Afternoon, Evening and Anytime. Each has a weekday schedule, a streak 🔥 and the last 7 days as dots. A week strip at the top shows a completion ring for each day |
| **Insights** | Swift Charts for the last 7 days, tasks completed this week, your best streak, 30-day routine consistency and average goal progress |

Data is stored only on the device, with **SwiftData**.

## Requirements

- Xcode 26 or later
- iOS / iPadOS 26 or later (Liquid Glass APIs)

## Run

1. Open `Sova.xcodeproj`.
2. Choose your team under *Signing & Capabilities*.
3. Run on an iPhone simulator or a device.

The project uses Xcode's synchronized folders, so files you add under `Sova/` are picked up automatically. If you prefer [XcodeGen](https://github.com/yonaskolb/XcodeGen), a `project.yml` is included.

## Structure

```
Sova/
  App/          entry point, root TabView, router for sheets and tabs
  Models/       SwiftData models (TaskItem, Goal, Milestone, Routine), sample data
  Theme/        color tokens, accents, themes, typography, canvas, surfaces, button styles
  Components/   owl mark, checkbox, progress, grouped list, empty state, settings menu
  Support/      natural-language parsing, reminders, task actions with undo, TipKit tips
  Features/     Onboarding, Capture, Today, Goals, Routines, Insights, Editors, Settings
```

## Credits

Typeface: [Allo](https://github.com/joshpuckett/allo) by Josh Puckett, used under the SIL Open Font License 1.1. The license ships in `Sova/Resources/Fonts/Allo-OFL.txt`.
