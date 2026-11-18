# Sova: App Store listing pack

Everything to enter in App Store Connect and the Apple Developer site, in the order you'll meet it. Every field is checked against Apple's character limits.

---

## 0. Apple Developer site (developer.apple.com → Certificates, IDs & Profiles)

**Identifiers → App Groups → +**
- Description: `Sova Group`
- Identifier: `group.app.sova.Sova`

**Identifiers → iCloud Containers → +**
- Description: `Sova iCloud`
- Identifier: `iCloud.app.sova.Sova`

**Identifiers → App IDs → + (App)**

| Field | App | Widget |
| --- | --- | --- |
| Description | `Sova` | `Sova Widgets` |
| Bundle ID (Explicit) | `app.sova.Sova` | `app.sova.Sova.Widgets` |
| Capabilities | **App Groups** (select `group.app.sova.Sova`), **iCloud** with CloudKit (select `iCloud.app.sova.Sova`), **Push Notifications** | **App Groups** (select `group.app.sova.Sova`) |

In-App Purchase is on by default for every App ID.

---

## 1. App Store Connect → Apps → + → New App

| Field | Enter |
| --- | --- |
| Platforms | iOS |
| Name | `Sova: Tasks, Habits & Goals` |
| Primary Language | English (U.S.) |
| Bundle ID | `app.sova.Sova` |
| SKU | `sova-ios-1` |
| User Access | Full Access |

---

## 2. App Information

| Field | Enter |
| --- | --- |
| Name (30) | `Sova: Tasks, Habits & Goals` (27) |
| Subtitle (30) | `Plan your day with a cute owl` (29) |
| Primary Category | Productivity |
| Secondary Category | Lifestyle |
| Content Rights | "Does your app contain, show, or access third-party content?" → **No** |
| License Agreement | Apple's Standard License Agreement (leave as is) |

**Age Rating:** answer **None / No** to every question. This covers violence, mature content, gambling, contests, unrestricted web access, user-generated content, messaging, advertising, and medical or wellness treatment. Result: **4+**.

---

## 3. Pricing and Availability
- **Price:** Free (USD 0.00)
- **Availability:** all countries and regions
- **Pre-orders:** off

---

## 4. App Privacy
- **Privacy Policy URL:** `https://0xpranayyy.github.io/sova/privacy.html`
- "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app.**
- Result shown on the App Store: **Data Not Collected**

**Accessibility** (optional "Accessibility Nutrition Labels"): only claim what you've tested on a real iPhone. Safe to claim: **Dark Interface** and **Reduced Motion**. Add **VoiceOver** and **Larger Text** only after testing them in TestFlight.

---

## 5. Version 1.0 page

### Promotional Text (170)
```
Tasks, habits and big goals in one app. Type a task the way you'd say it, tick it off, and watch your day come together, with a little owl along for the ride.
```

### Description (4000)
```
Sova keeps your tasks, daily habits and big goals in one simple app for iPhone.

JUST TYPE IT
Write the way you talk: "Call Mom tomorrow 6pm !!". Sova fills in the day, the time and the priority. Add "every Monday" and it repeats.

ONE SCREEN FOR TODAY
• Today shows what's due, the rituals you planned and anything overdue
• Up Next picks the one thing to do right now
• A progress ring fills as you finish your day
• Swipe anything you can't do today to tomorrow
• Tap Undo if you tick, move or delete something by mistake

HABITS, ON A SCHEDULE
• Add rituals like "Drink water", "Morning walk" or "Read 20 pages"
• Choose morning, afternoon or evening, and the days of the week
• Keep your streak going. Rest days don't break it.

BIG GOALS, SMALL STEPS
• Give a goal a deadline and break it into steps
• Each step you tick moves the percentage
• Link tasks to the goal they serve

ALERTS AND REPEATS
• A notification at a task's time, or a few minutes before
• Repeat daily, on weekdays, weekly, monthly or yearly
• Optional morning and evening reminders to plan and look back

WIDGETS AND SIRI
• Today widget with your progress ring
• Rituals widget: tick habits off right from the Home Screen
• Lock Screen widgets for your progress and what's next
• "Hey Siri, add a task in Sova", plus actions in Shortcuts

INSIGHTS
• Your week at a glance and a 17-week activity calendar
• See which rituals you keep most often

DESIGNED WITH CARE
• A friendly owl that celebrates when you finish your day
• Soft sounds and haptics when you check things off, both optional
• Light and dark mode, with a theme color you choose

PRIVATE
No account and no sign-up. No tracking, no ads. Your data stays on your iPhone, or in your own iCloud if you turn on sync.

SOVA PLUS
Sova is free with unlimited tasks, 3 rituals and 1 active goal. Sova Plus adds:
• Unlimited rituals and goals
• iCloud sync across your devices
• Extra app icons

Sova Plus is available as a monthly or yearly auto-renewable subscription (the yearly plan starts with a 7-day free trial), or as a one-time lifetime purchase. Payment is charged to your Apple Account when you confirm the purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period, and your account is charged for renewal within 24 hours before the period ends. Manage or cancel anytime in your Apple Account settings. Any unused part of a free trial ends when you buy a subscription.

Privacy Policy: https://0xpranayyy.github.io/sova/privacy.html
Terms of Use: https://0xpranayyy.github.io/sova/terms.html
License Agreement (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

### Keywords (100)
```
todo,planner,habit,tracker,routine,goals,reminder,daily,streak,productivity,checklist,list,focus
```

### URLs and other fields
| Field | Enter |
| --- | --- |
| Support URL | `https://0xpranayyy.github.io/sova/support.html` |
| Marketing URL | `https://0xpranayyy.github.io/sova/` |
| Version | `1.0` |
| Copyright | `2026 0xpranayyy` |
| Routing App Coverage File | leave empty |

