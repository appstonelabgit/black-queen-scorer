import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Faint guilloché engraving — the interlocking parametric line-work printed on
/// the back of playing cards and banknotes — painted behind a screen.
///
/// Wrapped around each route individually (see the router's `_engraved`) rather
/// than once under the whole Navigator: every [Scaffold] is transparent (see
/// [AppTheme]), so a single shared background would let the outgoing screen
/// bleed through the incoming one during a slide transition. Painting it
/// per-page makes each route opaque so it cleanly occludes the one beneath.
/// Isolated in a [RepaintBoundary] and drawn from a static [CustomPainter], so
/// it paints once per screen and never rebuilds with page content.
class EngravedBackground extends StatelessWidget {
  final Widget child;
  const EngravedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GuillochePainter(
                surface: theme.colorScheme.surface,
                ink: dark ? AppColors.primaryDark : AppColors.primaryLight,
                opacity: dark ? 0.07 : 0.05,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GuillochePainter extends CustomPainter {
  final Color surface;
  final Color ink;
  final double opacity;

  _GuillochePainter({
    required this.surface,
    required this.ink,
    required this.opacity,
  });

  // Lattice spacing and rosette scale — tuned to read as texture, not pattern.
  static const double _tile = 150;
  static const double _scale = 5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..isAntiAlias = true
      ..color = ink.withValues(alpha: opacity);

    for (double cy = _tile / 2; cy < size.height + _tile; cy += _tile) {
      for (double cx = _tile / 2; cx < size.width + _tile; cx += _tile) {
        // Two concentric hypotrochoid rings = interwoven, engraved look.
        _rosette(canvas, line, cx, cy, 7, 4, 4, _scale);
        _rosette(canvas, line, cx, cy, 9, 4, 2.4, _scale * 0.7);
      }
    }
  }

  /// One hypotrochoid (spirograph) rosette centred at (cx, cy). [bigR]/[smallR]
  /// are the rolling-circle radii ratio; [d] the pen offset.
  void _rosette(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    int bigR,
    int smallR,
    double d,
    double scale,
  ) {
    final turns = smallR ~/ _gcd(bigR, smallR); // curve closes after this many
    final k = (bigR - smallR) / smallR;
    const steps = 1000;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * math.pi * 2 * turns;
      final x = ((bigR - smallR) * math.cos(t) + d * math.cos(k * t)) * scale;
      final y = ((bigR - smallR) * math.sin(t) - d * math.sin(k * t)) * scale;
      if (i == 0) {
        path.moveTo(cx + x, cy + y);
      } else {
        path.lineTo(cx + x, cy + y);
      }
    }
    canvas.drawPath(path, paint);
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  @override
  bool shouldRepaint(_GuillochePainter old) =>
      old.surface != surface || old.ink != ink || old.opacity != opacity;
}
