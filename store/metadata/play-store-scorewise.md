# Play Console — ScoreWise (v1.2.1, build 8)

Current source of truth. Supersedes `play-store.md` (old "Black Queen Scorer" branding, 1.2.0).
Rebrand: **ScoreWise** · Android app id `com.scorewise.cardscorer` · Firebase `scorewise-9a7f6`.
AEO/ASO applied per `store/ASO_AEO_STRATEGY.md`. Honest game set only (partnership trick-taking,
caller+target model) — deliberately NOT claiming Rummy/Bridge/Skyjo: different scoring, false
claim tanks retention + reviews, which are 2026 ranking signals.

---

## Store listing — paste-in fields

| Field | Value |
|---|---|
| App name (title, ≤30) | `ScoreWise: Card Game Scorer` (27 chars) |
| Short description (≤80) | `Card game score keeper. Offline scorepad & live share for 29, Court Piece, Rang.` (80) |
| Category | Apps → Tools |
| Tags | Utilities, Productivity, Offline |
| Contact email | admin@shubhpanchang.com |
| Website | https://scorewise-legal.vercel.app/  ⚠️ confirm marketing root resolves |
| Privacy policy | https://scorewise-legal.vercel.app/privacy/ |

**Title front-loads brand + the #1 head keyword ("Card Game Scorer") inside the first 27 chars —
survives search-result truncation.** Short description leads with the exact head phrase
`card game score keeper`, packs `scorepad` + the `live share` differentiator, anchors two honest
high-recognition games. Both indexed fields carry the target terms (short desc = 84% of observed
Play ranking lift).

---

## Full description (max 4000 chars) — AEO structured

```
ScoreWise is a fast, offline card game score keeper — a digital scorepad for the friend who always ends up keeping score. Start a session, add players, and log every round in seconds. No account, no internet, no paper.

Built for partnership trick-taking card games where one player calls a target and their team tries to reach it: 29, Partner 29, Court Piece, Rang, Mindi, Black Queen, and many regional variants.

— LIVE SHARE YOUR SCOREBOARD —
Tap broadcast on any session. A short code and QR appear. Friends open the link or scan to watch every round land in real time — in any browser, no app, no sign-up. Nobody has to crowd around one phone.

— WHY SCOREWISE —
• Start in seconds. Add 4 to 12 players, one tap each. Past names remembered.
• Log a round in under 10 seconds. Pick the caller, tap teammates, set the target on a custom keypad, tap Won or Lost.
• Always-correct math. Totals recompute from scratch after every edit or delete — no stale scores, ever.
• Live leaderboard. Rows reorder as scores change; each score pulses green on a gain, red on a loss.
• Optional caller bonus. Configure a transparent ± bonus that applies only to the caller.
• Round history. Every tile shows caller, target, and result. Edit or delete any round — the board recalculates instantly.
• Celebratory finish. Podium, fun stats (biggest single win, boldest call, longest streak), and a WhatsApp-friendly summary card.
• Lifetime stats. Top winner, top earner, cold streak, most targets won — tracked across every night you play.
• Resume anytime. Take a call, answer a text — one tap resumes your active session. No lost rounds.

— FREQUENTLY ASKED —
Q: Is ScoreWise free?
A: Yes. Free to use, works fully offline.

Q: Does it need an account or internet?
A: No. Scoring and history stay on your device. Internet is only used if you choose to live-share a session.

Q: Which card games does it work for?
A: Any partnership trick-taking game with a caller and a target score — 29, Partner 29, Court Piece (Rang / Rung / Trump / Kot Piece / Sar Bazi), Mindi, Black Queen, and similar regional variants.

Q: Can friends watch the score without the app?
A: Yes. Live-share opens the scoreboard in any web browser from a link or QR code — no install needed.

Q: Is this a gambling app?
A: No. ScoreWise only keeps score. "Calling a target" means calling a number of points or tricks — no money, chips, coins, wagers, or stakes of any kind.

— ALSO KNOWN AS —
Court Piece is also called Rang, Rung, Trump, Kot Piece, or Sar Bazi across South Asia. 29 is played as Partner 29 or 29 Card Game in Kerala and Nova Scotia. Black Queen is a regional partnership variant. ScoreWise keeps score for all of them.

— PRIVACY —
Scoring and history stay on your device. Live sharing is opt-in per session — when you tap broadcast, player names, scores, and results sync to a temporary session anyone with the code can watch. End it from Settings to delete it. No account, no cross-app tracking.

Made for card nights. Grab your deck — ScoreWise keeps score.
```

