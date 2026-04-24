# Play Console — Black Queen Scorer

Copy these fields directly into the Play Console when you create or update the app.

Source of truth for 1.2.0. Data safety answers live in `store/SUBMISSION.md` § "Play Console — paste-in fields" — unchanged for 1.2.0.

---

## Store listing

| Field | Value |
|---|---|
| App name | Black Queen Scorer |
| Short description (80 chars) | Live-share your card night. Fast offline scorer for Court Piece, Rang, 29. |
| Category | Apps → Tools |
| Tags | Utilities, Productivity, Offline |
| Contact email | dbvaghani@gmail.com |
| Website | https://appstonelabgit.github.io/black-queen-scorer/ |
| Privacy policy | https://appstonelabgit.github.io/black-queen-scorer/privacy.html |

## Full description (max 4000 chars)

```
Black Queen Scorer — fast offline scorer for Court Piece, Rang, 29, and Partner 29. Now with live-share: friends watch your scoreboard update in real time.

Tracks scores across rounds for team card games like Court Piece, Rang, 29, Partner 29, and similar bidding variants. Built for the friend who always ends up keeping score — so the game never has to pause.

NEW IN THIS RELEASE

• Live share your scoreboard. Tap the broadcast icon on any session. A QR code and short code appear. Friends open the link or scan the QR and watch every round land in real time. No sign-up, and viewers don't need the app — it works in any browser.

• Seating order. Lock the player order you actually sit in around the table. Scoreboard and round entry follow it, so "bidder + left + right" always matches the room.

• Persistent session banner. Leave the app, take a call, answer a text. Come back and one tap resumes your active session. No lost rounds.

• Share the app. One tap sends a friend the download link when they ask what scorer you're using.

KEY FEATURES

• Start a session in seconds. Add 4 to 12 players with one tap each. Names from past sessions are remembered.

• Enter a round in under 10 seconds. Pick the bidder, tap teammates, enter the bid on a custom keypad, tap Won or Lost.

• Always-correct math. Scores recompute from scratch after every edit or delete — no stale totals.

• Optional bidder bonus. Configure a ±bonus that applies only to the bidder. Fully transparent.

• Live leaderboard. Rows reorder smoothly as scores change. Score pulses green on gain, red on loss.

• Round history. Every round tile shows bidder, bid, and result. Edit or delete any round — the leaderboard recalculates instantly.

• Celebratory finish. Podium, fun stats (biggest single win, boldest bidder, longest streak), shareable WhatsApp-friendly summary card.

• Lifetime stats. Top winner, top earner, cold streak, most bids won — tracked across every session you play.

WHO IT'S FOR

Groups of 4 to 12 friends playing in person. One person enters scores while everyone else plays.

SUPPORTED GAMES

Any bidding-based team card game where one player bids an amount, a team tries to win that bid, and opposition wins if the team fails. Works well for Court Piece, Rang (Trump), 29, Partner 29, Black Queen, and many regional variants.

ALSO KNOWN AS

Court Piece is also called Rang, Rung, Trump, Kot Piece, or Sar Bazi in South Asia. 29 is played as Partner 29 or 29 Card Game in Kerala and Nova Scotia.

PRIVACY

Scoring and history stay on your device. Live sharing is opt-in per session — when you tap broadcast, player names, scores, and round results sync to a temporary session that anyone with the code can watch. End the session from Settings to delete it. Ads are served by Google AdMob and may use your advertising ID for frequency capping; opt out of personalized ads from Android system settings → Google → Ads. No account, no cross-app tracking.

Made for card nights.
```

## What's new (release notes for 1.2.0, max 500 chars)

```
1.2 — New: seating order locks the player layout you actually sit in, and a persistent banner lets you resume your active session in one tap after leaving the app. Plus faster toasts, one-tap share-the-app link, and fixes across history + summary.
```

---

## Data safety form (1.2.0)

Unchanged from 1.1.0. See `store/SUBMISSION.md` § "Data safety form (1.1.0)" for the full matrix. Summary:

- **Data collected**: Yes.
  - Advertising or performance → **Advertising ID** (purpose: Advertising or marketing). Shared with Google AdMob.
  - App activity → **App interactions** (purpose: App functionality).
  - App info and performance → **Crash logs**, **Diagnostics** (purpose: App functionality).
  - Messages → **Other in-app messages** (player names / scores in live sessions). Purpose: App functionality. Optional: Yes (only when a live session is started).
- **Data encrypted in transit**: Yes (HTTPS).
- **User can request deletion**: Yes — "Settings → Data → Delete all history" plus uninstall clears the anonymous Firebase UID.

## Content rating

Use the Play Console's questionnaire:
- Violence: None
- Sexual content: None
- Profanity: None
- Controlled substances: None
- Gambling: **None** (scoring a bidding card game does not count as gambling — no real-money stakes, no wagers, no simulated gambling)
- User-generated content: **Yes, but shared privately** — live sessions can show player names entered by the user; only visible to people holding the session code.

Result: **Everyone**.

## Target audience and content

- Age range: **13+** (simpler approvals; the app is safe for all ages but 13+ avoids additional COPPA flows)
- Is your app designed specifically for children? **No**

## Ads

- Contains ads: **Yes** (Google AdMob).
- Uses advertising ID: **Yes** (declaration required on API 33+).

## App access

- All functionality available without any restricted access: **Yes**.

---

## Screenshots required (phone)

| Orientation | Resolution | Count |
|---|---|---|
| Portrait | 1080 × 2340 recommended (min 320, max 3840) | 2 minimum, 8 maximum |

Target order for 1.2.0 (6 shots — scoreboard leads; live-share differentiates in slot 2):

1. **Scoreboard** with broadcast icon visible
2. **Live share sheet** (QR + demo code `ABCD-2345`) — hero differentiator
3. Round entry mid-bid
4. Summary podium
5. Home with active-session resume banner
6. Lifetime stats

Feature graphic (1024 × 500 PNG) still required — see `store/SUBMISSION.md` § "Play Store feature graphic". Proposed headline: **"Live-share your card night."**

See `store/screenshots/README.md` for the capture recipe.
