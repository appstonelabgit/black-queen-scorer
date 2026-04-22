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
        Expanded(child: child),
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
    return SafeArea(
      top: false,
      child: RepaintBoundary(
        key: const ValueKey('persistent-banner'),
        child: AdService.banner(),
      ),
    );
  }
}
