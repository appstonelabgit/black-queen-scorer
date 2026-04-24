# Submission worksheet — Black Queen Scorer

One file, one tab open while submitting. Paste from here into App Store Connect and the Play Console.

**Anything marked `🔒` is a secret — do not fill in this file. Store it in your password manager instead.**

---

## App identity (same for both stores)

| Field | Value |
|---|---|
| App name | Black Queen Scorer |
| Version | 1.2.0 |
| Build number | 1 (bump for every re-upload) |
| iOS bundle id | `com.blackqueenscorer.app` |
| Android application id | `com.blackqueenscorer.app` |
| Primary category | iOS: Utilities · Play: Apps → Tools |
| Age rating | 4+ (iOS) / Everyone (Play) |
| Price | Free |

## Live URLs

| Field | Value |
|---|---|
| Privacy Policy URL | https://appstonelabgit.github.io/black-queen-scorer/privacy.html |
| Marketing / Website URL | https://appstonelabgit.github.io/black-queen-scorer/ |
| Support email | dbvaghani@gmail.com |
| Source repo | https://github.com/appstonelabgit/black-queen-scorer |

---

## App Store Connect — paste-in fields

Source of truth: `store/metadata/app-store.md`. Quick reference below.

**Name** → `Black Queen Scorer`

**Subtitle** → `Fast offline card-night scorer`

**Promotional text** (editable anytime):
```
New: live-share your card night. Tap broadcast, friends watch the scoreboard update in real time via QR or link. Still the fastest scorer for Court Piece, Rang, 29.
```

**Keywords** (100 chars):
```
card,score,scorer,bid,court,piece,rang,29,partner,trump,kot,sar,tracker,leaderboard,live,offline
```

**Description**: copy full block from `store/metadata/app-store.md` § Description.

**What's New**: copy full block from `store/metadata/app-store.md` § What's New.

**Copyright**: `© 2026 AppStoneLab`

**Privacy answers** (corrected 2026-04-24 after Apple flagged the ATT disclosure; binary unchanged):
- Data collection: **Yes** — see § "App Privacy (1.1.0+)" below for the category-by-category answers.
- Tracking: **Yes** — Info.plist ships `NSUserTrackingUsageDescription` and `apsl_ads` (wrapping `google_mobile_ads`) triggers the ATT prompt. Users who grant ATT receive personalized ads via AdMob, which means Device ID and Product Interaction are "used to track you" per Apple's definition. Answer **Yes** for those two categories (see matrix below). If we later force `nonPersonalizedAds: true` and drop the ATT key, we can revert to No — track that decision as Path B in `docs/privacy.html`.
- Export compliance (non-exempt encryption): **No** — Info.plist has `ITSAppUsesNonExemptEncryption = false`; the app only uses HTTPS via standard OS/SDK libs.

## App Privacy (1.1.0+)

Apple's "Data Types" answers (corrected for 1.2.0 after ATT-disclosure review gate):

| Category | Collected? | Linked to you? | Used to track you? | Purposes |
|---|---|---|---|---|
| Identifiers → Device ID | Yes | No | **Yes** | Third-Party Advertising, Analytics |
| Usage Data → Product Interaction | Yes | No | **Yes** | Third-Party Advertising, Analytics |
| Diagnostics → Crash Data | Yes | No | No | App Functionality |
| Diagnostics → Performance Data | Yes | No | No | App Functionality |
| User Content → Other User Content (player names, scores, rounds — only when live-sharing) | Yes | No | No | App Functionality |

All other categories: **Not Collected**.

> Why Device ID + Product Interaction are marked "Used to track you": Apple defines tracking as linking user/device data collected from our app with data collected from other apps/sites for targeted advertising or measurement, or sharing that data with data brokers. AdMob with personalized ads (granted via the ATT prompt) does exactly that — it joins our Device ID / interaction signals with Google's cross-app graph. Crash, Performance, and live-session User Content are app-functionality only and stay on Google / Firebase's App-Functionality purpose path, so those rows remain No.