_Keyword coverage: `card game score keeper`, `scorepad`, `score keeper`, `card game`, plus honest
per-game long-tail (29, Court Piece, Rang, Mindi, Black Queen) — ~1 exact-match per ~250 chars,
placed naturally, no stuffing. The FAQ block doubles as AEO fuel: answer-engine-shaped Q&A that
mirrors "what's the best app to keep score for card games / is it free / does it work offline"._

---

## What's new (release notes, max 500 chars)

```
Meet ScoreWise — the fast, offline scorer for your card nights. Live-share the scoreboard so friends watch every round in real time, in any browser. Plus one-tap resume for your active session, lifetime stats across games, and a celebratory podium finish. No account, no internet needed to keep score.
```

---

## #8 — Data Safety form

- **Data collected**: Yes.
  - Advertising / performance → **Advertising ID** — purpose: Advertising or marketing. Shared with Google AdMob. ⚠️ See "Ads decision" below — declare only if shipping with AdMob live.
  - App activity → **App interactions** — purpose: App functionality.
  - App info & performance → **Crash logs**, **Diagnostics** — purpose: App functionality.
  - Messages → **Other in-app messages** (player names / scores in live sessions) — purpose: App functionality. Optional: Yes (only when a live session starts).
- **Encrypted in transit**: Yes (HTTPS).
- **User can request deletion**: Yes — Settings → Data → Delete all history; uninstall clears the anonymous Firebase UID.

## #8 — Content rating (IARC questionnaire)

Pick the **Utility / Productivity / Communication / Other** branch — this is a scorekeeping TOOL, not a Game.

- Violence: **None**
- Sexual content: **None**
- Profanity: **None**
- Controlled substances: **None**
- Real-money gambling / wagering: **No**
- Simulated gambling (chips, coins, casino, betting): **No**
- Randomized purchases / loot boxes: **No**
- User-generated content shared with others: **Yes, shared privately** — live sessions can show player names the user typed; visible only to holders of the session code.

> Gambling = No: ScoreWise only keeps score for classic trick-taking card games. "Calling a target"
> = calling a number of points/tricks — no currency real or virtual is wagered, won, or lost. No
> chips, coins, stakes, or chance-based payouts.

Result: **Everyone**.

## #8 — Target audience & content

- Age range: **13+** (safe for all ages; 13+ avoids extra COPPA flows).
- Designed specifically for children? **No**.

## #8 — Ads decision ⚠️

Launch plan = **ads OFF** (RTDB `ad_config` unset → `showAds=false`; no creatives serve). But the
AdMob SDK is compiled in and `MobileAds.initialize()` runs, which can touch the advertising ID.
Two consistent options — pick one, keep the Ads + Data-Safety answers matched:

1. **Declare ads (safe default):** Contains ads = **Yes**, Advertising ID = **Yes** in Data Safety.
   Over-declaring never fails review; under-declaring does. Recommended unless SDK init is gated off.
2. **No ads at launch:** only if you gate `AdService.initialize()` / `MobileAds` behind the live
   config so nothing initializes when ads are off — then Contains ads = **No**, drop Advertising ID.

Uses advertising ID declaration is required on API 33+ whenever the SDK can access it.

## #8 — App access

- All functionality available without restricted/login access: **Yes**.

---

## Graphics checklist

| Asset | Spec | Status |
|---|---|---|
| Phone screenshots | 6 framed, 941×1672 (9:16) in `store/screenshots` + ChatGPT frames | ready — order: Home → Scoreboard → Podium → Stats → Player → Round |
| Feature graphic | 1024 × 500 PNG | TODO — headline "Live-share your card night." |
| App icon | 512 × 512 PNG (32-bit) | verify ScoreWise mark exported |

⚠️ Screenshot resolution 941px wide passes Play (min 320) but is under the recommended 1080.
Upscale to 1080×1920 for max sharpness if regenerating.
```
