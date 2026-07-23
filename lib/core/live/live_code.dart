import 'dart:math' as math;

/// Host serving the live-share landing page + verified deep-link
/// association files (`.well-known/`). Vercel — it serves `.well-known`
/// at the domain root and rewrites `/l/:code`, neither of which GitHub
/// Pages project sites can do. Change in ONE place if the domain moves.
const liveLinkHost = 'black-queen-scorer.vercel.app';

/// Public URL for a live session — encoded in the QR + share text.
String liveLinkUrl(String code) => 'https://$liveLinkHost/l/$code';

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
