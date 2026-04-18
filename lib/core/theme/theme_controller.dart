import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/storage/hive_boxes.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(_load());

  static ThemeMode _load() {
    try {
      final box = Hive.box(HiveBoxes.settings);
      final v = box.get('themeMode') as String?;
      switch (v) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final box = Hive.box(HiveBoxes.settings);
      await box.put('themeMode', mode.name);
    } catch (_) {/* ignore */}
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});
