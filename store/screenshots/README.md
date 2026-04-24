# Screenshots — how to produce them

This is a two-step flow: populate the app with demo data, capture the screens, optionally frame them.

---

## 1. Populate the app with demo data

The app ships a debug-only **Settings → Developer → Seed demo data** button (only visible in `debug` / `profile` builds). Tapping it writes:

- 2 finished sessions with 3–4 rounds each (so History + Lifetime stats + Summary all look populated)
- 1 active session with 3 rounds (so Home's Resume card + Scoreboard are populated)
- 8 recent players (so Session Setup chips are populated)

One tap, and every screen has good content.

---

## 2. Take screenshots

### iOS — App Store sizes

Apple requires at least one screenshot at the **6.9″ iPhone** resolution. Optionally add 6.5″ for older-device listings.

| Device class | Simulator device | Required dimensions |
|---|---|---|
| 6.9″ iPhone | iPhone 17 Pro Max | **1290 × 2796** |
| 6.5″ iPhone (optional) | iPhone 11 Pro Max | 1242 × 2688 |

Steps:

```bash
# Launch on the right simulator
open -a Simulator
# Then: Hardware → Device → iOS → iPhone 17 Pro Max

flutter run --release
```

With the app open on the simulator, press **⌘+S** (File → Save Screen) — it saves a PNG of the simulator screen at the device's native resolution into `~/Desktop`. Rename as you go (e.g. `01_home.png`).

**Tip**: Toggle Appearance → Dark in the simulator (`⌘+Shift+A`) to match the app's dark theme for consistency with the hero screenshots.

### Android — Play Store sizes

Play accepts any portrait PNG between 320 and 3840 px wide, aspect ratio between 16:9 and 9:16. Recommended: **1080 × 2340** or **1440 × 3120**.

```bash
flutter run --release
# Use a Pixel 7 or Pixel 8 emulator

# From the emulator's floating toolbar: click the camera icon to save a screenshot.
# Or: adb exec-out screencap -p > 01_home.png
```

---

## 3. Shot list (recommended order for 1.2.0)

Take 6 screenshots. **Scoreboard leads** — it answers "what does this app do" in 0.5s. **Live-share is slot 2** so the differentiator lands before anyone scrolls off.

| # | Screen | How to reach it | Caption |
|---|---|---|---|
| 1 | **Scoreboard** (live, broadcast icon visible) | Home → Resume | *Live leaderboard. Zero spreadsheet.* |
| 2 | **Live share sheet** (QR + short code) | Scoreboard → tap broadcast icon | *Friends watch in real time. No app needed for viewers.* |
| 3 | **Round Entry** | Scoreboard → New Round, pick bidder + team + bid 700 | *Bidder, team, bid — under 10 seconds.* |
| 4 | **Summary** (finish) | Any session → Finish | *Finish with a shareable podium.* |
| 5 | **Home** (with resume banner) | Launch after seeding with an active session | *One tap, back in the game.* |
| 6 | **Lifetime stats** (History) | Home → History | *See who really owns the table.* |

Skip the session-setup form, history-list, and Settings screens for store screenshots — they're less visually distinctive.

Post-launch: A/B-test slots 1 and 2 in reverse via ASC Product Page Optimization. Hypothesis = live-share hero beats generic leaderboard hero.

**Live-share capture note**: use a fake demo code matching the real format (e.g. `ABCD-2345`), not a real session code. Either end the real session before shooting or substitute the code in post. Code alphabet is `2-9 A-H J-N P-Z` (no `0/O/1/I/L`), grouped 4-4 with a dash — see `lib/core/live/live_code.dart`.

---

## 4. Framing + captions (the polish step)

Raw simulator screenshots are fine but plain device-framed mockups with a single-line caption above convert far better. Three easy options:

### Option A — Previewed (fastest, browser-based, free)

1. Go to <https://previewed.app>.
2. Drag in your raw 1290×2796 PNG.
3. Choose "iPhone 15 Pro Max" frame. Add a caption like **"Enter a round in under 10 seconds."** in brand gold (`#E8B931`) on the emerald background.
4. Export at 1290×2796.

### Option B — shots.so (beautiful gradients)

<https://shots.so> — same flow, more colourful background options. Good for the hero screenshot.

### Option C — fastlane frameit (for a repeatable pipeline)

If you want one command to (re)produce all framed screenshots whenever the UI changes, set up fastlane in `ios/` and `android/` with `frameit`. Worth it only if you expect frequent store refreshes.

---

## 5. Caption copy (ready to use)

Short, scannable one-liners calibrated for App Store screenshot text:

1. **Scoreboard** — *"Live leaderboard. Zero spreadsheet."*
2. **Live share** — *"Friends watch in real time. No app needed for viewers."*
3. **Round Entry** — *"Bidder, team, bid — under 10 seconds."*
4. **Summary** — *"Finish with a shareable podium."*
5. **Home** — *"One tap, back in the game."*
6. **Lifetime stats** — *"See who really owns the table."*

---

## 6. Export and upload

Organize final assets as:

```
store/screenshots/
├── ios/
│   ├── 6.9inch/
│   │   ├── 01_scoreboard.png
│   │   ├── 02_live_share.png
│   │   ├── 03_round_entry.png
│   │   ├── 04_summary.png
│   │   ├── 05_home.png
│   │   └── 06_lifetime_stats.png
│   └── 6.5inch/
│       └── ... (optional)
└── android/
    └── phone/
        ├── 01_scoreboard.png
        └── ...
```

> v1.2.0 reorder vs 1.1.0: Scoreboard promoted to slot 1 (was slot 2), Live-share slot 2 (was slot 3), Home demoted to slot 5 (was slot 1). Rationale: scoreboard answers "what is this" fastest; live-share is the differentiator and needs top-of-list surface area.

Upload via App Store Connect → **App Store → iOS App → Screenshots** and Play Console → **Main store listing → Graphics**.
