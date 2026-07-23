import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Round {
  final String id;
  final String bidder;
  final List<String> team;
  final int bidAmount;
  final bool won;
  final DateTime createdAt;

  /// Free-score payload: per-player points for this round. `null` means this is
  /// a bid round (the original engine). Non-null means a free-score round, in
  /// which case [bidder]/[team]/[bidAmount]/[won] are unused (kept at defaults).
  final Map<String, int>? scores;

  Round({
    required this.id,
    required this.bidder,
    required this.team,
    required this.bidAmount,
    required this.won,
    required this.createdAt,
    this.scores,
  });

  factory Round.create({
    required String bidder,
    required List<String> team,
    required int bidAmount,
    required bool won,
  }) {
    final normalisedTeam = <String>[];
    normalisedTeam.add(bidder);
    for (final p in team) {
      if (p != bidder && !normalisedTeam.contains(p)) {
        normalisedTeam.add(p);
      }
    }
    return Round(
      id: _uuid.v4(),
      bidder: bidder,
      team: List.unmodifiable(normalisedTeam),
      bidAmount: bidAmount,
      won: won,
      createdAt: DateTime.now(),
    );
  }

  /// Builds a free-score round from a per-player points map.
  factory Round.free({required Map<String, int> scores}) => Round(
        id: _uuid.v4(),
        bidder: '',
        team: const [],
        bidAmount: 0,
        won: false,
        createdAt: DateTime.now(),
        scores: Map.unmodifiable(scores),
      );

  /// True when this is a free-score round rather than a bid round.
  bool get isFree => scores != null;

  Round copyWith({
    String? bidder,
    List<String>? team,
    int? bidAmount,
    bool? won,
    Map<String, int>? scores,
  }) {
    return Round(
      id: id,
      bidder: bidder ?? this.bidder,
      team: team ?? this.team,
      bidAmount: bidAmount ?? this.bidAmount,
      won: won ?? this.won,
      createdAt: createdAt,
      scores: scores ?? this.scores,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bidder': bidder,
        'team': team,
        'bidAmount': bidAmount,
        'won': won,
        'createdAt': createdAt.toIso8601String(),
        if (scores != null) 'scores': scores,
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        id: json['id'] as String,
        bidder: json['bidder'] as String,
        team: List<String>.from(json['team'] as List),
        bidAmount: json['bidAmount'] as int,
        won: json['won'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        scores: json['scores'] == null
            ? null
            : Map<String, int>.from(json['scores'] as Map),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Round &&
        other.id == id &&
        other.bidder == bidder &&
        _listEq(other.team, team) &&
        other.bidAmount == bidAmount &&
        other.won == won &&
        other.createdAt == createdAt &&
        _mapEq(other.scores, scores);
  }

  @override
  int get hashCode => Object.hash(
        id,
        bidder,
        Object.hashAll(team),
        bidAmount,
        won,
        createdAt,
        scores == null ? null : Object.hashAll(_sortedScoreEntries(scores!)),
      );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map<String, int>? a, Map<String, int>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

List<Object> _sortedScoreEntries(Map<String, int> m) {
  final keys = m.keys.toList()..sort();
  return [for (final k in keys) '$k=${m[k]}'];
}
