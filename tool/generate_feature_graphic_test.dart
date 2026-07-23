// Generates the Play Store feature graphic (1024x500 PNG).
// Emerald gradient background, gold spade+crown crest on the left,
// "Black Queen Scorer" + tagline on the right.
//
// Run with:
//   flutter test tool/generate_feature_graphic_test.dart
//
// Output: store/screenshots/android/feature-graphic.png

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const _canvas = Size(1024, 500);
const _emerald = Color(0xFF0F5132);
const _emeraldDeep = Color(0xFF0A1F1A);
const _gold = Color(0xFFE8B931);
const _goldDeep = Color(0xFFD4A017);
const _fontFamily = 'FramerSans';

Future<void> _loadFont() async {
  const candidates = [
    '/System/Library/Fonts/SFNS.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    '/System/Library/Fonts/Helvetica.ttc',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    final loader = FontLoader(_fontFamily)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
    // ignore: avoid_print
    print('Loaded font from $path');
    return;
  }
  throw StateError('No usable TTF found on host');
}

Future<Uint8List> _render(void Function(Canvas, Size) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas, _canvas);
  final picture = recorder.endRecording();
  final image =
      await picture.toImage(_canvas.width.toInt(), _canvas.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void _drawSpade(Canvas canvas, Offset c, double r, Paint paint) {
  final p = Path();
  p.moveTo(c.dx, c.dy - r);
  p.cubicTo(c.dx + r * 0.85, c.dy - r * 0.45, c.dx + r * 1.02,
      c.dy + r * 0.15, c.dx + r * 0.55, c.dy + r * 0.42);
  p.cubicTo(c.dx + r * 0.28, c.dy + r * 0.56, c.dx + r * 0.1,
      c.dy + r * 0.52, c.dx + r * 0.08, c.dy + r * 0.4);
  p.cubicTo(c.dx + r * 0.15, c.dy + r * 0.72, c.dx + r * 0.22,
      c.dy + r * 0.88, c.dx + r * 0.4, c.dy + r * 0.98);
  p.lineTo(c.dx - r * 0.4, c.dy + r * 0.98);
  p.cubicTo(c.dx - r * 0.22, c.dy + r * 0.88, c.dx - r * 0.15,
      c.dy + r * 0.72, c.dx - r * 0.08, c.dy + r * 0.4);
  p.cubicTo(c.dx - r * 0.1, c.dy + r * 0.52, c.dx - r * 0.28,
      c.dy + r * 0.56, c.dx - r * 0.55, c.dy + r * 0.42);
  p.cubicTo(c.dx - r * 1.02, c.dy + r * 0.15, c.dx - r * 0.85,
      c.dy - r * 0.45, c.dx, c.dy - r);
  p.close();
  canvas.drawPath(p, paint);
}

void _drawCrown(Canvas canvas, Offset c, double w, Paint paint) {
  final h = w * 0.55;
  final p = Path();
  final left = c.dx - w / 2;
  final right = c.dx + w / 2;
  final baseY = c.dy + h / 2;
  p.moveTo(left, baseY);
  p.lineTo(right, baseY);
  p.lineTo(right - w * 0.05, c.dy - h / 2);
  p.lineTo(c.dx + w * 0.18, c.dy);
  p.lineTo(c.dx, c.dy - h * 0.75);
  p.lineTo(c.dx - w * 0.18, c.dy);
  p.lineTo(left + w * 0.05, c.dy - h / 2);
  p.close();
  canvas.drawPath(p, paint);

  final gem = Paint()..color = _emeraldDeep;
  canvas.drawCircle(Offset(c.dx, c.dy - h * 0.7), w * 0.05, gem);
  canvas.drawCircle(Offset(right - w * 0.05, c.dy - h / 2), w * 0.035, gem);
  canvas.drawCircle(Offset(left + w * 0.05, c.dy - h / 2), w * 0.035, gem);
}

void _paintBackground(Canvas canvas) {
  final rect = Offset.zero & _canvas;
  final bg = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_emerald, _emeraldDeep],
    ).createShader(rect);
  canvas.drawRect(rect, bg);

  // Subtle gold spade silhouette in the bottom-right for identity.
  final spadePaint = Paint()..color = _gold.withValues(alpha: 0.06);
  _drawSpade(
    canvas,
    Offset(_canvas.width - 90, _canvas.height - 40),
    180,
    spadePaint,
  );
}

void _paintCrest(Canvas canvas) {
  // Crest centered vertically in the left ~300px column.
  final center = Offset(190, _canvas.height / 2 + 10);
  const spadeR = 95.0;

  // Soft shadow.
  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  _drawSpade(canvas, center.translate(0, 6), spadeR, shadow);

  // Gold spade.
  final goldPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_gold, _goldDeep],
    ).createShader(Rect.fromCircle(center: center, radius: spadeR));
  _drawSpade(canvas, center, spadeR, goldPaint);

  // Crown sitting above the spade.
  final crownY = center.dy - spadeR * 1.35;
  final crownW = spadeR * 0.9;
  _drawCrown(canvas, Offset(center.dx, crownY), crownW, Paint()..color = _gold);
}

void _paintText(Canvas canvas) {
  // Title — sized to stay on a single line.
  final titlePb = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.left,
    fontFamily: _fontFamily,
    fontSize: 62,
    height: 1.05,
    fontWeight: FontWeight.w800,
  ))
    ..pushStyle(ui.TextStyle(
      color: Colors.white,
      letterSpacing: -1.4,
      fontWeight: FontWeight.w800,
    ))
    ..addText('Black ')
    ..pushStyle(ui.TextStyle(
      color: _gold,
      letterSpacing: -1.4,
      fontWeight: FontWeight.w800,
    ))
    ..addText('Queen')
    ..pop()
    ..addText(' Scorer');
  final title = titlePb.build()
    ..layout(const ui.ParagraphConstraints(width: 700));
  canvas.drawParagraph(title, const Offset(320, 180));

  // Subtitle.
  final subPb = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.left,
    fontFamily: _fontFamily,
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w500,
  ))
    ..pushStyle(ui.TextStyle(
      color: Colors.white.withValues(alpha: 0.82),
      letterSpacing: -0.4,
      fontWeight: FontWeight.w500,
    ))
    ..addText('Fast offline card-night scorer');
  final sub = subPb.build()
    ..layout(const ui.ParagraphConstraints(width: 700));
  canvas.drawParagraph(sub, const Offset(320, 272));

  // Gold accent underline under subtitle.
  final line = Paint()
    ..color = _gold.withValues(alpha: 0.85)
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3;
  canvas.drawLine(const Offset(322, 330), const Offset(420, 330), line);
}

void main() {
  testWidgets('generate Play Store feature graphic', (tester) async {
    await tester.runAsync(() async {
      await _loadFont();
      final bytes = await _render((canvas, size) {
        _paintBackground(canvas);
        _paintCrest(canvas);
        _paintText(canvas);
      });
      const outPath = 'store/screenshots/android/feature-graphic.png';
      await File(outPath).parent.create(recursive: true);
      await File(outPath).writeAsBytes(bytes);
      // ignore: avoid_print
      print('✓ $outPath (${bytes.length} bytes)');
    });
  });
}
