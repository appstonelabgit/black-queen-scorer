# Publishing Black Queen Scorer

This guide walks through shipping v1.0.0 to the App Store and Play Store.

---

## App identity

| | Value |
|---|---|
| App name | Black Queen Scorer |
| iOS bundle id | `com.blackqueenscorer.app` |
| Android application id | `com.blackqueenscorer.app` |
| Version | `1.0.0` |
| Build number | `1` |

Bump `version: X.Y.Z+N` in `pubspec.yaml` for every release:
- `X.Y.Z` is the public version (maps to `CFBundleShortVersionString` / `versionName`).
- `+N` is the **build number** — must strictly increase every upload to TestFlight / Play Internal. App Store Connect rejects re-uploads of the same build number even for internal testers.

---

## Regenerating branding assets

The app icon and splash images are painted programmatically from `tool/generate_icon_test.dart`, so you never have to open a design tool.

```bash
# 1. Paint the master PNGs into assets/icon/
flutter test tool/generate_icon_test.dart

# 2. Generate per-platform icons (iOS AppIcon.appiconset + Android mipmaps)
dart run flutter_launcher_icons

# 3. Generate the native splash screens (LaunchScreen.storyboard + Android 12 splash XML)
dart run flutter_native_splash:create
```

If you tweak colors or the crest shape, just re-run these three commands and rebuild — no other edits needed.

---

## iOS (App Store)

### 1. Add the Privacy manifest to Xcode

The repo already contains `ios/Runner/PrivacyInfo.xcprivacy`, but it must also be referenced from the Xcode project. Open `ios/Runner.xcworkspace` in Xcode, then:

1. Right-click the `Runner` group in the project navigator → **Add Files to "Runner"…**
2. Select `ios/Runner/PrivacyInfo.xcprivacy`.
3. In the dialog that appears, tick only the **Runner** target under "Add to targets".

Verify by opening the **Build Phases → Copy Bundle Resources** list and confirming `PrivacyInfo.xcprivacy` is present.

### 2. Signing

In Xcode → `Runner` target → **Signing & Capabilities**:

- Team: select your Apple Developer team.
- Bundle identifier: `com.blackqueenscorer.app` (already set).
- Leave "Automatically manage signing" on for TestFlight. For App Store distribution you can switch to manual and pick an "Apple Distribution" certificate + matching provisioning profile.

### 3. Archive

```bash
flutter build ipa --release
```

Or from Xcode: **Product → Archive** → **Distribute App → App Store Connect → Upload**.

### 4. App Store Connect metadata

- Category: **Games → Card**
- Age rating: 4+
- Privacy:
  - Data collection: **No data collected** (everything lives in local Hive storage).
  - Tracking: None.
- Export compliance: Uses only standard encryption (HTTPS is not used; answer **No** to "does your app use non-exempt encryption").

Screenshots required:
- 6.9″ (iPhone 17 Pro Max): 1290×2796
- 6.5″ (iPhone 11 Pro Max / XS Max): 1242×2688

Suggested flow to screenshot: Home → Session Setup → Scoreboard → Round Entry → Summary.

---

## Android (Play Store)

### 1. Create an upload keystore (once)

```bash
keytool -genkey -v -keystore ~/black-queen-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Keep the `.jks` file and the passwords somewhere safe — losing them means you can never ship a signed update.

### 2. Point Gradle at the keystore

Copy the template and fill it in:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` to set `storePassword`, `keyPassword`, `keyAlias` (`upload`), and the absolute `storeFile` path. The file is already in `.gitignore` — **never commit it**.

With `key.properties` present, `android/app/build.gradle.kts` automatically wires the `release` signing config. Without it, release builds fall back to the debug keystore (fine for local testing, not for the Play Store).

### 3. Build the App Bundle

Play Store uploads require an AAB:

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Install size sanity check (should be under 30 MB installed):

```bash
flutter build apk --release --split-per-abi
ls -lh build/app/outputs/flutter-apk/
```

### 4. Play Console metadata

- Category: **Games → Card**
- Content rating: Everyone (no ads, no violence, no gambling — tracks scores only).
- Data safety:
  - Data collection: **None**
  - Data sharing: **None**
  - Data encrypted in transit: **N/A, no network traffic**
  - Users can request data deletion: **N/A, all data is local; "Delete all history" in Settings clears everything.**
- Target API level: 34 (already set).

---

## Store listing copy

**Short description (80 char max):**
> Fast offline scorer for bidding card games. No signup, no ads, no cloud.

**Full description:**
> Black Queen Scorer is a fast, offline score tracker for bidding-based team card games (Court Piece, Rang, 29, and similar variants). Designed so the scorekeeper never holds up the game:
>
> • Start a session with 4–12 players in seconds
> • Enter a round — bidder, team, bid, result — in under 10 seconds
> • Optional bidder bonus, fully transparent math
> • Live leaderboard with trophy badge and score-change pulse
> • Rounds history, edit any round, auto-recalculated totals
> • Finish-screen podium, fun stats, and WhatsApp-friendly share card
> • Lifetime stats across all your sessions
> • 100% offline — no account, no ads, no cloud sync, no tracking
>
> Built for in-person card nights.

---

## Pre-submission checklist

- [ ] `flutter analyze` clean
- [ ] `flutter test` all green
- [ ] `flutter build appbundle --release` succeeds
- [ ] `flutter build ipa --release` succeeds
- [ ] Install size < 30 MB (`flutter build apk --release --split-per-abi`)
- [ ] Icon and splash render correctly on device (not just simulator)
- [ ] Cold-launch → splash → Home works on iOS and Android
- [ ] Share button produces a valid PNG and opens the share sheet
- [ ] Theme toggle persists across app restart
- [ ] PrivacyInfo.xcprivacy is in Copy Bundle Resources (Xcode)
- [ ] `android/key.properties` configured locally, AAB signs correctly
- [ ] Version in `pubspec.yaml` and `lib/core/strings.dart` match
