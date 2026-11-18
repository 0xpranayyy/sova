# Sova: search ranking, featuring and the Apple Design Awards

## 1. Search (App Store Optimization)

### How App Store search actually works
- Apple ranks your app on only four things:
  - the **app name** (strongest)
  - the **subtitle**
  - the hidden **keyword field**
  - **in-app purchase names**
- The **description is not used for ranking** on the App Store. It only helps people decide once they're on your page.
- Apple combines words **across** those fields. "habit" (name) + "tracker" (subtitle) still matches a search for "habit tracker".
- Never repeat a word in two fields; it wastes space. Use singular forms, commas with no spaces, and no competitor names (that breaks Apple's rules).
- After keywords, ranking depends on **downloads, ratings and how many searchers tap and install**. Great screenshots and reviews matter as much as keywords.

### The metadata

| Field | Value | Length |
| --- | --- | --- |
| Name | `Sova: To-Do List & Habits` | 25/30 |
| Subtitle | `Daily Planner & Goal Tracker` | 28/30 |
| Keywords | `todo,task,manager,reminder,routine,schedule,checklist,streak,productivity,widget,focus,morning,adhd` | 99/100 |

**Searches this covers** (all checked):
- to do list, todo list
- habit tracker, habit streak
- daily planner, task planner, goal planner, focus planner, schedule planner
- goal tracker, routine tracker
- task manager
- daily routine, morning routine
- reminder, checklist, daily checklist
- productivity, to do widget
- adhd planner

**About "adhd":** people with ADHD are one of the biggest groups searching for planners, and Sova's design fits them well:
- one Up Next item at a time
- gentle reminders
- swipe to tomorrow without guilt
- streaks that rest days don't break

Apple requires keywords to be relevant, and this one is. If you'd rather not target it, swap `adhd` for `plan`.

**Why this beats the old name.** "Sova: Tasks, Habits & Goals" + "Plan your day with a cute owl" spent the subtitle on "cute owl", which nobody searches for. The new name puts **"to-do list"** (the biggest search in this category) and **"habits"** in the strongest field.

### Double your keyword space (legitimately)
The US App Store also reads the **Spanish (Mexico)** listing, and the UK store reads **English (U.K.)**.
- **Spanish (Mexico):** add a real Spanish translation of the listing, with Spanish keywords: `tareas,lista,hábitos,planificador,metas,rutina,recordatorio,agenda,diario,productividad`. This helps Spanish speakers in the US and gives you more search terms.
- **English (U.K.):** copy the English listing for UK and Commonwealth stores.
- **Hindi and other markets:** later, translate the app itself, not just the listing. Apple values real localization highly.

### Conversion (turning searchers into downloads)
- **Screenshot 1** decides most installs. It already shows the Today screen with a clear headline.
- **Product Page Optimization** (App Store Connect → Product Page Optimization) lets you test up to 3 variations of icon or screenshots on real visitors. Test the yellow-owl icon against the "Sunny" icon, and two different first screenshots.
- **Custom Product Pages:** up to 35 versions of your page, each with its own screenshots and link. Use them for ads or posts aimed at different people. For example:
  - students: "study planner"
  - fitness: "habit tracker"
  - ADHD: "one thing at a time"
- **In-App Events** (App Store Connect → In-App Events) show up in search results and on the Today tab. Ideas:
  - "New Year: 30-day habit challenge"
  - "Back to school planner"
  - "Spring reset"

### Ratings
- The app asks for a rating only after someone finishes a whole day: on the 3rd such day, at most every 60 days. This is already built.
- Reply to every review in App Store Connect, especially critical ones. Replies are public and build trust.
- Before launch, invite friends to TestFlight and fix what they find. A strong first week of ratings lifts ranking.

---

## 2. Getting featured on the App Store

Apple's editors pick featured apps by hand. They look for **great design, real usefulness, adoption of new Apple technology, accessibility and localization**.

**Submit a featuring nomination:** App Store Connect → your app → **Featuring Nominations** → New Nomination → type **App Launch**. Submit **3–4 weeks before** your release date and set the release to manual so you control launch day. Use this text:

> **Sova: To-Do List & Habits** brings tasks, daily rituals and big goals together in one calm, joyful iPhone app. You type a task the way you'd say it ("Call Mom tomorrow 6pm !!") and Sova fills in the date, time, repeat and priority. Rituals keep streaks on the days you choose, goals break into steps, and an owl companion celebrates when you finish your day.
>
> Sova is built entirely on Apple technology:
> - SwiftUI and SwiftData
> - Liquid Glass and an iOS 26 design
> - interactive Home Screen and Lock Screen widgets
> - App Intents for Siri, Shortcuts and Spotlight
> - TipKit
> - a native StoreKit paywall
> - iCloud sync
>
> It is private by design: no account, no tracking, no ads. It supports dark mode, Reduce Motion and haptics throughout, with a custom typeface and hand-made illustration.

---

## 3. Apple Design Awards: what it takes

**How the awards work:** there is **no application**. Apple's teams choose finalists themselves, usually announced before WWDC in June, from apps they've noticed. Being featured, having strong ratings and being talked about all help Apple notice you.

**The six award categories, and where Sova fits:**

| Category | Sova's fit today | What would make it a contender |
| --- | --- | --- |
| **Delight and Fun** | Strong: the owl, celebrations, sounds, stickers | More owl moments: seasonal outfits, reactions to streak milestones |
| **Interaction** | Good: natural-language capture, swipe to tomorrow, interactive widgets | Control Center control, Action button support, Apple Watch quick add |
| **Visuals and Graphics** | Good: custom type, illustration, Liquid Glass | Animated widgets and an app icon that changes with your streak |
| **Inclusivity** | Needs work | Full VoiceOver, Dynamic Type at every size, several languages |
| **Innovation** | Possible | On-device Apple Intelligence (Foundation Models) to break goals into steps and plan the day |
| **Social Impact** | Not a fit | none |

### The roadmap toward award level

**1.1 (the essentials judges check first)**
- [ ] **VoiceOver everywhere:** every button, check, chart and the owl described. Test the full app with VoiceOver on.
- [ ] **Dynamic Type** up to the largest accessibility sizes, with no clipped text.
- [ ] **Localization:** Spanish, Hindi, German, Japanese, French and Portuguese, starting with the app.
- [ ] **Spotlight:** tasks and rituals appear in iPhone search through App Intents entities.
- [ ] **Control Center and Lock Screen controls:** "Add task" and "Tick ritual".

**1.2 (the "wow" layer)**
- [ ] **Apple Intelligence** with the on-device Foundation Models framework:
  - "Break this goal into steps"
  - "Plan my day" from your tasks and rituals
  - Private, with no server.
- [ ] **Apple Watch app:** tick rituals from the wrist, with complications.
- [ ] **Live Activity:** a focus timer with the owl on the Lock Screen and Dynamic Island.
- [ ] **StandBy widget** for the nightstand.

**1.3**
- [ ] **iPad and Mac** versions with keyboard shortcuts.
- [ ] **Owl outfits** unlocked by streaks: shareable, and pure "Delight and Fun".

---

## 4. Launch checklist
1. **TestFlight beta** with 20–50 people for 2 weeks. Fix every crash and rough edge.
2. **Featuring nomination** 3–4 weeks before launch.
3. **Set a launch date** with manual release.
4. **Launch day:**
   - post the film on X, Instagram Reels and TikTok
   - a Product Hunt launch
   - share the website and press kit with app review blogs
5. **Week 1:** reply to every review, watch the crash logs (Xcode Organizer or App Store Connect), and ship a 1.0.1 fast if needed.
6. **Week 2+:** start Product Page Optimization tests, then plan the first In-App Event.
