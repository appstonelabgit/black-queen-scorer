import 'dart:async';

import 'package:apsl_ads/apsl_ads.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ad_config.dart';

const _emeraldDeep = Color(0xFF0A1F1A);
const _gold = Color(0xFFE8B931);
const _nativeSurface = Color(0xFF143028);

class _BqsAdIdManager extends AdsIdManager {
  final AdConfig cfg;
  const _BqsAdIdManager(this.cfg);

  @override
  List<AppAdIds> get appAdIds => [
        AppAdIds(
          appId: cfg.appId,
          adNetwork: AdNetwork.admob,
          bannerId: cfg.bannerId,
          nativeId: cfg.nativeId,
          interstitialId: cfg.interstitialId,
          // Supplying this makes apsl load an app-open ad at init and show it
          // on every foreground resume via its AppLifecycleReactor.
          appOpenId: cfg.appOpenId.isEmpty ? null : cfg.appOpenId,
        ),
      ];
}

/// Lifecycle of the native ad's creative, distinct from SDK readiness.
/// The native platform view renders at a collapsed width until the creative
/// arrives, so Home covers the [loading] window with a placeholder and hides
/// the slot entirely on [failed]. The banner uses the same states to collapse
/// its reserved height to zero when no creative fills.
enum AdLoadStatus { loading, loaded, failed }

class AdService {
  static bool _sdkInitialized = false;
  static int _finishCount = 0;
  static bool _eventListenerAttached = false;

  /// Flipped to true once the SDK is ready *and* ad IDs are usable. Widgets
  /// returned by [banner] / [nativeMedium] rebuild against this so they
  /// paint the first time init finishes — critical for Home's native ad,
  /// which is rendered before post-frame init completes.
  static final ValueNotifier<bool> readyNotifier = ValueNotifier(false);

  /// Tracks whether the native creative has actually loaded. Driven by the
  /// global ad event stream so the UI can avoid showing the collapsed-width
  /// placeholder artifact while a native ad is still fetching.
  static final ValueNotifier<AdLoadStatus> nativeStatus =
      ValueNotifier(AdLoadStatus.loading);

  /// Same, for the persistent banner — lets the slot collapse to zero height
  /// instead of leaving an empty black box when no banner fills.
  static final ValueNotifier<AdLoadStatus> bannerStatus =
      ValueNotifier(AdLoadStatus.loading);

  /// True once the native ad has failed every retry for this Home mount.
  /// Home hides the whole "Sponsored" block on this — NOT on a transient
  /// [nativeStatus] failure, so retries aren't unmounted mid-flight.
  static final ValueNotifier<bool> nativeExhausted = ValueNotifier(false);

  static bool get ready =>
      _sdkInitialized && AdConfigLoader.current.showAds;

  /// Called post-frame from main.dart. Safe to call even if Firebase init
  /// failed — it simply no-ops and the app keeps working.
  static Future<void> initialize() async {
    if (_sdkInitialized) return;
    final cfg = await AdConfigLoader.load();
    if (!cfg.showAds || !cfg.hasUsableIds) return;

    try {
      await ApslAds.instance.initialize(
        _BqsAdIdManager(cfg),
        adMobAdRequest: const AdRequest(),
      );
      _sdkInitialized = true;
      readyNotifier.value = true;
      _attachAdStatusListener();
    } catch (e) {
      debugPrint('AdService.initialize failed: $e');
    }
  }

  /// Mirrors native + banner load/fail events into their status notifiers.
  /// Attached once.
  static void _attachAdStatusListener() {
    if (_eventListenerAttached) return;
    _eventListenerAttached = true;
    ApslAds.instance.onEvent.listen((event) {
      final ValueNotifier<AdLoadStatus>? target = switch (event.adUnitType) {
        AdUnitType.native => nativeStatus,
        AdUnitType.banner => bannerStatus,
        _ => null,
      };
      if (target == null) return;
      switch (event.type) {
        case AdEventType.adLoaded:
        case AdEventType.adShowed:
          target.value = AdLoadStatus.loaded;
          break;
        case AdEventType.adFailedToLoad:
        case AdEventType.adFailedToShow:
          target.value = AdLoadStatus.failed;
          break;
        default:
          break;
      }
    });
  }

  /// Persistent banner. Reserves its 50px only while loading or once filled;
  /// collapses to zero height on failure so a dead slot never shows as an
  /// empty black box. Remounting (re-entering the shell) retries the load.
  static Widget banner() => const _BannerSlot();

  /// Native ad themed to the app's emerald/gold tokens. Self-contained widget
  /// that handles the loading placeholder and capped in-session retry — see
  /// [_NativeSlot].
  static Widget nativeMedium() => const _NativeSlot();

