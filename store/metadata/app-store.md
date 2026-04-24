# App Store Connect — Black Queen Scorer

Copy these fields directly into App Store Connect when you create or update the app record.

Source of truth for 1.2.0. Privacy answers live in `store/SUBMISSION.md` § "App Privacy (1.1.0)" — unchanged for 1.2.0.

---

## App Information

| Field | Value |
|---|---|
| Name | Black Queen Scorer |
| Subtitle | Fast offline card-night scorer |
| Primary category | Utilities |
| Subcategory | — |
| Content rights | Does not use third-party content |
| Age rating | 4+ (no objectionable content) |

---

## Pricing and Availability

- **Price tier**: Free.
- **Availability**: All territories.

---

## App Privacy

See `store/SUBMISSION.md` § "App Privacy (1.1.0)" for the full data-type matrix. Summary:

- **Data collected**: Yes — Device ID (ads, analytics), Product Interaction (analytics), Crash + Performance Diagnostics, and player names/scores only when a live session is active.
- **Data linked to user**: No.
- **Data used to track**: No. AdMob initializes with `nonPersonalizedAds: true`; ATT prompt is used for personalization only.

## Export Compliance

- `ITSAppUsesNonExemptEncryption = false` in Info.plist.
- Question: *"Does your app use non-exempt encryption?"* → **No** (HTTPS via standard OS/SDK libs only).

---

## Version metadata (fill per release)

**Promotional text** (max 170 chars — shown above the description, editable without re-submission):

```
New: live-share your card night. Tap broadcast, friends watch the scoreboard update in real time via QR or link. Still the fastest scorer for Court Piece, Rang, 29.
```

**Keywords** (max 100 chars, comma-separated, no spaces around commas):

```
card,score,scorer,bid,court,piece,rang,29,partner,trump,kot,sar,tracker,leaderboard,live,offline
```

> Swap candidates before committing: verify `kot` / `sar` volume in Sensor Tower or AppTweak. If unclear, revert to `card,score,scorer,bid,court,piece,rang,tracker,offline,29,partner,night,game,team,leaderboard`.

**Description** (max 4000 chars):

```
The fastest scorer for bidding card games — now with live sharing.

Black Queen Scorer tracks scores across rounds for team card games like Court Piece, Rang, 29, and similar bidding variants. Built for the one friend who always ends up keeping score — so the game never has to pause.

NEW IN 1.2

• Live share your scoreboard
  Tap the broadcast icon on any session. A QR code and short code appear. Friends open the link or scan the QR and watch every round land in real time. No sign-up. No app install required for viewers — it works in any browser.

• Seating order
  Lock the player order you actually sit in around the table. Scoreboard and round entry follow it, so "bidder + left + right" always matches the room.

• Persistent session banner
  Leave the app, take a call, answer a text. Come back and one tap resumes your active session. No lost rounds.

• Share the app
  One tap sends a friend the download link when they ask "what scorer are you using?".

KEY FEATURES

• Start a session in seconds — 4 to 12 players, names remembered from past sessions.
• Enter a round in under 10 seconds — pick bidder, tap team, enter bid on a custom keypad, tap Won or Lost.
• Always-correct math — scores recompute from scratch after every edit or delete.
• Optional bidder bonus — configure a ±bonus that applies only to the bidder.
• Live leaderboard — rows reorder smoothly; scores pulse green on gain, red on loss.
• Round history — edit or delete any round, leaderboard recalculates instantly.
• Celebratory finish — podium, fun stats (biggest single win, boldest bidder, longest streak), shareable summary card.
• Lifetime stats — top winner, top earner, cold streak, most bids won across every session you play.

WHO IT'S FOR

Groups of 4 to 12 friends playing in person. One person enters scores while everyone else plays.

SUPPORTED GAMES

Any bidding-based team card game: one player bids, a team tries to make the bid, opposition wins if they fail. Court Piece, Rang (Trump), 29, Partner 29, Black Queen, and regional variants.

PRIVACY

Scoring and history stay on your device. Live sharing is opt-in per session — when you tap broadcast, player names, scores, and round results sync to a temporary session that anyone with the code can watch. End the session from Settings to delete it. AdMob shows ads and may use a device identifier for frequency capping; you can opt out of personalized ads from your system settings. No account, no cross-app tracking.

Made for card nights.
```

**What's New in this version** (release notes, max 4000 chars):

```
• Seating order — lock the player order that matches your table layout. Scoreboard, round entry, and history all follow it.
• Persistent session banner — resume an active session in one tap after leaving the app.
• Share the app — one-tap share link for friends who ask what scorer you're using.
• Polish — smoother toasts, cleaner round-entry flow, bug fixes across history and summary.
```

**Support URL** (required): `https://github.com/appstonelabgit/black-queen-scorer/issues`

**Marketing URL** (optional): `https://appstonelabgit.github.io/black-queen-scorer/`

**Copyright**: `© 2026 AppStoneLab`

---

## Screenshots required (iPhone only, portrait)

| Device | Resolution | Count |
|---|---|---|
| 6.9" iPhone (16/17 Pro Max) | 1290 × 2796 | 3–10 |
| 6.5" iPhone (11 Pro Max / XS Max) | 1242 × 2688 | 3–10 (optional — Apple auto-generates from 6.9" if missing but quality drops) |

Target order for 1.2.0 (6 shots — live-share shot is the new hero):

1. Home with active-session resume banner
2. Scoreboard with broadcast icon visible
3. **Live share sheet** (QR + demo code `ABCD-2345`) — new
4. Round entry mid-bid
5. Summary podium
6. Lifetime stats

See `store/screenshots/README.md` for the capture recipe.
