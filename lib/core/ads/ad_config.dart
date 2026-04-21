import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

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
}
