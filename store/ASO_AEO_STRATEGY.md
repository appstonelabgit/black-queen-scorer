# ASO + AEO Strategy — organic installs for the card-scorer app

Research date: 2026-07-23. For the Play Console submission on the new (approved) account.
Goal: maximize **organic** installs by (1) ranking for high-volume generic card-scoring searches and (2) getting surfaced by AI answer engines — without losing the long-tail regional-game traffic the current listing already earns.

---

## 1. The core strategic problem with "Black Queen Scorer"

The title is the single heaviest-weighted ranking field on Play (30 chars, capped since 2021). "Black Queen" spends that scarce budget on a **low-volume, ambiguous** term:

- **Low search volume** — "Black Queen" is one regional variant; almost nobody searches it as a scorer.
- **Ambiguous entity** — reads as chess (the queen piece), a card, or something goth/edgy. AI engines and Play's entity model can't cleanly map it to "card game scorekeeping."
- **Zero head-term coverage** — the real demand is generic: *score keeper*, *card game scorer*, *scorepad*, *score counter*, *scoreboard*. None are in the title.

Because this is a **fresh Play account with no ratings to carry over**, there's no brand equity to protect. Clean slate → rebrand to a generic-but-ownable name is the single highest-leverage move available.

---

## 2. Competitive landscape (who ranks for the generic terms)

| App | Title pattern | Positioning |
|---|---|---|
| ScorePad – Game Scoreboard | brand + "Game Scoreboard" | "fastest scoreboard for **any** game" |
| Scores Pad – board game tracker | brand + "board game tracker" | names card games: Tarot, Rummy, Bridge, Skyjo |
| Score Keeper – Score Counter | keyword + keyword | pure-generic, multiple clones |
| ScoreKEEPER | bare keyword | offline, no ads (same wedge as us) |
| Score Counter: Count Anything | keyword + tagline | universal counter |

**Takeaways:**
- The generic head-terms are **saturated with weak, undifferentiated clones**. Exact-match generic names ("Score Keeper") are unrankable AND unownable — you'd be one of ten.
- The winning move is a **short brandable mark + an explicit generic keyword phrase** in the title (e.g. `ScorePad – Game Scoreboard`). You get the keyword coverage *and* a name AI/brand-search can attribute to you.
- **Nobody owns "card-game-specific scorer" cleanly.** Most are "any game" generalists. Our real, defensible wedge: *the scorer built for card games specifically* (round/trick/bid model, per-game presets, caller bonus) **plus live-share**, which none of the competitors above have.

---

## 3. Play ASO — what actually moves ranking in 2026

Priority order, from the research:

1. **Title (30 chars)** — heaviest field. Pattern: `Brand: Primary Keyword`. Front-load the #1 keyword in the first ~15 chars (that's where search-result truncation happens).
2. **Short description (80 chars)** — punches far above its size. **84% of observed Play ranking gains correlated with adding the target keyword to the short description**, even with the title unchanged. Treat this as a second title, not a tagline.
3. **Full description** — index-scanned, but density is out; aim for **~1 exact-match of each target keyword per 250 chars**, placed naturally. Keyword-stuffing now *hurts* conversion (and conversion feeds ranking).
4. **Off-metadata signals (the 2026 shift)** — conversion rate, **retention**, and **review velocity** now weigh as much as metadata, sometimes more. Google explicitly rebalanced "from install volume to retention and engagement." → icon/screenshot conversion and keeping users are ranking work, not just polish.

### Concrete field rewrites (name-agnostic; swap `<Brand>`)

**Title** — put the generic head term in, keep the brand short:
```
<Brand>: Card Game Score Keeper      (≤30 chars — verify per chosen brand)
```

**Short description (80)** — keyword-first, one differentiator, two game anchors:
```
Card game score keeper. Offline scorepad for Rummy, 29, Court Piece + live share.
```
(79 chars. Leads with the exact head phrase; "scorepad" + "score keeper" both indexed; names two high-volume games — Rummy is far higher volume than Court Piece — and surfaces the live-share differentiator.)

