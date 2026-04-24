# Privacy Policy — Black Queen Scorer

Last updated: 24 April 2026

> **Canonical version**: the published copy of this policy lives at <https://appstonelabgit.github.io/black-queen-scorer/privacy.html> (source: `docs/privacy.html`). Keep this markdown file in sync whenever that HTML file changes.

Black Queen Scorer ("the app", "we") is developed and maintained by **AppStoneLab**. This page explains, in plain English, what data the app handles.

## Summary

Gameplay data — player names, scores, session history — is stored on your device by default. The app uses Google services for advertising, basic crash prevention, and the optional live-session sharing feature. No account, sign-in, or personal identifier is ever requested.

## Data you create inside the app

When you add players, record rounds, and finish sessions, the app stores that information in your device's private application storage (Hive). That data:

- Never leaves your device unless you explicitly start or share a live session (see below)
- Is not accessible to other apps
- Is automatically deleted when you uninstall the app
- Can be deleted at any time from **Settings → Data → Delete all history**

## Live session sharing (opt-in per session)

Live sharing is off by default. When you tap the **broadcast** icon on a session's scoreboard, the app syncs that session to **Firebase Realtime Database** so anyone with the short code can follow the scoreboard live. The data synced is limited to:

- Player names as you enter them
- Rounds (bidder, bid amount, win/loss, per-player score deltas)
- Session start and finish timestamps
- An anonymous Firebase user ID assigned to your device (not linked to any account — generated on first launch)

The session is reachable only to people you share the 8-character code (format `XXXX-XXXX`) with. Nothing in this data identifies you personally; it contains only what you typed into the app.

To stop sharing, delete the session from history or uninstall the app. Inactive sessions older than 30 days are automatically purged from the server.

## Advertising

The app shows advertisements through **Google AdMob**. AdMob may access:

- Your device's advertising identifier (to serve and measure ads; you can reset or opt-out in your device settings)
- Approximate geography inferred from IP address
- Basic device information (model, OS version, language)

On iOS, the app asks for tracking permission the first time it launches. If you decline, ads you see are non-personalized.

For details on AdMob's data handling, see [Google's privacy policy](https://policies.google.com/privacy). You can opt out of personalized advertising on Android via *Settings → Google → Ads* and on iOS via *Settings → Privacy → Tracking*.

## Firebase services

We use these Firebase products:

- **Firebase Authentication (Anonymous)** — assigns your device a random anonymous ID so the Realtime Database can allow writes without requiring a sign-up
- **Firebase Realtime Database** — hosts live-session data (see above)
- **Firebase Remote Config** — lets us tune ad placements and frequency without releasing a new app version

Firebase is a Google service governed by [Google's Firebase privacy commitments](https://firebase.google.com/support/privacy).

## Data we never collect

- Name, email, phone number, date of birth
- Precise location
- Contacts, photos, or files on your device
- Microphone, camera, or biometric data

## Permissions

The app asks for:

- **Internet** — required for ads and live-session sync
- **Advertising ID** (Android) — used only by the ad SDK

When you tap **Share** on a session summary, the app generates an image on your device and hands it to the system share sheet. Whatever you do with that image (WhatsApp, email, AirDrop, etc.) is between you and the destination app.

## Children's privacy

The app is rated for ages 13 and up. It does not knowingly collect personal data from anyone under 13.

## Changes to this policy

If this policy ever changes, we will publish the updated version at the same URL and update the "Last updated" date at the top.

## Contact

Questions about privacy? Email **dbvaghani@gmail.com**.
