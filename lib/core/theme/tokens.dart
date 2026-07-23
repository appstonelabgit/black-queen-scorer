import 'dart:math' as math;
import 'package:flutter/material.dart';

class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

// "Card Room" palette: playing-card-back indigo primary, poker-chip gold
// accent, felt-green wins, suit-red losses. Ivory/indigo-black neutrals biased
// toward the indigo accent (not pure grey). See docs / theme preview for rationale.
class AppColors {
  // Light — card table by day
  static const primaryLight = Color(0xFF4338CA); // indigo, card-back blue
  static const accentLight = Color(0xFFD9A31E); // poker-chip gold
  static const surfaceLight = Color(0xFFF7F6FB); // ivory with indigo bias
  static const surfaceElevatedLight = Color(0xFFFFFFFF);
  static const onSurfaceLight = Color(0xFF1E1B33); // indigo-black
  static const mutedLight = Color(0xFF6E6A85);
  static const successLight = Color(0xFF15803D); // felt green
  static const dangerLight = Color(0xFFC81E38); // suit red

  // Dark — card room at night
  static const primaryDark = Color(0xFF6257E8); // brighter indigo, AA on white text
  static const accentDark = Color(0xFFE7B84B);
  static const surfaceDark = Color(0xFF12101F);
  static const surfaceElevatedDark = Color(0xFF211E33);
  static const onSurfaceDark = Color(0xFFF2F0F7);
  static const mutedDark = Color(0xFF9B96B0);
  static const successDark = Color(0xFF34D399);
  static const dangerDark = Color(0xFFF26B7A);
}

/// Brightness-aware semantic colors. `danger` already lives on the
/// ColorScheme as `error`; `success` has no ColorScheme slot, so route all
/// positive/win greens through these instead of hand-pasting hex (which had
/// drifted and broke contrast in dark mode).
Color successColor(Brightness b) =>
    b == Brightness.light ? AppColors.successLight : AppColors.successDark;

Color dangerColor(Brightness b) =>
    b == Brightness.light ? AppColors.dangerLight : AppColors.dangerDark;

/// Minimal WCAG contrast helper for dev-time checks.
double contrastRatio(Color a, Color b) {
  double lum(Color c) {
    double channel(double n) =>
        n <= 0.03928 ? n / 12.92 : math.pow((n + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  final l1 = lum(a);
  final l2 = lum(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
