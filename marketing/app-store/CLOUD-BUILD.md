# Ship Sova without a Mac: the cloud build

GitHub's Macs build Sova, Apple signs it in the cloud, and the build lands in TestFlight. You never touch certificates or provisioning profiles.

**What you do once:** about 20 minutes, in this order:
1. Unblock GitHub Actions
2. Register the identifiers
3. Create the app
4. Make an API key
5. Find your Team ID
6. Add four secrets

**Every release:** one click.

---

## 1. Unblock GitHub Actions

The test build hasn't been able to start. GitHub stops it before it begins, which almost always means an account issue.

1. Open **github.com/0xpranayyy/sova → Actions**.
2. Click the failed **Build** run. GitHub shows the reason in a yellow or red banner at the top.
3. Fix what it says. It's usually one of these:
   - **Billing:** GitHub → your avatar → **Settings → Billing and plans**. Add or update the payment method, or raise the Actions spending limit above $0. The repo is public, so standard Mac minutes are free, but a card must be on file.
   - **Verification:** confirm your email or phone if GitHub asks.
4. Back on the failed run, click **Re-run all jobs**. When the **Build** check turns green, the code compiles.

---

## 2. Register the identifiers (developer.apple.com)

Go to **Certificates, IDs & Profiles → Identifiers**. The exact values are in `LISTING-PACK.md` section 0. In short:

| Type | Identifier | Notes |
| --- | --- | --- |
| App Group | `group.app.sova.Sova` | |
| iCloud Container | `iCloud.app.sova.Sova` | |
| App ID | `app.sova.Sova` | Turn on **App Groups**, **iCloud (CloudKit)** and **Push Notifications**, and select the group and container above |
| App ID | `app.sova.Sova.Widgets` | Turn on **App Groups** and select the same group |

The cloud signing creates the certificates and profiles itself. These identifiers just need to exist.

---

## 3. Create the app (App Store Connect)

**appstoreconnect.apple.com → Apps → + → New App**, with the values from `LISTING-PACK.md` section 1:
- iOS
- Name: **Sova: To-Do List & Habits**
- Bundle ID: `app.sova.Sova`
- SKU: `sova-ios-1`

---

## 4. Make an App Store Connect API key

1. **App Store Connect → Users and Access → Integrations** tab → **App Store Connect API**.
2. The first time, the Account Holder clicks **Request Access** and accepts.
3. Under **Team Keys**, click **+ (Generate API Key)**:
   - **Name:** `GitHub cloud build`
   - **Access:** **Admin**. Admin is required so Apple can create the cloud-managed distribution certificate for you.
4. Click **Download API Key**. You get a file like `AuthKey_ABC123XYZ.p8`.
   - **You can download it only once.** Keep it somewhere safe, like your password manager.
5. On the same page, copy:
   - **Key ID:** the column next to your key, e.g. `ABC123XYZ`
   - **Issuer ID:** shown above the keys table, a long ID like `69a6de7e-…`

---

## 5. Find your Team ID

**developer.apple.com/account → Membership details → Team ID**. It's 10 characters, e.g. `A1B2C3D4E5`.

---

## 6. Add four secrets to GitHub

**github.com/0xpranayyy/sova → Settings → Secrets and variables → Actions → New repository secret.** Add each of these exactly:

| Name | Value |
| --- | --- |
| `ASC_KEY_ID` | The Key ID from step 4 |
| `ASC_ISSUER_ID` | The Issuer ID from step 4 |
| `APPLE_TEAM_ID` | The Team ID from step 5 |
| `ASC_KEY_P8` | The whole `.p8` file. Open it in a text editor and paste everything, including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines |

Secrets are encrypted. They never show in logs or to anyone who opens the repo.

---

## 7. Build and upload

1. **GitHub → Actions → TestFlight → Run workflow → Run workflow** (on `main`).
2. Wait about 15–25 minutes. A green check means the build was signed and uploaded. The run's summary shows the build number.
3. Apple then processes it for 10–30 minutes. You'll get an email when it's ready.

For later releases you can also push a tag instead of clicking, for example `v1.0.1`.

---

## 8. Test it on your iPhone (TestFlight)

1. **App Store Connect → Sova → TestFlight.** The build appears with its number.
   - **Export compliance:** already answered inside the app (`ITSAppUsesNonExemptEncryption = NO`), so it won't ask.
2. **Internal Testing → +** → create a group (e.g. "Team") → add yourself. Internal testers must be users in App Store Connect.
3. Install the **TestFlight** app on your iPhone, open the invite and install Sova.
4. Optional: **External Testing** for friends by email or public link. The first external build goes through a short Beta App Review (usually under a day).

**While testing:**
- Buy Sova Plus with a **Sandbox** account (iPhone **Settings → Developer → Sandbox Apple Account**). TestFlight purchases are free.
- Check that **Restore purchases** works.
- Try the widgets, Siri ("Add a task in Sova"), the notification buttons, and the Control Center button.

---

## 9. Submit for review