**Full description** — keep the current strong body, but:
- Open with the generic phrase, then the specific games: *"…score keeper for any card game — Rummy, Rank, 29, Court Piece, Bridge, Skyjo, and more."*
- Keep the existing "ALSO KNOWN AS" section — it's excellent long-tail capture. **Add Rummy/Bridge/Skyjo/Uno-style** references since those are the volume.
- Retain the anti-gambling paragraph (protects content rating).

**Keyword targets (in priority):**
`card game score keeper` · `scorepad` · `score counter` · `card game scorer` · `game scoreboard` · then long-tail per-game: `rummy score`, `29 card game score`, `court piece scorer`, `bridge score`, `skyjo`, `black queen`.

### Conversion / retention levers (the off-metadata half)
- **Icon** must read as "card scoring" at 48px (a card + a tally/number), not an abstract mark.
- **Screenshots**: keep scoreboard as slot 1 (answers "what is this" in 0.5s), live-share slot 2 (the differentiator). Add caption text overlays with keywords ("Score any card game", "Live-share the scoreboard").
- **Review velocity**: add a gentle in-app review prompt after a *finished* session (peak satisfaction — podium screen). This directly feeds a 2026 ranking signal.
- **Retention**: the resume-banner + lifetime-stats already help; surface "come back" value (e.g. session history) early.

---

## 4. AEO — getting surfaced by AI answer engines

The query that matters: *"what's the best app to keep score for card games?"* asked in ChatGPT / Gemini / Perplexity / Google AI Overviews. These answer from **retrieved live sources**, not just training data. So AEO for an app ≠ ASO; it's about being the **cross-source-validated entity** for "card game scorer."

> Note: the "ChatGPT app directory" (apps that run *inside* ChatGPT) is a different thing and not the play here — you're a standalone mobile app. The lever is being *cited/recommended* in answers, which is source-driven.

What the research says drives it:

1. **Get into the listicles AI retrieves.** "Best score-counter apps" articles (MakeUseOf, Denexa, BoardGameGeek threads) are exactly what LLMs pull from. Action: pitch/submit to these roundups; earn a mention. This is the highest-leverage AEO move for an app.
2. **Reddit / BoardGameGeek presence.** AI engines lean heavily on Reddit and BGG for "best app for X." Authentic mentions in r/cardgames, r/boardgames, game-specific subs (r/rummy, Court Piece communities) = retrievable recommendations. (Genuine, not astroturf — engines and mods punish fake.)
3. **A crawlable, structured landing page.** You already have `appstonelabgit.github.io/black-queen-scorer/`. Upgrade it to answer the question directly:
   - An FAQ block with schema.org `FAQPage` structured data ("What card games does it support?", "Is it free/offline?", "Does it work for Rummy / 29 / Court Piece?").
   - A comparison/feature table (AI loves extractable tables).
   - Explicit entity statements: "*<Brand> is a free, offline score keeper for card games.*" Consistent name + description everywhere = the "entity recognition + cross-source validation" the research names.
4. **Consistent NAP-style entity signals.** Same app name, same one-line description across Play, App Store, the site, GitHub, and any mention. Inconsistency dilutes the entity.
5. **Structured data + clear naming maps to jobs-to-be-done.** Name/describe by the user job ("keep score for card games"), not a cryptic brand.

AEO deliverables to queue (post-name decision):
- [ ] Rewrite the GitHub Pages site: H1 = "<Brand> — Card Game Score Keeper", FAQPage schema, feature table, supported-games list.
- [ ] Draft 1–2 honest Reddit/BGG posts (show, don't spam) for launch.
- [ ] Email 3–5 "best score keeper app" listicle authors with a short, specific pitch (offline + live-share + card-specific).

---

## 5. What NOT to change
- Keep the anti-gambling framing and "Utility, not Game" content-rating path — it's correct and protects approval.
- Keep the "ALSO KNOWN AS" long-tail section — pure ASO gold, just broaden it.
- Keep scoreboard-leads screenshot order.

---

## 6. Name decision (blocks everything downstream)

The rebrand gates: package id, store title, icon, site H1, all metadata. Direction options and recommendation are in the chat thread / see § "Name shortlist" once chosen. Requirement for any candidate:
- Short brandable mark (ownable for brand-search + AEO entity) **+** generic keyword in the title.
- Card-relevant, unambiguous, not colliding with an existing high-rank app.
- Verify collision on Play + a quick trademark sanity check before locking.
