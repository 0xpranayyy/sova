# Sova

A native iOS app for **daily tasks, goals and routines**, built with SwiftUI and iOS 26's **Liquid Glass**.

## Design

- **Vivid color blends.** Every screen sits on a slowly drifting `MeshGradient`. There are five themes (Sunset, Ocean, Meadow, Aurora, Midnight); each is bright pastel in Light Mode and deep and glowing in Dark Mode.
- **Liquid Glass throughout.** Cards, task rows, routine buttons, tiles, chips, text fields and buttons all use `glassEffect`, tinted with their accent and interactive where you can tap. The tab bar shrinks as you scroll, and the "New …" accessory floats above it.
- **Native type.** SF Pro with bold, Apple-style headlines and rounded numerals for stats.
- **Nine vivid accents**, each paired with a neighbor for two-tone gradients on icons, progress and selections.
- **Crafted details:** a checkbox that draws its own tick, a glowing two-tone progress ring for the day, springy pressable tiles, haptics on every meaningful change, and an owl mascot that blinks, follows your finger and smiles when you're done.

## Onboarding

Eight short steps. Each has one idea, a staggered blur-in reveal, and drifting washes of color that change mood per step. Swipe right to go back.

1. **Welcome.** The classic Apple layout: the owl in a glass bubble (its eyes follow your touch), "Welcome to Sova" and three feature rows.
2. **Three kinds of intention.** Fanned cards explain Today, Always and Someday. The example task is live, so tick it.
3. **Your name**, with a live preview of your greeting.
4. **Rituals.** Tactile tiles; each one you pick becomes a real routine.
5. **One goal for this season.** Write your own or tap a suggestion. It's created with a 90-day horizon.
6. **Reminders.** A preview of the real notification, then morning and evening times. The system permission prompt only appears after you choose "Turn on reminders".
7. **Make it yours.** A preview of *your* first day (your rituals, your goal) recolors live as you pick a theme.
8. **All set.** A summary of what was created; the owl hops and smiles.

Onboarding creates only what you choose; there is no sample or placeholder data. Inside the app, TipKit carries on teaching: first quick capture, then swiping.

## Everyday UX

- **Quick capture.** "New Task" opens a small sheet that reads natural language as you type: `Call Mom tomorrow 6pm !!` becomes a high-priority task due tomorrow at 6 PM. Return adds the task and keeps the field open for the next one.
- **Swipe actions.** On Today, swipe right to finish a task, and swipe left to push it to tomorrow or delete it.
- **Undo, everywhere.** Completing, moving or deleting a task shows a brief Undo bar in the Liquid Glass accessory above the tab bar.
- **Settings.** Change your name, theme and reminder times, replay the welcome, or erase all data.

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
