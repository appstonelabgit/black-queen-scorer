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

class AppColors {
  // Light
  static const primaryLight = Color(0xFF0F5132);
  static const accentLight = Color(0xFFD4A017);
  static const surfaceLight = Color(0xFFFAF7F2);
  static const surfaceElevatedLight = Color(0xFFFFFFFF);
  static const onSurfaceLight = Color(0xFF1A1A1A);
  static const mutedLight = Color(0xFF6B6B6B);
  static const successLight = Color(0xFF2E7D32);
  static const dangerLight = Color(0xFFC62828);

  // Dark
  static const primaryDark = Color(0xFF198754);
  static const accentDark = Color(0xFFE8B931);
  static const surfaceDark = Color(0xFF0A1F1A);
  static const surfaceElevatedDark = Color(0xFF143028);
  static const onSurfaceDark = Color(0xFFF5F1EA);
  static const mutedDark = Color(0xFFA8A8A8);
  static const successDark = Color(0xFF66BB6A);
  static const dangerDark = Color(0xFFEF5350);
}

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
