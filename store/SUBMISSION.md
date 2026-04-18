# Submission worksheet — Black Queen Scorer

One file, one tab open while submitting. Paste from here into App Store Connect and the Play Console.

**Anything marked `🔒` is a secret — do not fill in this file. Store it in your password manager instead.**

---

## App identity (same for both stores)

| Field | Value |
|---|---|
| App name | Black Queen Scorer |
| Version | 1.0.0 |
| Build number | 1 (bump for every re-upload) |
| iOS bundle id | `com.blackqueenscorer.app` |
| Android application id | `com.blackqueenscorer.app` |
| Primary category | Games → Card |
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
Track scores for bidding card games in seconds. Court Piece, Rang, 29, and more. Offline, private, no ads.
```

**Keywords** (100 chars):
```
card,score,scorer,bid,court,piece,rang,tracker,offline,29,partner,night,game,team,leaderboard
```

**Description**: copy full block from `store/metadata/app-store.md` § Description.

**What's New**: copy full block from `store/metadata/app-store.md` § What's New.

**Copyright**: `© 2026 AppStoneLab`

**Privacy answers**:
- Data collection: **No data collected**
- Tracking: **None**
- Export compliance (non-exempt encryption): **No** (no network traffic)

**Slots to fill in during submission** (don't put values here — just note them where the console shows them):

- [ ] Apple Developer Team ID: _(Membership → Team ID)_
- [ ] App Store Connect app record created
- [ ] Xcode signing working against Team
- [ ] PrivacyInfo.xcprivacy added to Copy Bundle Resources in Xcode
- [ ] Archive uploaded via Xcode Organizer
- [ ] Build selected for submission
- [ ] Screenshots uploaded (6.9" required, 6.5" optional)
- [ ] Submitted for review

---

## Play Console — paste-in fields

Source of truth: `store/metadata/play-store.md`.

**App title** → `Black Queen Scorer`

**Short description** (80 chars):
```
Fast offline scorer for Court Piece, Rang, 29 and other bidding card games.
```

**Full description**: copy full block from `store/metadata/play-store.md`.

**What's new** (release notes, 500 chars):
```
Welcome to Black Queen Scorer 1.0! Fast round entry, live leaderboard, edit any round, WhatsApp-share summary, lifetime stats across sessions, fully offline. No account, no tracking, no ads.
```

**Data safety form**: all **No**. See `store/metadata/play-store.md` § Data safety form.

**Content rating**: answer **No** to every content question → result **Everyone**.

**Contains ads**: **No**.

**Target audience**: 13+ (safest).

**Slots to fill in during submission**:

- [ ] Google Play developer account created ($25 one-time)
- [ ] App created in Play Console
- [ ] `android/key.properties` configured locally
- [ ] AAB uploaded: `flutter build appbundle --release`
- [ ] Data safety form completed
- [ ] Content rating questionnaire completed
- [ ] Screenshots uploaded (2 minimum, 8 max)
- [ ] Feature graphic uploaded (1024 × 500 PNG — see below)
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
