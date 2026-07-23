# Build: Black Queen Scorer — Flutter App

You are building a complete, production-ready Flutter app called **Black Queen Scorer**. Follow every instruction in this document precisely. When something is unspecified, apply professional judgment and state your assumption in a comment.

---

## 1. PROJECT OVERVIEW

**What it is:** A fast, offline-first score tracker for a bidding-based team card game (variant of Court Piece / Rang / 29). The app does NOT simulate card play — it only tracks scores across rounds within a session.

**Who it's for:** Groups of 4–12 friends playing in person. One person enters scores on their phone while everyone plays.

**The core loop:**
1. User starts a session with a list of players
2. After each round ends in real life, user taps "New Round"
3. User selects bidder, bidder's team, bid amount, won/lost — takes ≤ 10 seconds
4. Running leaderboard updates instantly
5. When game night ends, user taps "Finish" and gets a shareable summary

**Non-negotiable principles:**
- **Speed over features.** Every tap counts. The round entry flow must be completable in under 10 seconds.
- **Offline-first.** No auth, no cloud, no network calls in v1. Everything local.
- **Auto-save everything.** User should never lose data, ever. No "save" buttons.
- **Reversible actions.** Anything the user does can be undone or edited. No destructive confirmations mid-game.
- **Honest math.** Score calculations must be transparent and always correct.

---

## 2. THE GAME (SCORING RULES ONLY)

The app tracks rounds. Each round has:
- **Bidder**: one player
- **Bidder's team**: includes bidder, plus 0 or more teammates (user picks)
- **Opposition**: every other player in the session, automatically
- **Bid amount**: a positive integer (e.g., 700)
- **Result**: won or lost

### Scoring math — implement EXACTLY this:

Let `bid` = bid amount, `bonus` = session's bonus amount (0 if disabled).

