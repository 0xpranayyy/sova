# Sova Plus: set up and test before you publish

Sova Plus is three products:
- a yearly subscription with a free week
- a monthly subscription
- a one-time lifetime purchase

They only work if App Store Connect is set up exactly right. Do the three parts below in order.

---

## Part A: App Store Connect setup

Products don't load at all, not even in TestFlight, until **all of this** is done.

**1. Business: Paid Apps Agreement** (App Store Connect → **Business**)
- [ ] **Paid Apps** agreement status is **Active**, not Pending
- [ ] Bank account added
- [ ] Tax forms done (W-8BEN if you're outside the US)

**2. Subscriptions** (App Store Connect → Sova → **Monetization → Subscriptions**)
- [ ] Subscription group **Sova Plus**, with an English localization: display name `Sova Plus`
- [ ] **Sova Plus Yearly**, product ID `app.sova.plus.yearly` (exactly):
  - 1 year, USD 24.99
  - **Introductory Offer: Free, 1 week**, all countries
  - localization: name + description
  - review screenshot + review note
- [ ] **Sova Plus Monthly**, product ID `app.sova.plus.monthly`:
  - 1 month, USD 3.99
  - localization, review screenshot + note
- [ ] Level order: **Yearly = level 1, Monthly = level 2**. Drag them in the group list.

**3. Lifetime** (App Store Connect → Sova → **Monetization → In-App Purchases → +**)
- [ ] **Non-Consumable**, product ID `app.sova.plus.lifetime`, USD 49.99
- [ ] localization, review screenshot + note

**4. Status:** all three show **Ready to Submit**. If one says *Missing Metadata*, open it; the missing field is marked.

**5. First submission:** on the **1.0** version page, under **In-App Purchases and Subscriptions**, add all three, so they're reviewed together with the app. Apple requires this for an app's first purchases.

The **review screenshot** is the same image for all three: the top of the paywall from your TestFlight build (Settings → Sova Plus), showing the three plans and the button.

---

## Part B: Test on your Mac first (no App Store Connect needed)

Xcode can fake the App Store using `Sova.storekit`, which is already attached to the Sova scheme.

1. Run Sova from Xcode on a simulator or on your iPhone.
2. In Xcode, open **Debug → StoreKit → Manage Transactions** to watch purchases and refund them.
3. Speed up renewals: open `Sova.storekit` → **Editor → Subscription Renewal Rate → Every 30 seconds** (or every minute).

Run each test and tick it off:

| # | Do this | You should see |
|---|---|---|
| 1 | Add a 6th ritual (Rituals → +) | The paywall opens: "You've got 5 rituals going!" |
| 2 | Add a 4th active goal | The paywall opens (goals) |
| 3 | Settings → turn on iCloud sync | The paywall opens (sync) |
| 4 | Settings → App icon → Sunny | The paywall opens (icons) |
| 5 | Paywall, first time | Without scrolling: the three plans with prices. **Yearly** is selected, with **1 week free** and **SAVE 47%**; the button says **Start my free week** |
| 6 | Tap **Start my free week** | Apple's sheet shows the free week. Celebration, paywall closes; Settings shows "Active". You can add a 6th ritual and turn on sync |
| 7 | Wait for the trial to end at the fast rate | Still Plus; the yearly plan renews |
| 8 | Manage Transactions → **Refund** the yearly purchase, then return to the app | Plus turns off, the Sunny icon switches back to Sova, and a 6th ritual is blocked again |
| 9 | Open the paywall again | No **1 week free** pill and no timeline (the trial is used up); the button says **Continue · $24.99/year** |
| 10 | Tap the **Monthly** card, then **Continue · $3.99/month** | Plus on |
| 11 | Tap the **Lifetime** card, then **Buy once · $49.99** | Plus on; Settings shows **"Lifetime. Thank you!"** and tapping it does nothing |
| 12 | Delete the app, reinstall, Settings → **Restore purchases** | Plus comes back |
| 13 | Turn on **Ask to Buy** (Debug → StoreKit → Ask to Buy), buy Monthly | Nothing unlocks yet. Approve it in Manage Transactions, and Plus turns on by itself |
| 14 | In the `Sova.storekit` file, choose **Editor → Fail Transactions**, then buy | An error, nothing unlocks, the app keeps working |
| 15 | Paywall: scroll to the bottom, tap **Privacy Policy** and **Terms of Use** | Privacy opens the Sova website; Terms opens Apple's standard terms |
| 16 | Turn on airplane mode, open the paywall | "Couldn't reach the App Store" with **Try again**; turn the network back on and tap it, and the plans load |
| 17 | Tap **Restore** at the top with no purchase | A "Nothing to restore" message |

---

## Part C: Test the real thing in TestFlight

This uses the real App Store Connect products from Part A. **TestFlight purchases are free**, and subscriptions renew on a sped-up schedule.

1. Install the build from TestFlight on your iPhone.
2. Run tests **5, 6, 11, 12 and 15** from Part B again.
3. If the paywall shows no plans, Part A isn't finished. The usual cause is that the **Paid Apps Agreement isn't Active yet**, or a product ID doesn't match exactly.

When Part C passes, Plus is ready for review.

---

## What the app already handles

- **StoreKit 2:** every purchase is checked and verified on the device, with no server needed.
- **Listening from launch:** renewals, refunds and Ask to Buy approvals arrive even while the app is closed. Every transaction is finished.
- **Entitlement check** on launch and every time the app comes back. This covers free trials, billing grace periods, upgrades and refunds.
- **Honest paywall:** the free-week timeline only shows to people who can still get the trial.
- **Restore Purchases** on the paywall and in Settings, plus Privacy and Terms links, all of which Apple requires.
- **When Plus ends:**
  - your extra rituals and goals stay, but you can't add new ones past the free limits
  - iCloud sync turns off at the next launch
  - the app icon switches back to the regular one
- **Trial reminder:** a notification 2 days before the free week ends, as the paywall promises.