  /// Clean full-width card shown over the native slot while it loads, so the
  /// user sees an intentional placeholder instead of a stray sliver.
  static Widget _nativePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _nativeSurface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: _gold.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_gold.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  static Widget _nativeInner({Key? adKey}) {
    final style = NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: _nativeSurface,
      cornerRadius: 0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: _emeraldDeep,
        backgroundColor: _gold,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        style: NativeTemplateFontStyle.bold,
        size: 16,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white.withValues(alpha: 0.72),
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white.withValues(alpha: 0.55),
        size: 12,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: _nativeSurface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 360,
        child: ApslSequenceNativeAd(
          key: adKey,
          orderOfAdNetworks: const [AdNetwork.admob],
          templateType: TemplateType.medium,
          nativeTemplateStyle: style,
        ),
      ),
    );
  }

  /// Call this when a session transitions from active → finished. Shows an
  /// interstitial every Nth finish (N comes from RTDB, default 3).
  static void onSessionFinished() {
    if (!ready) return;
    _finishCount++;
    final n = AdConfigLoader.current.interstitialEveryNthFinish;
    if (n > 0 && _finishCount % n == 0) {
      ApslAds.instance.showAd(AdUnitType.interstitial);
    }
  }
}

/// Home's native ad slot. Shows a placeholder while the creative loads, and
/// on failure retries a few times (remounting the ad widget with a fresh key)
/// before giving up — so a transient no-fill recovers without the user having
/// to leave and return to Home. After the cap, [AdService.nativeStatus] stays
/// `failed` and Home collapses the whole "Sponsored" block.
class _NativeSlot extends StatefulWidget {
  const _NativeSlot();

  @override
  State<_NativeSlot> createState() => _NativeSlotState();
}

class _NativeSlotState extends State<_NativeSlot> {
  static const _maxAttempts = 3;
  static const _retryDelay = Duration(seconds: 20);

  int _attempts = 0;
  int _reloadKey = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdService.nativeStatus.value = AdLoadStatus.loading;
    AdService.nativeExhausted.value = false;
    AdService.nativeStatus.addListener(_onStatus);
  }

  void _onStatus() {
    final status = AdService.nativeStatus.value;
    if (status == AdLoadStatus.loaded) {
      _retryTimer?.cancel();
      return;
    }
    if (status != AdLoadStatus.failed) return;
    if (_attempts >= _maxAttempts) {
      // Out of retries — let Home collapse the block.
      AdService.nativeExhausted.value = true;
      return;
    }
    if (_retryTimer == null || !_retryTimer!.isActive) {
      _retryTimer = Timer(_retryDelay, () {
        if (!mounted) return;
        _attempts++;
        AdService.nativeStatus.value = AdLoadStatus.loading;
        setState(() => _reloadKey++); // fresh ad widget → new load attempt
      });
    }
  }

  @override
  void dispose() {
    AdService.nativeStatus.removeListener(_onStatus);
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.readyNotifier,
      builder: (_, ready, __) {
        if (!ready) return const SizedBox.shrink();
        return ValueListenableBuilder<AdLoadStatus>(
          valueListenable: AdService.nativeStatus,
          builder: (_, status, __) {
            return Stack(
              children: [
                AdService._nativeInner(adKey: ValueKey(_reloadKey)),
                if (status != AdLoadStatus.loaded)
                  Positioned.fill(child: AdService._nativePlaceholder()),
              ],
            );
          },
        );
      },
    );
  }
}

/// The persistent banner slot. Keeps the ad mounted (so it can load and the
/// SDK refresh timer can tick) while [AdService.bannerStatus] is loading or
/// loaded, and collapses to zero height on failure. Resetting the status on
/// mount gives a fresh load attempt each time the shell is re-entered.
class _BannerSlot extends StatefulWidget {
  const _BannerSlot();

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  static const _maxAttempts = 3;
  static const _retryDelay = Duration(seconds: 15);

  int _attempts = 0;
  int _reloadKey = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // Retry on (re)entry: a prior failure shouldn't permanently kill the slot.
    AdService.bannerStatus.value = AdLoadStatus.loading;
    AdService.bannerStatus.addListener(_onStatus);
  }

  void _onStatus() {
    if (AdService.bannerStatus.value != AdLoadStatus.failed) return;
    if (_attempts >= _maxAttempts) return;
    if (_retryTimer != null && _retryTimer!.isActive) return;
    _retryTimer = Timer(_retryDelay, () {
      if (!mounted) return;
      _attempts++;
      AdService.bannerStatus.value = AdLoadStatus.loading;
      setState(() => _reloadKey++); // fresh banner widget → new load attempt
    });
  }

  @override
  void dispose() {
    AdService.bannerStatus.removeListener(_onStatus);
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.readyNotifier,
      builder: (_, ready, __) {
        if (!ready) return const SizedBox.shrink();
        return ValueListenableBuilder<AdLoadStatus>(
          valueListenable: AdService.bannerStatus,
          builder: (_, status, __) {
            // Collapse only once retries are exhausted.
            if (status == AdLoadStatus.failed && _attempts >= _maxAttempts) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 50,
              child: ApslSequenceBannerAd(
                key: ValueKey(_reloadKey),
                orderOfAdNetworks: const [AdNetwork.admob],
              ),
            );
          },
        );
      },
    );
  }
}
