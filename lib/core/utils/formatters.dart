import 'package:characters/characters.dart';
import 'package:intl/intl.dart';

String formatScore(int n) {
  if (n == 0) return '0';
  final sign = n > 0 ? '+' : '\u2212'; // U+2212 minus sign
  final abs = n.abs();
  final formatted = NumberFormat('#,###').format(abs);
  return '$sign$formatted';
}

String formatBid(int n) => NumberFormat('#,###').format(n);

String formatDuration(Duration d) {
  if (d.inDays >= 1) {
    final days = d.inDays;
    final h = d.inHours.remainder(24);
    return h > 0 ? '${days}d ${h}h' : '${days}d';
  }
  if (d.inHours >= 1) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
  if (d.inMinutes >= 1) return '${d.inMinutes} min';
  return '${d.inSeconds}s';
}

/// "1 player", "3 players" — count + correctly pluralized noun.
String plural(int n, String singular, [String? pluralForm]) =>
    '$n ${n == 1 ? singular : (pluralForm ?? '${singular}s')}';

String formatRelativeDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final days = today.difference(that).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return DateFormat.yMMMd().format(dt);
}

String playerInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
