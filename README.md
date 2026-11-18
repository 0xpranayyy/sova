# Sova

A native iOS app for **daily tasks, goals and routines**, built with SwiftUI and iOS 26's **Liquid Glass**.

## Design

Sova draws on Apple's restraint and the warmth of the Browser Company. There are no gradient blobs on every card, no emoji icons and no sparkles.

- **Paper and ink.** A warm off-white canvas (deep warm black in Dark Mode), ink that's never pure black, a hairline-edged surface for content, and a whisper of film grain.
- **Editorial type.** New York serif for display text and screen titles; SF Pro for everything you tap.
- **One accent at a time.** Nine flat accents, each tuned separately for Dark Mode. Five themes (Ember, Tide, Moss, Plum, Ink) set the mood with a soft wash of light at the top of the canvas.
- **Crafted components.** A checkbox that draws its own tick, Things-style grouped lists, a day shown as segments, `!!` / `!!!` priorities, ink-capsule primary buttons, springy pressable tiles, and haptics on every meaningful change.
- **Liquid Glass where the HIG puts it:** the tab bar (it shrinks as you scroll), toolbars, the "New …" accessory above the tabs, sheets and floating back buttons. Content stays on quiet, solid surfaces.
- **A mascot.** "Sova" means owl. The owl blinks, follows your finger on the welcome screen and smiles when you're done.

## Onboarding

Six steps, each with one idea and a staggered, blur-in reveal over drifting washes of color that change mood per step:

1. **Hello.** An italic serif greeting; the owl's eyes follow your touch.
2. **Three kinds of intention.** Fanned, slightly rotated cards for Today, Always and Someday. The task is live, so tick it.
3. **Your name.** A big serif field with a live preview of your greeting.
4. **Rituals.** Tactile tiles to pick starter routines, which become real routines.
5. **Make it yours.** A miniature Today screen recolors live as you pick a theme.
6. **All set.** The owl hops and smiles; Sova opens.

You can replay it from the settings menu on Today.

## Features

| Tab | What it does |
| --- | --- |
| **Today** | A greeting, a progress ring for the day, a row of routine buttons to tick off, tasks due today or earlier (sorted by priority), your focus goal, upcoming tasks and a list of what you finished today |
| **Goals** | Goal cards with an emoji, gradient progress and a deadline countdown. The detail screen has milestones (progress is calculated from them) or a manual progress slider, plus linked tasks and archiving |
| **Routines** | Habits grouped by Morning, Afternoon, Evening and Anytime. Each has a weekday schedule, a streak 🔥 and the last 7 days as dots. A week strip at the top shows a completion ring for each day |
| **Insights** | Swift Charts for the last 7 days, tasks completed this week, your best streak, 30-day routine consistency and average goal progress |

Data is stored on the device with **SwiftData**. Onboarding creates your chosen routines and two first tasks; SwiftUI previews use a fuller sample dataset.

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
  Features/     Onboarding, Today, Goals, Routines, Insights, Editors
```
