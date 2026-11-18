# Sova

A native iOS app for **daily tasks, goals and routines**, built with SwiftUI and iOS 26's **Liquid Glass**.

## Design

- **Liquid Glass where Apple's HIG puts it.** The tab bar (it shrinks as you scroll), toolbars, the floating "New …" accessory above the tab bar, the checkboxes and the routine buttons are all real `glassEffect` controls. Content cards sit on a frosted material with a soft accent tint, so the glass controls stay distinct.
- **Aurora background.** Every screen floats on a slowly moving `MeshGradient`. There are five themes (Aurora, Sunset, Lagoon, Twilight, Bloom), switched from the palette menu. Colors are pastel in Light Mode and deep in Dark Mode.
- **Nine accent colors** (Iris, Orchid, Rose, Coral, Peach, Lime, Mint, Lagoon, Sky), each paired with a gradient partner.
- **Native details:** SF Symbols with symbol effects, numeric text transitions, haptics, zoom navigation transitions, Dynamic Type text styles, 44 pt tap targets, VoiceOver labels and actions, and support for Reduce Motion (the background stops moving).

## Features

| Tab | What it does |
| --- | --- |
| **Today** | A greeting, a progress ring for the day, a row of routine buttons to tick off, tasks due today or earlier (sorted by priority), your focus goal, upcoming tasks and a list of what you finished today |
| **Goals** | Goal cards with an emoji, gradient progress and a deadline countdown. The detail screen has milestones (progress is calculated from them) or a manual progress slider, plus linked tasks and archiving |
| **Routines** | Habits grouped by Morning, Afternoon, Evening and Anytime. Each has a weekday schedule, a streak 🔥 and the last 7 days as dots. A week strip at the top shows a completion ring for each day |
| **Insights** | Swift Charts for the last 7 days, tasks completed this week, your best streak, 30-day routine consistency and average goal progress |

Data is stored on the device with **SwiftData**. On first launch the app adds a small sample set so it looks lived-in right away.

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
  Theme/        palette, accents, aurora mesh background, card surface
  Components/   progress ring and bar, section header, chips, theme menu
  Features/     Today, Goals, Routines, Insights, Editors
```