1. **App Store Connect → Sova → App Store → 1.0 Prepare for Submission.**
2. Fill in every field from `LISTING-PACK.md` section 5: screenshots, description, keywords, URLs, review notes and age rating.
3. Under **Build**, click **+** and pick the build you tested.
4. Add the three in-app purchases (section 6 and 7 of the listing pack) to this version.
5. **Add for Review → Submit.**
6. Choose **Manually release**, so you pick the launch moment after approval.

---

## Next releases

1. Tell me what goes into the update. I'll raise the version, e.g. `1.0` → `1.0.1`, in the project.
2. Run **TestFlight** again. Build numbers count up by themselves.
3. In App Store Connect: **+ Version**, fill in "What's New", pick the build, and submit.

---

## If a run fails

Open the failed step in the Actions log. The error is near the bottom.

| The log says | Fix |
| --- | --- |
| `Missing secret for …` | A secret from step 6 is missing or misspelled. Names must match exactly |
| `No Accounts` / `not authorized` / `Authentication failed` | The key, Key ID or Issuer ID don't match. Make a new key (step 4) and update all three secrets |
| `Cloud signing permission error` / can't create a certificate | The key isn't **Admin**. Make a new Admin key |
| `No profiles for 'app.sova.Sova.Widgets'` / `bundle identifier not available` | The App IDs from step 2 are missing, or the widget App ID lacks **App Groups** |
| `iCloud container` / `App Group` errors | Turn those capabilities on in the App ID and select the right group and container (step 2) |
| `The bundle version must be higher than the previously uploaded version` | Just run the workflow again; the build number goes up each run |
| `A required agreement is missing or has expired` | The Account Holder must accept the latest agreement under **App Store Connect → Business** |
| `Metal Toolchain` errors | Re-run; the workflow downloads it first |
| A Swift compile error | Send me the error text and I'll fix it |

---

# With a Mac: Xcode Cloud

Xcode Cloud is Apple's own build service, set up once from Xcode. Your membership includes **25 build hours a month**. A Sova archive takes about 20–30 minutes, so that's plenty.

The repo is already prepared:
- `Package.resolved` pins the wave package, because Xcode Cloud won't download packages without it.
- `ci_scripts/ci_post_clone.sh` installs the Metal Toolchain and gives every build a higher build number.

**Before you start:**
- Do steps 2 and 3 above (identifiers and the app record).
- In Xcode, add your Apple ID under **Xcode → Settings → Accounts**.
- Install the Metal Toolchain under **Xcode → Settings → Components**.

### 1. Open the project
1. In **Xcode → Integrate → Clone…**, paste `https://github.com/0xpranayyy/sova` and open **Sova.xcodeproj**.
2. Click the project, choose the **Sova** target → **Signing & Capabilities** → **Team**: your team, with **Automatically manage signing** on. Do the same for **SovaWidgetsExtension**.
3. Optional, but worth it: plug in your iPhone and press **Run (⌘R)** once to check that it builds and runs.

### 2. Create the workflow
1. Open the **Report navigator (⌘9) → Cloud** tab and click **Get Started**. You can also use **Integrate → Create Workflow…**.
2. Pick the product **Sova**. Xcode links it to your App Store Connect app automatically, using the bundle ID.
3. When it asks for access to the source code, click **Grant Access**. Your browser opens; install the **Xcode Cloud** GitHub app on `0xpranayyy/sova` and come back to Xcode.
4. On the workflow page, set:
   - **Name:** `TestFlight`
   - **Start Conditions:** delete the default condition and add **Manual Start** (saves build hours). If you'd rather build on every push, use **Branch Changes → main** instead.
   - **Environment:** Xcode **latest release** (26.x), macOS **latest**
   - **Actions:** delete the default **Build** action, then **+ → Archive**:
     - Platform: **iOS**
     - Deployment Preparation: **TestFlight and App Store**
   - **Post-Actions:** **+ → TestFlight Internal Testing**, then pick your tester group. Create one first in App Store Connect → TestFlight → **Internal Testing → +**.
5. Click **Save**.

### 3. Start a build
1. In the **Cloud** tab, right-click the **TestFlight** workflow → **Start Build** → branch **main**.
2. Watch it run in the **Cloud** tab. Errors open right in Xcode.
3. When it's green, the build appears in **App Store Connect → TestFlight**. Your internal testers get it in the TestFlight app automatically.

### 4. Submit
Follow step 9 above: fill in the 1.0 page, pick this build and submit.

### If Xcode Cloud fails
| It says | Fix |
| --- | --- |
| Package resolution / `Package.resolved` | Open the project on the Mac, let Xcode resolve packages, then commit and push the updated `Package.resolved` |
| Signing or provisioning errors | The identifiers from step 2 are missing, or a capability (App Groups, iCloud) isn't on the App ID |
| `Metal Toolchain` | Check that `ci_scripts/ci_post_clone.sh` is in the repo (it is) and run again |
| A Swift compile error | Screenshot it and send it to me |
