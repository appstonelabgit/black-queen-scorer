import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// One live game the user has watched, persisted so they can re-open it
/// without re-entering the code after closing the app.
@immutable
class ViewedLiveGame {
  final String code;
  final List<String> players;
  final DateTime lastViewedAt;
  final bool finished;

  const ViewedLiveGame({
    required this.code,
    required this.players,
    required this.lastViewedAt,
    required this.finished,
  });

  int get playerCount => players.length;

  Map<String, dynamic> toJson() => {
        'code': code,
        'players': players,
        'lastViewedAt': lastViewedAt.millisecondsSinceEpoch,
        'finished': finished,
      };

  factory ViewedLiveGame.fromJson(Map<String, dynamic> json) => ViewedLiveGame(
        code: json['code'] as String? ?? '',
        players: (json['players'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        lastViewedAt: DateTime.fromMillisecondsSinceEpoch(
            (json['lastViewedAt'] as num?)?.toInt() ?? 0),
        finished: json['finished'] as bool? ?? false,
      );
}

/// Stores the codes of live games the user has watched, newest first.
/// Keyed by code so re-watching a game updates its entry in place rather
/// than duplicating it. Capped so the list never grows unbounded.
class LiveViewHistory {
  static const _boxName = 'live_view_history';
  static const _maxEntries = 25;

  static LiveViewHistory? _instance;
  static LiveViewHistory get instance => _instance ??= LiveViewHistory._();
  LiveViewHistory._();

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// A [Listenable] the UI can rebuild against when entries change.
  Listenable get listenable =>
      _box?.listenable() ?? const _NeverNotifies();

  /// Viewed games, most recently watched first.
  List<ViewedLiveGame> recent() {
    final box = _box;
    if (box == null) return const [];
    final games = <ViewedLiveGame>[];
    for (final raw in box.values) {
      try {
        games.add(
            ViewedLiveGame.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip a corrupt entry rather than break the whole list.
      }
    }
    games.sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));
    return games;
  }

  /// Records (or refreshes) a watched game. Updates the players/finished
  /// snapshot and bumps it to the top, then prunes the oldest beyond the cap.
  Future<void> record({
    required String code,
    required List<String> players,
    required bool finished,
  }) async {
    final box = _box;
    if (box == null) return;
    final entry = ViewedLiveGame(
      code: code,
      players: players,
      lastViewedAt: DateTime.now(),
      finished: finished,
    );
    await box.put(code, jsonEncode(entry.toJson()));
    await _prune();
  }

  Future<void> remove(String code) async => _box?.delete(code);

  Future<void> clear() async => _box?.clear();

  Future<void> _prune() async {
    final box = _box;
    if (box == null || box.length <= _maxEntries) return;
    final ordered = recent();
    for (final stale in ordered.skip(_maxEntries)) {
      await box.delete(stale.code);
    }
  }
}

/// Stand-in [Listenable] for when the box failed to open — never fires.
class _NeverNotifies extends Listenable {
  const _NeverNotifies();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
