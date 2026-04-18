import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Round {
  final String id;
  final String bidder;
  final List<String> team;
  final int bidAmount;
  final bool won;
  final DateTime createdAt;

  Round({
    required this.id,
    required this.bidder,
    required this.team,
    required this.bidAmount,
    required this.won,
    required this.createdAt,
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

  Round copyWith({
    String? bidder,
    List<String>? team,
    int? bidAmount,
    bool? won,
  }) {
    return Round(
      id: id,
      bidder: bidder ?? this.bidder,
      team: team ?? this.team,
      bidAmount: bidAmount ?? this.bidAmount,
      won: won ?? this.won,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bidder': bidder,
        'team': team,
        'bidAmount': bidAmount,
        'won': won,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        id: json['id'] as String,
        bidder: json['bidder'] as String,
        team: List<String>.from(json['team'] as List),
        bidAmount: json['bidAmount'] as int,
        won: json['won'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
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
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, bidder, Object.hashAll(team), bidAmount, won, createdAt);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