**Slots to fill in during submission** (don't put values here — just note them where the console shows them):

- [ ] Apple Developer Team ID: _(Membership → Team ID)_
- [ ] App Store Connect app record created
- [ ] Xcode signing working against Team
- [ ] PrivacyInfo.xcprivacy added to Copy Bundle Resources in Xcode
- [ ] Archive uploaded via Xcode Organizer
- [ ] Build selected for submission
- [ ] Screenshots uploaded (6 shots: Home / Scoreboard / Live share / Round entry / Summary / Lifetime — 6.9" required, 6.5" optional)
- [ ] Submitted for review

---

## Play Console — paste-in fields

Source of truth: `store/metadata/play-store.md`.

**App title** → `Black Queen Scorer`

**Short description** (80 chars):
```
Live-share your card night. Fast offline scorer for Court Piece, Rang, 29.
```

**Full description**: copy full block from `store/metadata/play-store.md`.

**What's new** (release notes, 500 chars):
```
1.2 — New: seating order locks the player layout you actually sit in, and a persistent banner lets you resume your active session in one tap after leaving the app. Plus faster toasts, one-tap share-the-app link, and fixes across history + summary.
```

**Data safety form** (set in 1.1.0; unchanged for 1.2.0):
- Data collected: **Yes**
  - Advertising or performance → **Advertising ID** (purpose: Advertising or marketing). Shared with Google AdMob.
  - App activity → **App interactions** (purpose: App functionality).
  - App info and performance → **Crash logs**, **Diagnostics** (purpose: App functionality).
  - Messages → **Other in-app messages** (player names/scores in live sessions). Purpose: App functionality. Optional: Yes (only when the user starts a live session).
- Data encrypted in transit: **Yes** (HTTPS).
- User can request deletion: **Yes** — "Settings → Data → Delete all history" plus uninstall clears the anonymous Firebase UID.

**Content rating**: answer **No** to every content question → result **Everyone**.

**Contains ads**: **Yes**.

**Uses advertising ID**: **Yes** (declaration required on API 33+).

**Target audience**: 13+.

**Slots to fill in during submission**:

- [ ] Google Play developer account created ($25 one-time)
- [ ] App created in Play Console
- [ ] `android/key.properties` configured locally
- [ ] AAB uploaded: `flutter build appbundle --release`
- [ ] Data safety form completed
- [ ] Content rating questionnaire completed
- [ ] Screenshots uploaded (6 shots: Home / Scoreboard / Live share / Round entry / Summary / Lifetime — 2 min, 8 max)
- [ ] Feature graphic uploaded (1024 × 500 PNG, headline "Live-share your card night." — see below)
- [ ] Internal testing track → Closed testing → Production

---

## Assets checklist

Where each asset lives and what size it needs to be.

### Icons (already generated)
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (all sizes)
- Android: `android/app/src/main/res/mipmap-*/` (all densities)

### Splash (already generated)
- iOS: `ios/Runner/Base.lproj/LaunchScreen.storyboard` + `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
- Android: `android/app/src/main/res/drawable-*/launch_background.xml`

### Screenshots (to be taken)
- iOS 6.9": 1290 × 2796, 3–10 shots → `store/screenshots/ios/6.9inch/`
- iOS 6.5": 1242 × 2688, optional → `store/screenshots/ios/6.5inch/`
- Android phone: 1080 × 2340 recommended, 2–8 shots → `store/screenshots/android/phone/`
- Shot list + captions: `store/screenshots/README.md`

### Play Store feature graphic (required)
- 1024 × 500 PNG
- Not generated yet. Easiest path: open [shots.so](https://shots.so) or Canva, drop in the icon on an emerald-to-gold gradient, add the text "Black Queen Scorer — Fast offline card-night scorer". Save as `store/screenshots/android/feature-graphic.png`.

### App Store preview (optional)
- 15–30 second video showing a round being entered. Skip for v1; add later if conversion needs help.

---

## 🔒 Secrets (store in password manager, NOT in this file)

Create a vault called **"Black Queen Scorer — Publishing"** and put these in it:

| Secret | Source |
|---|---|
| Apple Developer account (email + password + 2FA) | developer.apple.com |
| App Store Connect API key `.p8` + Key ID + Issuer ID | App Store Connect → Users and Access → Keys |
| Google Play Console login | play.google.com/console |
| Google Play service-account JSON | Play Console → API access (for future automation) |
| Android upload keystore `.jks` (attach file) | `keytool` output — back up in 2 places! |
| Android `storePassword` | The `keytool` prompt |
| Android `keyPassword` | The `keytool` prompt |
| Android `keyAlias` | `upload` (or whatever you chose) |

**Losing the Android keystore = can never ship a signed update.** Back it up to at least two places (password manager attachment + encrypted cloud file).

---

## Submission day — order of operations

1. Pull latest, run `flutter analyze && flutter test`. Both should be clean.
2. Bump `version:` in `pubspec.yaml` if needed and in `lib/core/strings.dart`.
3. Build artifacts:
   ```bash
   flutter build ipa --release
   flutter build appbundle --release
   ```
4. **iOS**: Open Xcode → Organizer → latest archive → Distribute → App Store Connect → Upload. Wait for "Processing" to finish (~10 min). Pick the build in ASC, fill in any remaining fields using this worksheet, submit for review.
5. **Android**: Play Console → your app → Production → Create new release → Upload `build/app/outputs/bundle/release/app-release.aab` → fill in release notes from this worksheet → roll out.
6. Tag the release in git:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

Done.
