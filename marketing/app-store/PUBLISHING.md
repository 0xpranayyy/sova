# Publishing Sova 1.0 to the App Store

Work through these in order. Everything Sova needs inside the project is already done:
- privacy manifests
- export compliance
- an iPhone-only build
- entitlements and the StoreKit config
- the support and privacy pages
- listing copy and screenshots

## 1. Accounts (once)
- [ ] A **paid Apple Developer Program** membership ($99/year). iCloud, push notifications and in-app purchases don't work on a free team.
- [ ] Sign the **Paid Apps agreement** and add bank and tax details: App Store Connect → Business. Subscriptions can't go live without it.

## 2. Fill in two placeholders
- [ ] `Sova/Support/Links.swift` → set `supportEmail` to your real address.
- [ ] `docs/support.html` → replace every `SUPPORT_EMAIL` with the same address (the page and its Contact card).

## 3. Turn on the website (privacy + support pages)
- [ ] GitHub → repo **Settings → Pages** → Source: *Deploy from a branch* → `main` / `/docs` → Save.
- [ ] After about a minute, check that these load:
  - https://0xpranayyy.github.io/sova/privacy.html
  - https://0xpranayyy.github.io/sova/support.html
- GitHub Pages on a **private** repo needs a paid GitHub plan. If the repo is private on a free plan, make it public or host the two pages somewhere else, then update `Links.swift` and the URLs below.

## 4. Xcode
- [ ] Run `git pull origin main`, open `Sova.xcodeproj`.
- [ ] **Signing & Capabilities**: choose your Team for **Sova** and **SovaWidgetsExtension**. Leave "Automatically manage signing" on. Xcode registers:
  - the App Group `group.app.sova.Sova`
  - the iCloud container `iCloud.app.sova.Sova`
  - Push Notifications
- [ ] Run once on your iPhone. Turn on Plus with the StoreKit test config, turn on iCloud sync, reopen the app and add a task. This creates the iCloud schema.
- [ ] **CloudKit Console** (icloud.developer.apple.com) → container `iCloud.app.sova.Sova` → **Deploy Schema Changes to Production**. Without this step, sync won't work for customers.
- [ ] Product → **Archive** → Distribute App → **App Store Connect** → Upload.

## 5. App Store Connect → My Apps → New App
| Field | Value |
| --- | --- |
| Platform | iOS |
| Name | Sova: To-Do List & Habits |
| Primary language | English (U.S.) |
| Bundle ID | app.sova.Sova |
| SKU | sova-ios-1 |

## 6. In-app purchases (create before submitting)
**Subscriptions → create group "Sova Plus"**:

| Reference name | Product ID | Duration | Price (suggested) | Offer |
| --- | --- | --- | --- | --- |
| Sova Plus Monthly | `app.sova.plus.monthly` | 1 month | $3.99 / ₹199 | none |
| Sova Plus Yearly | `app.sova.plus.yearly` | 1 year | $24.99 / ₹999 | Introductory offer: free, 1 week |

**In-App Purchases → Non-Consumable**:

| Reference name | Product ID | Price (suggested) |
| --- | --- | --- |
| Sova Plus Lifetime | `app.sova.plus.lifetime` | $49.99 / ₹2,499 |

For each product:
- Add a display name ("Sova Plus") and a description ("Unlimited rituals and goals, iCloud sync and app icons").
- Add a **review screenshot**: a screenshot of the paywall. Open it from Settings → Sova Plus in the simulator.
- On the version page, under **In-App Purchases and Subscriptions**, attach all three products to version 1.0. They're reviewed together with the app.

## 7. App information
- **Category:** Productivity. **Secondary:** Lifestyle.
- **Age rating:** answer "None" to everything → **4+**.
- **Privacy Policy URL:** https://0xpranayyy.github.io/sova/privacy.html
- **Support URL:** https://0xpranayyy.github.io/sova/support.html
- **Marketing URL:** https://0xpranayyy.github.io/sova/ (the Sova website in `docs/index.html`)
- **License agreement:** keep Apple's standard EULA. Sova's own Terms of Use are at https://0xpranayyy.github.io/sova/terms.html
- **Copyright:** © 2026 0xpranayyy

## 8. App Privacy
- "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app.**
- The result shows "Data Not Collected". This matches the privacy manifest in the app.

## 9. Version 1.0 page
- **Screenshots (6.9" display):** upload `marketing/app-store/6.9-inch/1-hero.png` … `6-done.png` in order. App Store Connect scales them for smaller iPhones. The `6.7-inch` set is there if it asks.
- **App preview (optional):** `marketing/Sova-intro.mp4`. App Store previews have size and length rules, so trim it in iMovie or QuickTime if App Store Connect rejects it.
- **Promotional text, description, keywords, What's New:** copy from `DESCRIPTION.md`.
- **Build:** pick the uploaded build. Export compliance is already answered in the app (no non-exempt encryption).
- **Sign-in required:** No.

## 10. App Review notes (paste this)
```
Sova needs no account or sign-in. Everything works offline on the device.

Free plan: unlimited tasks, up to 5 rituals and 3 active goals.
Sova Plus (auto-renewable subscription, monthly or yearly with a 1-week
free trial, or a one-time lifetime purchase) unlocks unlimited rituals and
goals, iCloud sync and an alternate app icon.

To see the paywall: Settings (gear on Today) → Sova Plus, or try to add a
4th ritual on the Rituals tab. Restore Purchases is in Settings → Help and
on the paywall. Terms of Use (Apple standard EULA) and the Privacy Policy
are linked on the paywall and in the description.

Widgets: Today, Rituals (interactive) and Lock Screen widgets.
Siri: "Add a task in Sova".
```

## 11. Submit
- [ ] **Add for Review → Submit.**
- First reviews usually take 1–3 days. If App Review asks a question, reply in Resolution Center. Most first-time subscription rejections are about missing paywall information, and Sova's paywall already shows the price, length, trial terms and links.

## After approval
- Put the numeric **Apple ID** of the app (App Information page) into `Links.appStoreID` so "Rate Sova" opens the review page directly.
- Put the App Store link into `APP_STORE_URL` near the bottom of `docs/index.html`, so every "Download" button on the website goes to the App Store.
