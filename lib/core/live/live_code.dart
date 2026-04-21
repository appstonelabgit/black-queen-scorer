import 'dart:math' as math;

/// URL-friendly alphabet without visually ambiguous characters (0/O/I/1/L).
const _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
final _rng = math.Random.secure();

/// Generates a short, shareable live-session code like `8F4T-P2Q9`.
String generateLiveCode() {
  final b = StringBuffer();
  for (var i = 0; i < 8; i++) {
    if (i == 4) b.write('-');
    b.write(_alphabet[_rng.nextInt(_alphabet.length)]);
  }
  return b.toString();
}

/// Normalises user-typed codes: uppercase, strips whitespace, keeps dashes.
String normalizeLiveCode(String raw) {
  return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
}

bool isValidLiveCode(String code) =>
    RegExp(r'^[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$').hasMatch(code);
