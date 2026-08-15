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
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.readyNotifier,
      builder: (context, ready, _) => ValueListenableBuilder<AdLoadStatus>(
        valueListenable: AdService.bannerStatus,
        builder: (context, status, _) {
          // Until a creative actually fills, the screen owns the full height
          // including the home-indicator inset; once the banner is visible it
          // takes over the bottom edge and the inset moves below the ad.
          final bannerVisible = ready && status == AdLoadStatus.loaded;
          final mq = MediaQuery.of(context);
          return Column(
            children: [
              // While the banner is visible, strip the bottom inset from the
              // wrapped screen so its SafeArea/bottomNavigationBar doesn't
              // reserve that space a second time — otherwise a phantom gap
              // appears between the screen's bottom content and the banner.
              // The MediaQuery wrapper is always present (only its data
              // changes) so toggling never remounts the screen subtree.
              Expanded(
                child: MediaQuery(
                  data: bannerVisible
                      ? mq.removePadding(removeBottom: true)
                      : mq,
                  child: child,
                ),
              ),
              _PersistentBanner(applyBottomInset: bannerVisible),
            ],
          );
        },
      ),
    );
  }
}

/// Stable widget whose element stays mounted across the shell's lifetime.
/// The key anchors it across rebuilds so Flutter doesn't recreate the ad
/// on minor parent changes.
class _PersistentBanner extends StatelessWidget {
  final bool applyBottomInset;
  const _PersistentBanner({required this.applyBottomInset});

  @override
  Widget build(BuildContext context) {
    // Paint the banner strip + the home-indicator inset in the app surface
    // colour so a short creative never exposes the black root behind the
    // shell. The strip must span the full screen width (the ad itself is a
    // fixed 320dp creative, centered) — the Column doesn't stretch children,
    // so without the infinite-width SizedBox the ColoredBox shrink-wraps to
    // the ad and the root shows through on both sides. Plain Padding (not
    // SafeArea) so the inset can collapse to zero while the banner is hidden
    // without remounting the ad widget.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              applyBottomInset ? MediaQuery.paddingOf(context).bottom : 0,
        ),
        child: const SizedBox(
          width: double.infinity,
          child: RepaintBoundary(
            key: ValueKey('persistent-banner'),
            child: Center(
              heightFactor: 1,
              child: _BannerHost(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indirection so the ad widget itself can stay `const` under the
/// RepaintBoundary while the parent's padding animates around it.
class _BannerHost extends StatelessWidget {
  const _BannerHost();

  @override
  Widget build(BuildContext context) => AdService.banner();
}
