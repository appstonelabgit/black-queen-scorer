import 'package:uuid/uuid.dart';

import 'round.dart';
import 'session_settings.dart';

const _uuid = Uuid();

class Session {
  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<String> players;
  final SessionSettings settings;
  final List<Round> rounds;

  Session({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.players,
    required this.settings,
    required this.rounds,
  });

  factory Session.create({
    required List<String> players,
    required SessionSettings settings,
  }) {
    return Session(
      id: _uuid.v4(),
      startedAt: DateTime.now(),
      finishedAt: null,
      players: List.unmodifiable(players),
      settings: settings,
      rounds: const [],
    );
  }

  Session copyWith({
    DateTime? startedAt,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
    List<String>? players,
    SessionSettings? settings,
    List<Round>? rounds,
  }) {
    return Session(
      id: id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      players: players ?? this.players,
      settings: settings ?? this.settings,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'players': players,
        'settings': settings.toJson(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: (json['finishedAt'] as String?) == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        players: List<String>.from(json['players'] as List),
        settings:
            SessionSettings.fromJson(json['settings'] as Map<String, dynamic>),
        rounds: (json['rounds'] as List)
            .map((r) => Round.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.id == id &&
      other.startedAt == startedAt &&
      other.finishedAt == finishedAt &&
      _listEq(other.players, players) &&
      other.settings == settings &&
      _listEq(other.rounds, rounds);

  @override
  int get hashCode => Object.hash(
        id,
        startedAt,
        finishedAt,
        Object.hashAll(players),
        settings,
        Object.hashAll(rounds),
      );
}

extension SessionX on Session {
  bool get isActive => finishedAt == null;
  Duration get duration =>
      (finishedAt ?? DateTime.now()).difference(startedAt);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
