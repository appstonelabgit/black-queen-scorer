import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:apsl_ads/apsl_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ad_config.dart';

/// Native-ad colors for one brightness, derived from the app's Card Room
/// tokens. The native template is styled at load time, so [_NativeSlot] keys
/// the ad widget by brightness — a theme flip remounts and reloads it.
class _AdPalette {
  final Color surface;
  final Color accent;
  final Color onAccent;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;

  const _AdPalette._({
    required this.surface,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
  });

  factory _AdPalette.of(Brightness b) => b == Brightness.light
      ? _AdPalette._(
          surface: AppColors.surfaceElevatedLight,
          accent: AppColors.accentLight,
          onAccent: AppColors.onSurfaceLight,
          text: AppColors.onSurfaceLight,
          textSecondary: AppColors.onSurfaceLight.withValues(alpha: 0.72),
          textTertiary: AppColors.mutedLight,
        )
      : _AdPalette._(
          surface: AppColors.surfaceElevatedDark,
          accent: AppColors.accentDark,
          onAccent: AppColors.onSurfaceLight,
          text: AppColors.onSurfaceDark,
          textSecondary: AppColors.onSurfaceDark.withValues(alpha: 0.72),
          textTertiary: AppColors.mutedDark,
        );
}

/// Fixed height reserved for the medium native slot. Shared by the inner ad
/// container, the loading placeholder, and the outer sizing box so the slot
/// never collapses to the creative's intrinsic (0-width) size while loading.
const double _nativeHeight = 360;

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
    // App Review requires the ATT prompt before any ad SDK starts, even when
    // remote config later disables ads — so this runs before the config gate.
    await _requestTrackingAuthorization();
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

  /// iOS-only App Tracking Transparency prompt. Waits for the dialog to be
  /// presentable (app must be active) and never throws — a denied/failed
  /// request just means AdMob serves non-personalized ads.
  static Future<void> _requestTrackingAuthorization() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Give the first frame a beat to settle; iOS silently drops the
        // prompt if the app isn't fully active yet.
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ATT request failed: $e');
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

  /// Persistent banner. Takes up zero height until a creative actually
  /// fills — the screen stays full while the ad loads (or never fills) and
  /// the 50px strip appears only on load. Remounting retries the load.
  static Widget banner() => const _BannerSlot();

  /// Native ad themed to the app's indigo/gold tokens, following the active
  /// light/dark theme. Self-contained widget that handles the loading
  /// placeholder and capped in-session retry — see [_NativeSlot].
  static Widget nativeMedium() => const _NativeSlot();

  /// Clean full-width card shown over the native slot while it loads, so the
  /// user sees an intentional placeholder instead of a stray sliver.
  static Widget _nativePlaceholder(_AdPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: p.accent.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(p.accent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  static Widget _nativeInner(_AdPalette p, {Key? adKey}) {
    final style = NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: p.surface,
      cornerRadius: 0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: p.onAccent,
        backgroundColor: p.accent,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: p.text,
        style: NativeTemplateFontStyle.bold,
        size: 16,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: p.textSecondary,
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: p.textTertiary,
        size: 12,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: p.accent.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: _nativeHeight,
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
  // ApslSequenceNativeAd owns retries: exponential backoff over maxRetries=5
  // (~2+4+8+16+32s), then a 45s recovery loop. We deliberately do NOT remount
  // the ad on a `failed` event — the package emits `adFailedToLoad` before each
  // of its own retries, and remounting with a fresh key disposed the in-flight
  // backoff, so the two retry loops fought and blank windows got longer.
  //
  // Instead we keep one ad widget mounted (stable key) and let the package
  // retry underneath. If nothing fills within this grace window, we collapse
  // the whole "Sponsored" block rather than leave a placeholder spinning.
  static const _giveUpAfter = Duration(seconds: 90);

  Timer? _giveUpTimer;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    AdService.nativeStatus.value = AdLoadStatus.loading;
    AdService.nativeExhausted.value = false;
    AdService.nativeStatus.addListener(_onStatus);
    _armGiveUpTimer();
  }

  void _armGiveUpTimer() {
    _giveUpTimer?.cancel();
    _giveUpTimer = Timer(_giveUpAfter, () {
      if (!mounted) return;
      if (AdService.nativeStatus.value != AdLoadStatus.loaded) {
        AdService.nativeExhausted.value = true; // Home collapses the block.
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A brightness flip remounts the ad (its key carries the brightness), so
    // the creative reloads. Reset the status to bring the placeholder back
    // over the reload window instead of showing an empty card.
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != null && _lastBrightness != brightness) {
      AdService.nativeStatus.value = AdLoadStatus.loading;
      AdService.nativeExhausted.value = false;
      _armGiveUpTimer();
    }
    _lastBrightness = brightness;
  }

  void _onStatus() {
    // Once the creative fills, we're done waiting; transient `failed` events
    // are ignored — the package handles the reload.
    if (AdService.nativeStatus.value == AdLoadStatus.loaded) {
      _giveUpTimer?.cancel();
    }
  }

  @override
  void dispose() {
    AdService.nativeStatus.removeListener(_onStatus);
    _giveUpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The template style only applies when the ad loads, so the key carries
    // the brightness: flipping the theme remounts the ad widget and reloads
    // the creative with the matching palette. Costs one reload per theme
    // switch — rare enough to be the right trade against a mismatched card.
    final brightness = Theme.of(context).brightness;
    final palette = _AdPalette.of(brightness);
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.readyNotifier,
      builder: (_, ready, __) {
        if (!ready) return const SizedBox.shrink();
        return ValueListenableBuilder<AdLoadStatus>(
          valueListenable: AdService.nativeStatus,
          builder: (_, status, __) {
            // Pin the slot to a full-width, fixed-height box. While the
            // creative loads, ApslAdmobNativeAd.show() returns SizedBox.shrink
            // (0x0), so a bare Stack would size to that collapsed child and
            // paint only the inner card's ~1px border — the stray "vertical
            // line" artifact. StackFit.expand forces both the native view and
            // the placeholder to the full box regardless of the ad's state.
            return SizedBox(
              width: double.infinity,
              height: _nativeHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AdService._nativeInner(
                    palette,
                    adKey: ValueKey('native-ad-${brightness.name}'),
                  ),
                  if (status != AdLoadStatus.loaded)
                    Positioned.fill(
                        child: AdService._nativePlaceholder(palette)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// The persistent banner slot. Keeps the ad mounted (so it can load and the
/// SDK refresh timer can tick) but contributes zero height until a creative
/// fills — loading happens behind a full-height screen instead of an empty
/// 50px strip. Resetting the status on mount gives a fresh load attempt each
/// time the shell is re-entered.
class _BannerSlot extends StatefulWidget {
  const _BannerSlot();

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  // As with the native slot, ApslSequenceBannerAd owns retries (exp backoff
  // over maxRetries=5, then a 45s recovery loop). We keep one banner widget
  // mounted with a stable key and let it retry underneath instead of
  // remounting it on each `failed` event. If nothing fills within the grace
  // window, we collapse the strip to zero height so no empty box lingers.
  static const _giveUpAfter = Duration(seconds: 90);

  Timer? _giveUpTimer;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    AdService.bannerStatus.value = AdLoadStatus.loading;
    AdService.bannerStatus.addListener(_onStatus);
    _giveUpTimer = Timer(_giveUpAfter, () {
      if (!mounted) return;
      if (AdService.bannerStatus.value != AdLoadStatus.loaded) {
        setState(() => _exhausted = true);
      }
    });
  }

  void _onStatus() {
    if (AdService.bannerStatus.value == AdLoadStatus.loaded) {
      _giveUpTimer?.cancel();
    }
  }

  @override
  void dispose() {
    AdService.bannerStatus.removeListener(_onStatus);
    _giveUpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.readyNotifier,
      builder: (_, ready, __) {
        if (!ready || _exhausted) return const SizedBox.shrink();
        // Offstage keeps the ad widget mounted and laid out (so the load
        // and the package's retry loop run) without painting or taking
        // height. The strip appears only once bannerStatus flips to loaded.
        return ValueListenableBuilder<AdLoadStatus>(
          valueListenable: AdService.bannerStatus,
          builder: (_, status, child) => Offstage(
            offstage: status != AdLoadStatus.loaded,
            child: child,
          ),
          child: SizedBox(
            height: 50,
            child: ApslSequenceBannerAd(
              key: const ValueKey('persistent-banner-ad'),
              orderOfAdNetworks: const [AdNetwork.admob],
            ),
          ),
        );
      },
    );
  }
}
