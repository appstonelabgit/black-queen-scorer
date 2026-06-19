import 'package:flutter/material.dart';

import '../ads/ad_service.dart';

/// Wraps every non-Home screen with a single persistent banner at the
/// bottom. Because this shell stays mounted for the entire time the user
/// is inside one of the wrapped routes, the ad widget lives through route
/// transitions and the ad SDK's internal refresh timer keeps ticking
/// without being reset on every `push` / `pop`.
class BannerShell extends StatelessWidget {
  final Widget child;
  const BannerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The banner (below) owns the real bottom edge and applies the
        // home-indicator inset via its own SafeArea. Strip the bottom inset
        // from the wrapped screen so its SafeArea/bottomNavigationBar doesn't
        // reserve that space a second time — otherwise a phantom gap appears
        // between the screen's bottom content and the banner.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
        const _PersistentBanner(),
      ],
    );
  }
}

/// Stable widget whose element stays mounted across the shell's lifetime.
/// The key anchors it across rebuilds so Flutter doesn't recreate the ad
/// on minor parent changes.
class _PersistentBanner extends StatelessWidget {
  const _PersistentBanner();

  @override
  Widget build(BuildContext context) {
    // Paint the banner strip + the home-indicator inset in the app surface
    // colour so a loading/empty/short ad never exposes the black root behind
    // the shell.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: RepaintBoundary(
          key: const ValueKey('persistent-banner'),
          child: AdService.banner(),
        ),
      ),
    );
  }
}