**On WIN (bidder's team wins):**
- Every player on bidder's team: `score += bid`
- Every player on opposition: `score -= bid`
- Additionally, bidder alone: `score += bonus`

**On LOSS (bidder's team loses):**
- Every player on bidder's team: `score -= bid`
- Every player on opposition: `score += bid`
- Additionally, bidder alone: `score -= bonus`

**Important:** The bonus applies to the bidder ONLY. Teammates and opposition are NOT affected by the bonus. This means the scoring is NOT zero-sum when bonus > 0 — that is intentional and correct.

**Worked example:** Bid 700, bonus 100, bidder = A, team = [A, B], opposition = [C, D, E]. Team wins.
- A: +700 + 100 = **+800**
- B: **+700**
- C, D, E: **−700** each

Same setup, team loses:
- A: −700 − 100 = **−800**
- B: **−700**
- C, D, E: **+700** each

### Score is always computed from rounds, never stored

Total scores MUST be derived by iterating through `session.rounds` and applying the math above. Never store a player's total as a field. This guarantees that editing or deleting a round automatically propagates correct totals everywhere. Write a pure function `computeScores(session) -> Map<String, int>` and use it everywhere scores are displayed.

---

## 3. TECH STACK

**Use exactly these:**

| Concern | Package |
|---|---|
| Framework | Flutter 3.24+ (Material 3) |
| Language | Dart 3.3+ |
| State management | `flutter_riverpod` ^2.5.1 |
| Routing | `go_router` ^14.6.2 |
| Local storage | `hive` ^2.2.3 + `hive_flutter` ^1.1.0 |
| Path | `path_provider` ^2.1.4 |
| IDs | `uuid` ^4.5.1 |
| Share | `share_plus` ^10.1.2 |
| Screenshot | `screenshot` ^3.0.0 |
| Icons | `phosphor_flutter` ^2.1.0 |
| Date format | `intl` ^0.19.0 |
| Lints | `flutter_lints` ^5.0.0 |

**Do NOT add:** Firebase, any auth library, bloc, provider, get_it, mobx, any analytics SDK, ads, in-app purchases. Keep dependencies minimal.

**Hive adapters:** Use `TypeAdapter` classes written by hand (no `build_runner` / `hive_generator`). Simpler, faster, no codegen step.

---

## 4. FOLDER STRUCTURE

Create this structure exactly:

```
lib/
├── main.dart
├── app.dart                          # MaterialApp.router + theme wiring
├── core/
│   ├── theme/
│   │   ├── tokens.dart              # Spacing, Radii, Durations, AppColors
│   │   ├── app_theme.dart           # light() and dark() ThemeData
│   │   └── theme_controller.dart    # Riverpod controller for theme mode
│   ├── router/
│   │   └── app_router.dart          # go_router config
│   └── utils/
│       ├── formatters.dart          # number formatting, date formatting
│       └── haptics.dart             # thin wrapper over HapticFeedback
├── data/
│   ├── models/
│   │   ├── round.dart
│   │   ├── session.dart
│   │   ├── session_settings.dart    # bonusEnabled, bonusAmount
│   │   └── adapters.dart            # all hive TypeAdapters in one file
│   ├── storage/
│   │   ├── hive_boxes.dart          # box names as constants + opening logic
│   │   ├── session_repository.dart  # CRUD for sessions
│   │   └── players_repository.dart  # recent player names
│   └── providers.dart                # Riverpod providers for repos + active session
├── features/
│   ├── home/
│   │   └── home_screen.dart
│   ├── session_setup/
│   │   ├── session_setup_screen.dart
│   │   └── widgets/
│   │       ├── player_chip.dart
│   │       └── bonus_toggle.dart
│   ├── scoreboard/
│   │   ├── scoreboard_screen.dart
│   │   └── widgets/
│   │       ├── player_row.dart
│   │       ├── round_list.dart
│   │       └── round_tile.dart
│   ├── round_entry/
│   │   ├── round_entry_screen.dart
│   │   └── widgets/
│   │       ├── player_selector.dart
│   │       ├── bid_keypad.dart
│   │       └── result_toggle.dart
│   ├── summary/
│   │   ├── summary_screen.dart
│   │   └── widgets/
│   │       ├── podium.dart
│   │       ├── stats_card.dart
│   │       └── share_card.dart      # the renderable WhatsApp share image
│   └── history/
│       ├── history_screen.dart
│       └── session_detail_screen.dart
└── shared/
    └── widgets/
        ├── app_button.dart
        ├── app_scaffold.dart        # with safe area + consistent padding
        ├── empty_state.dart
        └── confirm_dialog.dart
```

---

## 5. DATA MODELS

Write plain Dart classes (no Freezed). Include `copyWith`, `toJson`, `fromJson`, `==`, `hashCode`.

### `Round`
```dart
class Round {
  final String id;                    // uuid v4
  final String bidder;                // player name
  final List<String> team;            // names; must include bidder
  final int bidAmount;                // >= 1
  final bool won;                     // true = bidder's team won
  final DateTime createdAt;
}
```

### `SessionSettings`
```dart
class SessionSettings {
  final bool bonusEnabled;
  final int bonusAmount;              // ignored if bonusEnabled == false
}
```

### `Session`
```dart
class Session {
  final String id;                    // uuid v4
  final DateTime startedAt;
  final DateTime? finishedAt;         // null while active
  final List<String> players;         // 4..12 names, unique
  final SessionSettings settings;
  final List<Round> rounds;
}

extension SessionX on Session {
  bool get isActive => finishedAt == null;
  Duration get duration => (finishedAt ?? DateTime.now()).difference(startedAt);
}
```

### Hive adapters
Write manual `TypeAdapter<T>` for Round, SessionSettings, Session. Use typeIds 1, 2, 3 respectively. Register all in `main()` before opening boxes.

---

## 6. SCORING ENGINE

Create `lib/data/scoring.dart`:

```dart
/// Computes each player's total score for a session.
/// Iterates all rounds and applies the scoring rules.
/// This is the single source of truth for scores. Never cache.
Map<String, int> computeScores(Session session) { ... }

/// Computes the score delta for a single round, per player.
/// Used for the undo snackbar and round tile display.
Map<String, int> computeRoundDelta(Round round, Session session) { ... }

/// Stats for the summary screen.
class SessionStats {
  final List<({String name, int score})> ranked;   // sorted desc
  final ({String name, int count})? mostBidsWon;
  final ({String name, int amount, int round})? biggestSingleGain;
  final ({String name, int amount, int round})? biggestSingleLoss;
  final ({String name, int streak})? longestWinStreak;   // consecutive rounds where player was on winning side
  final ({String name, double avg})? boldestBidder;      // highest avg bid when bidding
  final int totalRounds;
  final Duration totalDuration;
}

SessionStats computeStats(Session session) { ... }
```

Unit-test the scoring engine with the worked example above, plus:
- Empty session (no rounds) → all players at 0
- 1 round with bonus disabled
- 1 round with bonus enabled, team wins
- 1 round with bonus enabled, team loses
- Multi-round session where same player bids twice and loses once
- Stats: biggest gain/loss correctly identifies the round

---

## 7. STORAGE LAYER

### Hive boxes

```dart
class HiveBoxes {
  static const sessions = 'sessions';          // Map<String, Session> keyed by id
  static const recentPlayers = 'recent_players'; // List<String>
  static const settings = 'settings';           // Map: themeMode, lastBonus, etc.
}
```

Open all boxes in `main()` before `runApp`. Show a splash until open.

### `SessionRepository`
- `Stream<List<Session>> watchAll()` — all sessions, sorted newest first
- `Session? getActive()` — the single active session, if any (enforce only one active at a time)
- `Future<void> save(Session s)` — upsert
- `Future<void> delete(String id)`
- `Future<void> finish(String id)` — sets `finishedAt = now`

### `PlayersRepository`
- `List<String> getRecent()` — up to 50 most recent unique names
- `Future<void> addMany(Iterable<String> names)` — called when a session is finished; dedupe case-insensitively, preserve original casing of newest occurrence

---

## 8. THEME & DESIGN SYSTEM

### Design tokens (`tokens.dart`)

```dart
class Spacing { static const xs=4, sm=8, md=16, lg=24, xl=32, xxl=48; }
class Radii   { static const sm=8, md=12, lg=16, xl=24, pill=999; }
class Durations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
```

### Color palette

| Role | Light | Dark |
|---|---|---|
| Primary (card felt) | `#0F5132` | `#198754` |
| Accent (gold) | `#D4A017` | `#E8B931` |
| Surface | `#FAF7F2` (warm off-white) | `#0A1F1A` (midnight green) |
| Surface elevated | `#FFFFFF` | `#143028` |
| On-surface | `#1A1A1A` | `#F5F1EA` |
| Muted | `#6B6B6B` | `#A8A8A8` |
| Success (positive score) | `#2E7D32` | `#66BB6A` |
| Danger (negative score) | `#C62828` | `#EF5350` |

All color pairs must pass WCAG AA (4.5:1 for body text, 3:1 for large text). Verify with a simple contrast helper.

### Typography

Use **Google Fonts via assets** (bundle to avoid runtime fetch). Download to `assets/fonts/`:
- **Inter** (Regular, Medium, SemiBold, Bold) — UI
- **DM Sans** (Regular, Bold) — scores only, with `FontFeature.tabularFigures()`

If you cannot bundle fonts, use `google_fonts` package with `GoogleFonts.config.allowRuntimeFetching = false` and handle the fallback gracefully. Prefer bundled.

Type scale (Material 3 roles):
- displayLarge: 48/700/-0.5
- displayMedium: 36/700/-0.25
- headlineLarge: 28/700
- headlineMedium: 22/600
- titleLarge: 18/600
- titleMedium: 16/600
- bodyLarge: 16/400/1.5
- bodyMedium: 14/400/1.5
- labelLarge: 14/600

### Theme mode
Persist in Hive settings box. Options: `system` (default), `light`, `dark`. Expose via a Riverpod `StateNotifierProvider`.

---

## 9. ROUTING

Use `go_router`. Define these routes:

```
/                          → HomeScreen
/setup                     → SessionSetupScreen
/session/:id               → ScoreboardScreen
/session/:id/round/new     → RoundEntryScreen (new round)
/session/:id/round/:rid    → RoundEntryScreen (edit existing)
/session/:id/summary       → SummaryScreen
/history                   → HistoryScreen
/history/:id               → SessionDetailScreen (read-only scoreboard)
/settings                  → SettingsScreen (theme toggle, clear data)
```

Transitions: default platform transitions. Exception: Round Entry uses `CupertinoPageRoute` feel (slide from right) with a 250ms duration.

---

## 10. SCREEN-BY-SCREEN SPECIFICATION

### 10.1 Home Screen (`/`)

**Purpose:** Entry point. Get the user into a game fast.

**Layout (top to bottom):**
1. App title "Black Queen Scorer" (headlineLarge), subtitle "Fast scoring for card nights" (bodyMedium, muted).
2. **Resume card** — shown ONLY if an active session exists:
   - Card with emerald-tinted background
   - Shows player count, round count, time elapsed ("4 players · 6 rounds · 42 min")
   - Primary "Resume" button
   - Small text button "Discard session" (triggers confirm dialog)
3. **Primary CTA:** `[ + Start New Session ]` — filled button, full-width, large.
4. **Secondary actions** (outlined buttons, stacked):
   - `[ History ]` — disabled if zero finished sessions
   - `[ Settings ]`
5. Footer: small "v0.1.0" text, centered, muted.

**Interactions:**
- Starting a new session while one is active → confirm dialog "Discard current session?"
- Pull-to-refresh: no-op with light haptic (feels responsive)

**Empty state:** First launch — no "Resume" card, History button disabled.

### 10.2 Session Setup Screen (`/setup`)

**Purpose:** Configure the session in one screen. No wizards, no steps.

**App bar:** Back arrow, title "New Session".

**Layout:**

1. **Section: Players** (titleMedium "Players")
   - **Recent players list** (if any exist in storage):
     - Shown as a scrollable grid of tappable chips with checkboxes (tick mark when selected).
     - Each chip shows the player name and a circular avatar with the player's initial on a color derived from a hash of the name (for visual distinction).
     - Tapping a chip toggles selection. Selected chips have accent-gold border and filled background.
     - At top of list: "Tap to add to this session" (bodySmall, muted).
   - **Add new player** field below the list:
     - TextField with "+" icon suffix, placeholder "Add new player".
     - Submits on Enter or "+" tap. New names are added to the selection AND become available as chips.
     - Duplicate name (case-insensitive vs already selected) → snackbar "Already added".
   - **Selected count badge** just above the CTA: "6 players selected" (updates live).
   - Validation: must have 4–12 selected to proceed.

2. **Section: Bonus for bidder** (titleMedium)
   - Toggle switch: "Enable bonus" (default: off)
   - When ON, shows inline number field below: "Bonus amount" with default `100`. Min 1, max 9999.
   - Helper text (bodySmall, muted): "Bidder gets ±bonus on top of the bid."

3. **Section: Quick guide** (collapsible, closed by default)
   - Title: "How scoring works"
   - When expanded, shows the math in plain language with an example. Use a monospaced code-like block for the example numbers.

4. **CTA at bottom** (sticky above keyboard):
   - `[ Start Session ]` — filled, disabled until 4+ players selected.
   - On tap: create Session, persist, navigate to `/session/:id`.

**Keyboard handling:** Screen scrolls so active fields aren't hidden. Submitting the "add player" field keeps focus for rapid entry.

**Animation:** Chip selection has a subtle scale + color transition (150ms). Selected count badge cross-fades when number changes.

### 10.3 Scoreboard Screen (`/session/:id`)

**This is the main screen during play.** User will look at it most.

**App bar:**
- Title: "Round N" where N is the next round number (e.g., "Round 5")
- Subtitle (bodySmall, muted): player count and elapsed time ("6 players · 42 min")
- Action icons (right): settings icon (opens sheet with "Edit players", "Rename session", "Delete session"), finish-flag icon (opens Finish confirmation).

**Layout:**

1. **Leaderboard** (top, most prominent):
   - Sorted by score descending.
   - Each row shows: rank badge (1, 2, 3... with trophy icon for 1st in gold), avatar circle (initial), name, and score.
   - Score is rendered with DM Sans tabular figures, large (titleLarge), colored:
     - Positive: success color, prefix `+`
     - Negative: danger color, prefix `−` (use minus sign U+2212, not hyphen)
     - Zero: muted color, no prefix
   - Rank change animation: when scores update, rows animate to new positions with a 400ms ease curve. Use `AnimatedList` or `ImplicitlyAnimatedList`.
   - Row tap → bottom sheet showing that player's round-by-round delta history.

2. **Rounds list** (below leaderboard, collapsible header "Rounds (N)" with chevron):
   - Each round tile shows:
     - Round number (small, muted)
     - One-line summary: "Arvind & Nilay · bid 700 · Won" or "Kaka (alone) · bid 650 · Lost"
     - Delta preview on the right: `+700 / −700` for team/opp
     - Tap → navigates to round edit screen
     - Long-press → bottom sheet: "Edit round", "Delete round" (with confirm)
   - Most recent round at top.
   - Empty state: illustration + "No rounds yet — tap New Round to begin."

3. **Sticky bottom bar:**
   - Big primary button: `[ + New Round ]` — full-width minus padding, 64dp tall, emerald with gold underline accent on press. Haptic feedback medium-impact on press.
   - Secondary text button above: `Finish Session`

**Interactions:**
- After returning from a new round entry: show snackbar "Round N saved" with an "Undo" action, visible for 5 seconds. Undo removes the round.
- Auto-save: every round write persists immediately to Hive.
- If user backgrounds the app and returns, state restores exactly.

**Animation:**
- Leaderboard reorder: spring-like, 400ms
- Score delta: brief color pulse on the changed value (success green for gain, danger red for loss) lasting 600ms, then returns to steady state color.
- New round list tile: slides in from top with 250ms ease-out.

### 10.4 Round Entry Screen (`/session/:id/round/new` or `/:rid`)

**This is the "money" screen. Optimize ruthlessly for speed.**

**App bar:** Title "New Round" or "Edit Round N". Back arrow. Trash icon (edit mode only) → confirm → delete and pop.

**Layout:** Single scrollable column. NO pagination, NO wizard steps. All inputs visible at once.

**Section 1: Bidder** (required)
- Label: "Who bid?" (titleMedium)
- Horizontal wrap of player chips (all session players).
- Single-select; selected chip has accent-gold border + filled background.
- Tapping a chip gives light haptic.

**Section 2: Bidder's team** (required, at least bidder)
- Label: "Who's with the bidder?" (titleMedium). Sub-label (bodySmall, muted): "Tap to add teammates. The bidder is always on the team."
- Horizontal wrap of chips for all players EXCEPT the bidder.
- Multi-select. Bidder is NOT shown here (they're auto-included).
- If no bidder selected yet, this section is disabled (greyed, non-interactive, with helper "Pick a bidder first").
- Show current split as a subtitle: "Team: Arvind, Nilay  vs  Opposition: Nitin, Hitesh, Kaka" — live-updating.

**Section 3: Bid amount** (required, >= 1)
- Label: "Bid amount"
- Large display showing current value (displayMedium, tabular). Default empty showing placeholder "0".
- Below it: a **custom numeric keypad** (3×4 grid: 1 2 3 / 4 5 6 / 7 8 9 / 00 0 ⌫).
  - Buttons are 64dp tall, full width divided, generous tap targets.
  - Light haptic on each tap.
  - Ignore leading zeros. Cap at 5 digits (99999).
- Do NOT use the OS keyboard. The custom keypad is always visible, doesn't push content.

**Section 4: Result** (required)
- Label: "Result"
- Two huge side-by-side buttons, equal width, 72dp tall:
  - **Won** (left): success green background, white text, check icon
  - **Lost** (right): danger red background, white text, X icon
- Tapping either commits the round (if all other fields valid).

**Validation / commit flow:**
1. If any field missing when Won/Lost tapped → shake the missing section, haptic warning, no commit.
2. If all valid → success haptic (medium), save round, pop back to scoreboard. Show snackbar with undo.

**Edit mode differences:**
- Pre-populate all fields from the existing round.
- Changes apply immediately to all fields; commit happens on Won/Lost tap as usual.
- Additional "Save without changing result" button at bottom if only non-result fields changed.

**Keyboard:** Since we use a custom keypad, never show OS keyboard. No TextField for bid amount.

**Animation:**
- Chip select: 150ms scale + color
- Keypad key press: 100ms scale-down (0.95) then back
- Section shake on validation fail: 300ms horizontal shake
- Won/Lost press: 150ms scale-down, then screen pops with standard transition

### 10.5 Summary Screen (`/session/:id/summary`)

**Purpose:** Celebrate. Give shareable moment.

**App bar:** Title "Session Complete". Close (X) icon on right → confirm "Leave summary?" only if unshared, else just navigate home.

**Layout:**

1. **Hero banner:**
   - Subtle confetti animation for 2 seconds on mount (use `flutter_staggered_animations` or simple custom painter — keep it lightweight; no heavy lottie).
   - "🎉 Session Complete" (displayMedium)
   - Subtitle: "6 players · 8 rounds · 45 min"

2. **Podium** (top 3 if >= 3 players):
   - Custom illustrated podium with player names and scores.
   - 2nd place on left (silver), 1st center (gold, tallest), 3rd right (bronze).
   - Avatars on top of each pedestal.

3. **Full rankings list:**
   - All players, ranked. Same styling as scoreboard rows but finalized.

4. **Fun stats cards** (grid, 2 per row on phones):
   - 🎯 Most bids won: [Name] ([count])
   - 💰 Biggest single win: [Name] +[amount] (Round [N])
   - 💣 Biggest single loss: [Name] −[amount] (Round [N])
   - 🔥 Longest win streak: [Name] ([N] in a row)
   - 🎲 Boldest bidder: [Name] (avg bid [X])
   - If any stat has no data (e.g., no one bid), omit the card.

5. **CTAs:**
   - `[ 📤 Share ]` — primary. Uses `screenshot` package to render a dedicated `ShareCard` widget (styled differently from the screen — see below), then uses `share_plus` to share the PNG.
   - `[ 🏠 Back to Home ]` — outlined

**Share card design:**
- Off-screen widget. Rendered via `Screenshot` package.
- 1080×1350 (Instagram portrait). Uses brand colors, app logo at top, "Black Queen Scorer" wordmark, final rankings, total rounds, date, and a small "Shared from Black Queen Scorer" footer.
- Must look great in WhatsApp thumbnails (the top third matters most).

**On mount:** If session is not yet finished in storage, mark it finished (`finishedAt = now`) and persist recent player names.

### 10.6 History Screen (`/history`)

**Purpose:** Browse past sessions.

**App bar:** Title "History". Search icon (opens search field) [optional for v1 if time allows].

**Layout:**
- List of past sessions, newest first.
- Each item: date (relative: "Yesterday", "2 days ago", or absolute after 7 days), player count, round count, winner name + score.
- Tap → SessionDetailScreen (read-only scoreboard with rounds list, no editing).
- Swipe-to-delete (with confirm snackbar, 3s undo).
- Empty state: illustration + "No past sessions yet."

### 10.7 Session Detail Screen (`/history/:id`)

Identical to Scoreboard Screen BUT:
- No "New Round" button.
- No "Finish" action.
- Round tiles: tap does nothing (or shows read-only details). Long-press does nothing.
- App bar action: share icon (re-share the summary image), delete icon.

### 10.8 Settings Screen (`/settings`)

**Purpose:** Small, just essentials for v1.

**Sections:**
1. **Appearance**
   - Theme mode: segmented control (System / Light / Dark)
2. **Data**
   - "Clear recent players" (with confirm)
   - "Delete all history" (with double-confirm, typed "DELETE")
3. **About**
   - App version, "Made with ❤️ for card nights", tiny credits line.

---

## 11. ANIMATIONS — THE FULL LIST

Use `Durations.fast / base / slow` tokens. Default curve: `Curves.easeOutCubic`. Spring for reorder animations via `AnimatedSwitcher` or implicit animations.

| Animation | Duration | Curve |
|---|---|---|
| Chip select/deselect | 150ms | easeOut |
| Keypad press | 100ms | easeInOut |
| Button press (filled) | 150ms | easeOut |
| Screen route (default) | 250ms | Cupertino / platform |
| Round Entry route | 250ms | easeOutCubic slide from right |
| Leaderboard reorder | 400ms | easeOutCubic |
| Score delta pulse | 600ms total (200 in / 400 out) | easeInOut |
| Round tile insert | 250ms | easeOutCubic slide from top |
| Section shake (validation) | 300ms | custom: 4-cycle oscillation |
| Summary confetti | 2000ms one-shot | linear with custom painter |
| Resume-card fade in on Home | 400ms | easeOutCubic |

**Respect reduced motion:** Check `MediaQuery.disableAnimations`; if true, skip decorative animations (confetti, pulses, shake) and use instant transitions.

---

## 12. HAPTICS

Use `HapticFeedback`. Wrap in a `Haptics` utility:
- `selection()` — for chip taps, list selections
- `light()` — for keypad, minor confirmations
- `medium()` — for round commit, new session start
- `warning()` — for validation failure (use `HapticFeedback.vibrate()` with small pattern on Android, `mediumImpact()` on iOS)

Every meaningful action produces haptic feedback. Users often play with sound off.

---

## 13. ACCESSIBILITY

- All interactive elements: 48×48dp min hit area (iOS: 44pt).
- Add `Semantics` labels to icon-only buttons, avatars (speak the name).
- Support `MediaQuery.textScaler` — never hardcode overflow with `maxLines: 1` on critical text (use `FittedBox` or wrap).
- Color is never the sole indicator — Won/Lost also has icons and text. Score sign is both color AND prefix character.
- Contrast: verify every text-on-background combination passes 4.5:1 (body) or 3:1 (large text). Add a debug overlay in dev mode that flags violations [optional but recommended].
- Ensure keyboard navigation works for external keyboards.

---

## 14. ERROR & EDGE CASES

Handle all of these:

1. **Duplicate player names:** Case-insensitive dedupe at session creation. Snackbar feedback.
2. **Deleting the active round that's currently being edited:** Not possible — edit screen loads from storage; if round disappears, pop with toast "Round was deleted".
3. **Device back button on Round Entry:** Pops without saving; no confirm (user intent is clear). Edit mode: if fields are dirty, show confirm "Discard changes?"
4. **App killed mid-round entry:** Do NOT persist partial round state. Only completed rounds are saved. User must re-enter the round. This is acceptable because rounds are fast.
5. **Storage full / Hive write fails:** Show a blocking error dialog: "Couldn't save. Check storage space." Retry option.
6. **Session with 0 rounds when finishing:** Allow it. Summary shows "No rounds played" state, all scores are 0.
7. **Session with only losses for all teams:** Normal — scores are negative for some, positive for others. Math still works.
8. **Bid amount of 0:** Not allowed. Disable Won/Lost buttons if bid is 0 or empty.
9. **Orientation:** Lock to portrait in v1. Set in `AndroidManifest.xml` and `Info.plist`.

---

## 15. PERFORMANCE

- Use `const` constructors wherever possible.
- `ListView.builder` for rounds and history lists (never `ListView(children: ...)` for dynamic lists).
- `RepaintBoundary` around the Leaderboard list to isolate its repaints during score animations.
- Avoid rebuilding the whole Scoreboard when a single score changes — use `Consumer`/`select` patterns in Riverpod.
- No network calls in v1. No image downloads.
- Target: <30MB install size. Bundle only the font weights actually used.

---

## 16. TESTING

Write these tests at minimum:

**`test/scoring_test.dart`:**
- Empty session → all zeros
- Single round win, no bonus
- Single round win, with bonus (bidder gets extra, others don't)
- Single round loss, with bonus
- Multi-round where same player bids twice with different outcomes
- Stats: correctly picks biggest gain/loss and streak

**`test/models_test.dart`:**
- Round copyWith preserves id and createdAt
- Round.create ensures bidder is in team
- Session isActive reflects finishedAt correctly

**`test/scoring_edge_test.dart`:**
- All players on bidder's team (no opposition) → should be prevented by UI; if it happens, math still runs without divide-by-zero (we don't divide)
- Bid of 1, bid of 99999

Widget tests for Round Entry flow: pick bidder → pick team → enter bid → tap Won → assert round was added to session via a fake repository.

---

## 17. PLATFORM CONFIG

### Android
- `android/app/build.gradle`: `minSdkVersion 21`, `targetSdkVersion 34`
- Package name: `com.blackqueenscorer.app` (or `com.bytelane.blackqueenscorer` if branded under ByteLane)
- App icon: generate via `flutter_launcher_icons` with the emerald+gold "B" mark (placeholder OK; actual icon can come later)
- Adaptive icon background: emerald, foreground: gold "B"

### iOS
- `ios/Runner/Info.plist`: set `UISupportedInterfaceOrientations` to portrait only.
- Bundle identifier matches Android package.
- Launch screen: emerald background with gold "B" centered.

### Locked to portrait
```dart
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
]);
```

---

## 18. APP ENTRY POINT

`main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  // register adapters
  Hive.registerAdapter(RoundAdapter());
  Hive.registerAdapter(SessionSettingsAdapter());
  Hive.registerAdapter(SessionAdapter());
  // open boxes
  await Future.wait([
    Hive.openBox<Session>(HiveBoxes.sessions),
    Hive.openBox<List>(HiveBoxes.recentPlayers), // store as list under a known key
    Hive.openBox(HiveBoxes.settings),
  ]);

  runApp(const ProviderScope(child: BlackQueenScorerApp()));
}
```

`app.dart`:

```dart
class BlackQueenScorerApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'Black Queen Scorer',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## 19. COPYWRITING — USE THESE EXACT STRINGS

Put all user-facing strings in `lib/core/strings.dart` as constants. This makes future i18n trivial.

Key strings:
- App name: "Black Queen Scorer"
- Tagline: "Fast scoring for card nights"
- Primary CTA home: "Start New Session"
- Session setup CTA: "Start Session"
- Round entry CTA: "Won" / "Lost"
- Scoreboard CTA: "+ New Round"
- Finish confirm: "Finish this session?" body: "You can still view it in History, but no more rounds can be added."
- Discard confirm: "Discard this session?" body: "All rounds will be permanently lost."
- Validation: "Pick a bidder", "Enter a bid amount", "Pick Won or Lost"
- Success snack: "Round [N] saved" + "Undo" action
- Empty history: "No past sessions yet."
- Empty rounds: "No rounds yet — tap New Round to begin."

---

## 20. DELIVERY CHECKLIST

When the app is done, verify ALL of these:

- [ ] `flutter analyze` produces zero warnings
- [ ] `flutter test` passes every test
- [ ] App launches cleanly on Android emulator and iOS simulator
- [ ] First-run: can create session with 4 players, play 3 rounds, finish, see summary
- [ ] Mid-session app kill → relaunch → resume works with full state intact
- [ ] Round edit changes propagate to leaderboard correctly
- [ ] Round delete recalculates scores correctly
- [ ] Share button produces a valid PNG and opens share sheet
- [ ] Theme toggle works across all screens
- [ ] Light and dark mode both pass contrast checks
- [ ] Recent players appear on next session setup
- [ ] Haptics fire on all meaningful actions
- [ ] Reduced motion mode disables decorative animations
- [ ] No OS keyboard appears on bid entry (only custom keypad)
- [ ] App size under 30MB after release build (`flutter build apk --release --split-per-abi`)

---

## 21. WHAT'S EXPLICITLY OUT OF SCOPE FOR v1

Do NOT build these. They are v2+:
- Online accounts / sync / cloud backup
- Phone auth / OTP
- Multiple languages (English only)
- Card-play simulation (trump suits, partner-by-card, actual card dealing)
- Tournaments across sessions
- Groups / player profiles with photos
- Charts and trend analysis
- In-app purchases or ads
- Exporting to CSV/JSON
- Widgets or notifications

If a feature isn't in this document, it's not in v1. Period.

---

## 22. HOW TO PROCEED

1. Start by creating the folder structure in section 4.
2. Build data models (section 5) and scoring engine (section 6), and WRITE THE TESTS first. Get the math right before any UI.
3. Build the theme + design tokens (section 8).
4. Build the storage layer (section 7).
5. Build screens in this order:
   1. Home
   2. Session Setup
   3. Scoreboard (without rounds)
   4. Round Entry
   5. Scoreboard (with rounds and animations)
   6. Summary
   7. History + Session Detail
   8. Settings
6. Run through the Delivery Checklist.
7. Do a final pass on animations, haptics, and accessibility.

Ship when every box in section 20 is ticked.

---

Build this app. If you need to deviate from any instruction, add a comment explaining why. Prioritize correctness of scoring math above all else — a beautiful app with wrong math is useless.
