// Paints the iPad Pro 13" marketing canvas (2064x2752) from the same raw
// phone screenshots used for iPhone 6.9". The device image sits centered with
// ample emerald felt around it, caption up top, wordmark at the bottom.
//
// Run with:
//   flutter test tool/frame_ipad_screenshots_test.dart
//
// Inputs  : store/screenshots/ios/6.9inch/raw/<NN>_<slug>.png
// Outputs : store/screenshots/ios/13inch/framed/<NN>_<slug>.png

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const _canvas = Size(2064, 2752);
const _emerald = Color(0xFF0F5132);
const _emeraldDeep = Color(0xFF0A1F1A);
const _gold = Color(0xFFE8B931);
const _fontFamily = 'FramerSans';

class _Shot {
  final String slug;
  final String captionA;
  final String captionB;
  const _Shot(this.slug, this.captionA, this.captionB);
}

const _shots = <_Shot>[
  _Shot('01_home', 'Fast, offline', 'card-night scorer'),
  _Shot('02_scoreboard', 'Live leaderboard,', 'zero spreadsheet'),
  _Shot('03_round_entry', 'Bidder, team, bid,', 'done — in 10 seconds'),
  _Shot('04_summary', 'Finish with a', 'podium and a share card'),
  _Shot('05_lifetime_stats', 'See who really', 'owns the table'),
  _Shot('06_settings', 'No account.', 'No ads. No tracking.'),
];

Future<ui.Image> _loadPng(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
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

void _paintBackground(Canvas canvas) {
  final rect = Offset.zero & _canvas;
  final bg = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_emerald, _emeraldDeep],
    ).createShader(rect);
  canvas.drawRect(rect, bg);

  // Bigger spade silhouette in the top-right for iPad's wider canvas.
  final spadePaint = Paint()..color = _gold.withValues(alpha: 0.06);
  _drawSpade(
    canvas,
    Offset(_canvas.width - 260, 260),
    340,
    spadePaint,
  );
}

void _paintCaption(Canvas canvas, String lineA, String lineB) {
  final para = (ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontFamily: _fontFamily,
      fontSize: 120,
      height: 1.05,
      fontWeight: FontWeight.w800,
    ),
  )
        ..pushStyle(ui.TextStyle(
          color: Colors.white,
          letterSpacing: -1.8,
          fontWeight: FontWeight.w800,
        ))
        ..addText('$lineA\n')
        ..pushStyle(ui.TextStyle(
          color: _gold,
          letterSpacing: -1.8,
          fontWeight: FontWeight.w800,
        ))
        ..addText(lineB))
      .build()
    ..layout(ui.ParagraphConstraints(width: _canvas.width - 200));

  canvas.drawParagraph(para, const Offset(100, 200));
}

void _paintDevice(Canvas canvas, ui.Image shot) {
  const deviceWidth = 1000.0;
  final deviceHeight = shot.height * (deviceWidth / shot.width);
  final left = (_canvas.width - deviceWidth) / 2;
  const top = 720.0;
  final rect = Rect.fromLTWH(left, top, deviceWidth, deviceHeight);
  final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(56));

  // Drop shadow beneath the device.
  final shadowRect = rect.translate(0, 22).inflate(8);
  final shadowRRect =
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(56));
  canvas.drawRRect(
    shadowRRect,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
  );

  canvas.save();
  canvas.clipRRect(rrect);
  paintImage(
    canvas: canvas,
    rect: rect,
    image: shot,
    fit: BoxFit.cover,
  );
  canvas.restore();

  // Gold hairline border.
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = _gold.withValues(alpha: 0.35),
  );
}

void _paintWordmark(Canvas canvas) {
  final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
    textAlign: TextAlign.center,
    fontFamily: _fontFamily,
    fontSize: 46,
    fontWeight: FontWeight.w700,
  ))
    ..pushStyle(ui.TextStyle(color: Colors.white.withValues(alpha: 0.72)))
    ..addText('Black Queen Scorer');
  final para = pb.build()
    ..layout(ui.ParagraphConstraints(width: _canvas.width));
  canvas.drawParagraph(
      para, Offset(0, _canvas.height - 150 - para.height / 2));
}

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

void main() {
  testWidgets('frame iPad marketing screenshots', (tester) async {
    await tester.runAsync(() async {
      await _loadFont();
      const rawDir = 'store/screenshots/ios/6.9inch/raw';
      const outDir = 'store/screenshots/ios/13inch/framed';
      await Directory(outDir).create(recursive: true);

      for (final shot in _shots) {
        final rawPath = '$rawDir/${shot.slug}.png';
        if (!await File(rawPath).exists()) {
          // ignore: avoid_print
          print('SKIP missing raw: $rawPath');
          continue;
        }
        final image = await _loadPng(rawPath);

        final bytes = await _render((canvas, size) {
          _paintBackground(canvas);
          _paintCaption(canvas, shot.captionA, shot.captionB);
          _paintDevice(canvas, image);
          _paintWordmark(canvas);
        });

        final outPath = '$outDir/${shot.slug}.png';
        await File(outPath).writeAsBytes(bytes);
        // ignore: avoid_print
        print('✓ $outPath (${bytes.length} bytes)');
      }
    });
  });
}
