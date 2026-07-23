import 'dart:io';

import 'package:flutter/services.dart';

class Haptics {
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> warning() async {
    if (Platform.isIOS) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.vibrate();
    }
  }
}
