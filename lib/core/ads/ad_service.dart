import 'package:apsl_ads/apsl_ads.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ad_config.dart';

const _emeraldDeep = Color(0xFF0A1F1A);
const _gold = Color(0xFFE8B931);

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
        ),
      ];
}

class AdService {
  static bool _sdkInitialized = false;
  static int _finishCount = 0;

  static bool get ready => _sdkInitialized && AdConfigLoader.current.showAds;

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
    } catch (e) {
      debugPrint('AdService.initialize failed: $e');
    }
  }

  /// Fixed-height banner that returns an empty box while loading or if
  /// ads are disabled. Callers can place it unconditionally.
  static Widget banner() {
    if (!ready) return const SizedBox.shrink();
    return const SizedBox(
      height: 50,
      child: ApslSequenceBannerAd(
        orderOfAdNetworks: [AdNetwork.admob],
      ),
    );
  }

  /// Native ad themed to the app's emerald/gold tokens.
  static Widget nativeMedium() {
    if (!ready) return const SizedBox.shrink();
    final style = NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: Colors.transparent,
      cornerRadius: Radii.lg,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: _emeraldDeep,
        backgroundColor: _gold,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        style: NativeTemplateFontStyle.bold,
        size: 15,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white70,
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white60,
        size: 12,
      ),
    );
    return SizedBox(
      height: 330,
      child: ApslSequenceNativeAd(
        orderOfAdNetworks: const [AdNetwork.admob],
        templateType: TemplateType.medium,
        nativeTemplateStyle: style,
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