### Screenshots: iPhone 6.9" Display
Upload in this order from `marketing/app-store/6.9-inch/`:
1. `1-hero.png`
2. `2-capture.png`
3. `3-rituals.png`
4. `4-goals.png`
5. `5-dark.png`
6. `6-done.png`

App Store Connect scales them down for smaller iPhones automatically. If it asks for 6.7", use the same names from `marketing/app-store/6.7-inch/`.

**App Preview (optional):** `marketing/Sova-intro.mp4`. Apple allows 15–30 seconds; trim a second if it complains.

### Build
Choose the build uploaded from Xcode or the cloud build. Encryption is already declared in the app, so you won't be asked.

### In-App Purchases and Subscriptions (on this page)
Click **+** and add all three products from section 6, so they're reviewed together with 1.0.

### App Review Information
| Field | Enter |
| --- | --- |
| Sign-in required | **No** |
| Contact first name, last name, phone, email | **yours.** Apple uses these only if they have a question. |
| Attachment | none |

**Notes** (paste):
```
Sova needs no account or sign-in. Everything works offline on the device.

Free plan: unlimited tasks, up to 3 rituals and 1 active goal.
Sova Plus (auto-renewable subscription: monthly, or yearly with a 1-week free trial; or a one-time lifetime purchase) unlocks unlimited rituals and goals, iCloud sync and an alternate app icon.

To see the paywall: open Settings (gear icon on the Today tab) and tap Sova Plus, or try to add a 4th ritual on the Rituals tab. Restore Purchases is in Settings → Help and on the paywall. The Privacy Policy and Terms of Use (Apple standard EULA) are linked on the paywall and in the description.

Widgets: Today, Rituals (interactive) and Lock Screen widgets.
Siri: "Add a task in Sova".
```

### Version Release
**Manually release this version**, so you choose the launch moment after approval.

### What's New
Not shown for a first version. For 1.0 you can leave it empty.

---

## 6. Monetization → Subscriptions

**Subscription Group:**
- Reference Name: `Sova Plus`
- Localization, English (U.S.): Subscription Group Display Name `Sova Plus`, App Name Display Options: use the App Name

**Subscription 1 (Level 1, highest value):**
| Field | Enter |
| --- | --- |
| Reference Name | `Sova Plus Yearly` |
| Product ID | `app.sova.plus.yearly` |
| Duration | 1 Year |
| Price | USD 24.99 (India: ₹999) |
| Display Name (30) | `Sova Plus Yearly` |
| Description (45) | `Unlimited rituals, goals and iCloud sync` (40) |
| Introductory Offer | Free, 1 week, all countries and regions, starts now, no end date |
| Family Sharing | Off |

**Subscription 2 (Level 2):**
| Field | Enter |
| --- | --- |
| Reference Name | `Sova Plus Monthly` |
| Product ID | `app.sova.plus.monthly` |
| Duration | 1 Month |
| Price | USD 3.99 (India: ₹199) |
| Display Name (30) | `Sova Plus Monthly` |
| Description (45) | `Unlimited rituals, goals and iCloud sync` (40) |
| Family Sharing | Off |

## 7. Monetization → In-App Purchases → + → Non-Consumable
| Field | Enter |
| --- | --- |
| Reference Name | `Sova Plus Lifetime` |
| Product ID | `app.sova.plus.lifetime` |
| Price | USD 49.99 (India: ₹2,499) |
| Display Name (30) | `Sova Plus Lifetime` |
| Description (45) | `Everything in Plus, forever, no subscription` (44) |
| Family Sharing | Off |

**For all three products:**
- **Review Screenshot:** a screenshot of the paywall from the real app (Settings → Sova Plus), taken in TestFlight or the simulator. 640×920 or larger works.
- **Review Notes:** `Open Settings (gear on Today) → Sova Plus to see the paywall. Restore Purchases is in Settings → Help.`

**Product IDs must match the app exactly:**
- `app.sova.plus.monthly`
- `app.sova.plus.yearly`
- `app.sova.plus.lifetime`

---

## 8. Business (once, before subscriptions can go live)
- **Agreements:** accept the **Paid Apps Agreement**.
- **Bank Account and Tax Forms:** fill these in. In-app purchases stay in "Missing Metadata" until this is done.

## 9. Before you press Submit
- [ ] Turn on GitHub Pages (repo Settings → Pages → `main` / `/docs`). Check that the privacy, terms and support links open.
- [ ] Replace `SUPPORT_EMAIL` in `docs/support.html`, and `supportEmail` in `Sova/Support/Links.swift`.
- [ ] If iCloud sync stays in 1.0: deploy the CloudKit schema to Production in the CloudKit Console.
- [ ] Test the build in TestFlight on your iPhone. Buy Plus with a Sandbox account (Settings → Developer → Sandbox Apple Account) and check that restore works.
