// Generates the app icon and splash assets used by flutter_launcher_icons
// and flutter_native_splash. Run with:
//
//   flutter test tool/generate_icon_test.dart
//
// Writes to assets/icon/icon.png, icon_foreground.png, splash.png.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emerald = Color(0xFF0F5132);
const _emeraldDeep = Color(0xFF0A1F1A);
const _gold = Color(0xFFE8B931);
const _goldDeep = Color(0xFFD4A017);

Future<Uint8List> _render(
  Size size,
  void Function(Canvas canvas, Size size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas, size);
  final picture = recorder.endRecording();
  final image =
      await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<void> _write(String path, Uint8List bytes) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  // ignore: avoid_print
  print('Wrote ${bytes.length} bytes → $path');
}

/// Paint a classic spade shape centered at `c` with overall radius `r`.
/// The shape fits roughly within a box of side 2r.
void _drawSpade(Canvas canvas, Offset c, double r, Paint paint) {
  final p = Path();
  // Apex.
  p.moveTo(c.dx, c.dy - r);
  // Right upper curve + right lobe outer.
  p.cubicTo(
    c.dx + r * 0.85, c.dy - r * 0.45,
    c.dx + r * 1.02, c.dy + r * 0.15,
    c.dx + r * 0.55, c.dy + r * 0.42,
  );
  // Right lobe curving back in toward stem top.
  p.cubicTo(
    c.dx + r * 0.28, c.dy + r * 0.56,
    c.dx + r * 0.1, c.dy + r * 0.52,
    c.dx + r * 0.08, c.dy + r * 0.4,
  );
  // Stem (right side).
  p.cubicTo(
    c.dx + r * 0.15, c.dy + r * 0.72,
    c.dx + r * 0.22, c.dy + r * 0.88,
    c.dx + r * 0.4, c.dy + r * 0.98,
  );
  // Stem base.
  p.lineTo(c.dx - r * 0.4, c.dy + r * 0.98);
  // Stem (left side).
  p.cubicTo(
    c.dx - r * 0.22, c.dy + r * 0.88,
    c.dx - r * 0.15, c.dy + r * 0.72,
    c.dx - r * 0.08, c.dy + r * 0.4,
  );
  // Left lobe inner back out.
  p.cubicTo(
    c.dx - r * 0.1, c.dy + r * 0.52,
    c.dx - r * 0.28, c.dy + r * 0.56,
    c.dx - r * 0.55, c.dy + r * 0.42,
  );
  // Left upper curve back to apex.
  p.cubicTo(
    c.dx - r * 1.02, c.dy + r * 0.15,
    c.dx - r * 0.85, c.dy - r * 0.45,
    c.dx, c.dy - r,
  );
  p.close();
  canvas.drawPath(p, paint);
}

/// Simple 5-point crown sitting on top of the spade.
void _drawCrown(Canvas canvas, Offset c, double w, Paint paint) {
  final h = w * 0.55;
  final p = Path();
  final left = c.dx - w / 2;
  final right = c.dx + w / 2;
  final baseY = c.dy + h / 2;
  // Base line.
  p.moveTo(left, baseY);
  p.lineTo(right, baseY);
  // Right peak.
  p.lineTo(right - w * 0.05, c.dy - h / 2);
  // Right-center valley.
  p.lineTo(c.dx + w * 0.18, c.dy);
  // Center peak (tallest).
  p.lineTo(c.dx, c.dy - h * 0.75);
  // Left-center valley.
  p.lineTo(c.dx - w * 0.18, c.dy);
  // Left peak.
  p.lineTo(left + w * 0.05, c.dy - h / 2);
  p.close();
  canvas.drawPath(p, paint);

  // Small gems on peaks.
  final gem = Paint()..color = _emeraldDeep;
  canvas.drawCircle(Offset(c.dx, c.dy - h * 0.7), w * 0.05, gem);
  canvas.drawCircle(Offset(right - w * 0.05, c.dy - h / 2), w * 0.035, gem);
  canvas.drawCircle(Offset(left + w * 0.05, c.dy - h / 2), w * 0.035, gem);
}

void _paintFullIcon(Canvas canvas, Size size, {required bool withBackground}) {
  final rect = Offset.zero & size;

  if (withBackground) {
    // Rounded-rectangle emerald felt background (iOS squares it off in post).
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_emerald, _emeraldDeep],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Faint gold vignette ring.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..color = _gold.withValues(alpha: 0.25);
    final inset = size.width * 0.08;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
        Radius.circular(size.width * 0.18),
      ),
      ring,
    );
  }

  final center = Offset(size.width / 2, size.height / 2);
  final spadeR = size.width * (withBackground ? 0.3 : 0.24);

  // Soft gold drop-shadow behind the spade for depth.
  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.02);
  _drawSpade(canvas, center.translate(0, size.height * 0.015), spadeR, shadow);

  // Main gold spade.
  final goldPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [_gold, _goldDeep],
    ).createShader(Rect.fromCircle(center: center, radius: spadeR));
  _drawSpade(canvas, center, spadeR, goldPaint);

  // Crown sitting above the spade.
  final crownY = center.dy - spadeR * 1.35;
  final crownW = spadeR * 0.9;
  _drawCrown(
    canvas,
    Offset(center.dx, crownY),
    crownW,
    Paint()..color = _gold,
  );
}

void main() {
  testWidgets('generate icon + splash assets', (tester) async {
    await tester.runAsync(() async {
      const size = Size(1024, 1024);

      // 1. Main icon: full bg + crest.
      final main = await _render(size, (canvas, s) {
        _paintFullIcon(canvas, s, withBackground: true);
      });
      await _write('assets/icon/icon.png', main);

      // 2. Adaptive foreground (transparent bg, crest at safe-zone size).
      final fg = await _render(size, (canvas, s) {
        _paintFullIcon(canvas, s, withBackground: false);
      });
      await _write('assets/icon/icon_foreground.png', fg);

      // 3. Splash crest (matches foreground).
      final splash = await _render(size, (canvas, s) {
        _paintFullIcon(canvas, s, withBackground: false);
      });
      await _write('assets/icon/splash.png', splash);
    });
  });
}
