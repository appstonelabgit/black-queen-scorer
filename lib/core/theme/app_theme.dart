import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final primary = isLight ? AppColors.primaryLight : AppColors.primaryDark;
    final accent = isLight ? AppColors.accentLight : AppColors.accentDark;
    final surface = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final surfaceElevated =
        isLight ? AppColors.surfaceElevatedLight : AppColors.surfaceElevatedDark;
    final onSurface = isLight ? AppColors.onSurfaceLight : AppColors.onSurfaceDark;
    final muted = isLight ? AppColors.mutedLight : AppColors.mutedDark;
    final danger = isLight ? AppColors.dangerLight : AppColors.dangerDark;

    final scheme = ColorScheme(
      brightness: b,
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.black,
      tertiary: accent,
      onTertiary: Colors.black,
      error: danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceElevated,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: muted.withValues(alpha: 0.3),
    );

    final text = _buildTextTheme(onSurface, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: text.labelLarge,
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          side: BorderSide(color: muted.withValues(alpha: 0.4)),
          textStyle: text.labelLarge,
          foregroundColor: onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: muted.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: muted.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        backgroundColor: surfaceElevated,
        contentTextStyle: text.bodyMedium?.copyWith(color: onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: muted.withValues(alpha: 0.18),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static TextTheme _buildTextTheme(Color onSurface, Color muted) {
    const family = 'Inter';
    return TextTheme(
      displayLarge: const TextStyle(
        fontFamily: family,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: const TextStyle(
        fontFamily: family,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      headlineLarge: const TextStyle(
        fontFamily: family,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: const TextStyle(
        fontFamily: family,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ).apply(bodyColor: onSurface, displayColor: onSurface);
  }
}

/// Score/number style: DM Sans-like tabular. We don't bundle the font here
/// (to keep install size under 30MB per section 15), so we use the system
/// default with tabular figures feature.
TextStyle scoreTextStyle(BuildContext context, {double size = 18}) {
  final scheme = Theme.of(context).colorScheme;
  return TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: scheme.onSurface,
  );
}
