import 'package:hive/hive.dart';

import 'hive_boxes.dart';

class PlayersRepository {
  PlayersRepository._(this._box);

  final Box _box;
  static const _key = 'list';

  factory PlayersRepository() =>
      PlayersRepository._(Hive.box(HiveBoxes.recentPlayers));

  List<String> getRecent() {
    final raw = _box.get(_key);
    if (raw is List) return List<String>.from(raw);
    return <String>[];
  }

  Future<void> addMany(Iterable<String> names) async {
    final existing = getRecent();
    // Merge newest-first; case-insensitive dedupe; preserve casing of newest.
    final merged = <String>[];
    final seen = <String>{};
    final incoming = names.toList().reversed.toList();
    for (final n in [...incoming, ...existing]) {
      final key = n.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (seen.add(key)) merged.add(n.trim());
      if (merged.length >= 50) break;
    }
    await _box.put(_key, merged);
  }

  Future<void> clear() => _box.delete(_key);

  Future<void> remove(String name) async {
    final lower = name.trim().toLowerCase();
    final filtered = getRecent()
        .where((n) => n.toLowerCase() != lower)
        .toList();
    await _box.put(_key, filtered);
  }
}
