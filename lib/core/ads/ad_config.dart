import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Google-published test ad unit IDs. Safe to send real traffic against
/// during development — they never fire a real impression and never
/// trigger a policy review. Used in debug builds only.
const _testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
const _testAppIdIos = 'ca-app-pub-3940256099942544~1458002511';
const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

/// Snapshot of the /ad_config node in Realtime Database. Drives runtime
/// behavior so ad IDs and frequency can be tuned without releasing an app.
class AdConfig {
  final bool showAds;
  final int interstitialEveryNthFinish;
  final String appId;
  final String bannerId;
  final String nativeId;
  final String interstitialId;

  const AdConfig({
    required this.showAds,
    required this.interstitialEveryNthFinish,
    required this.appId,
    required this.bannerId,
    required this.nativeId,
    required this.interstitialId,
  });

  static const AdConfig empty = AdConfig(
    showAds: false,
    interstitialEveryNthFinish: 3,
    appId: '',
    bannerId: '',
    nativeId: '',
    interstitialId: '',
  );

  bool get hasUsableIds =>
      bannerId.isNotEmpty && nativeId.isNotEmpty && interstitialId.isNotEmpty;
}

class AdConfigLoader {
  static AdConfig _current = AdConfig.empty;
  static AdConfig get current => _current;

  static Future<AdConfig> load() async {
    // Debug builds never touch RTDB or serve real creatives. Simulator
    // runs, hot reload, local TestFlight pre-builds — all get test ads.
    if (kDebugMode) {
      _current = _debugConfig();
      return _current;
    }
    try {
      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final ref = FirebaseDatabase.instance.ref('ad_config');
      final snap = await ref.get().timeout(const Duration(seconds: 8));
      if (!snap.exists) return _current;
      final root = Map<String, dynamic>.from(snap.value as Map);
      final platform =
          Map<String, dynamic>.from(root[platformKey] as Map? ?? const {});
      _current = AdConfig(
        showAds: root['showAds'] as bool? ?? false,
        interstitialEveryNthFinish:
            (root['interstitialEveryNthFinish'] as num?)?.toInt() ?? 3,
        appId: platform['appId'] as String? ?? '',
        bannerId: platform['bannerId'] as String? ?? '',
        nativeId: platform['nativeId'] as String? ?? '',
        interstitialId: platform['interstitialId'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('AdConfigLoader failed: $e');
    }
    return _current;
  }

  static AdConfig _debugConfig() {
    final isIos = Platform.isIOS;
    return AdConfig(
      showAds: true,
      interstitialEveryNthFinish: 3,
      appId: isIos ? _testAppIdIos : _testAppIdAndroid,
      bannerId: isIos ? _testBannerIos : _testBannerAndroid,
      nativeId: isIos ? _testNativeIos : _testNativeAndroid,
      interstitialId:
          isIos ? _testInterstitialIos : _testInterstitialAndroid,
    );
  }
}
