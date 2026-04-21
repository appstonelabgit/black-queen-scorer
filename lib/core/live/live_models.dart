/// Read-only view of a live session as returned from Firebase Realtime DB.
class LiveSessionState {
  final String code;
  final bool finished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;
  final List<String> players;
  final Map<String, int> scores;
  final int roundCount;
  final int bonus;
  final LiveRound? lastRound;

  const LiveSessionState({
    required this.code,
    required this.finished,
    required this.createdAt,
    required this.updatedAt,
    required this.finishedAt,
    required this.players,
    required this.scores,
    required this.roundCount,
    required this.bonus,
    required this.lastRound,
  });

  factory LiveSessionState.fromJson(String code, Map<dynamic, dynamic> json) {
    final players =
        (json['players'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final scoresRaw = Map<String, dynamic>.from(json['scores'] as Map? ?? {});
    final scores = scoresRaw.map((k, v) => MapEntry(k, (v as num).toInt()));
    final rounds = (json['rounds'] as List?) ?? const [];
    final lastRoundRaw =
        rounds.isEmpty ? null : Map<String, dynamic>.from(rounds.last as Map);

    return LiveSessionState(
      code: code,
      finished: json['finishedAt'] != null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['updatedAt'] as num?)?.toInt() ?? 0),
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json['finishedAt'] as num).toInt()),
      players: players,
      scores: scores,
      roundCount: rounds.length,
      bonus: (json['bonus'] as num?)?.toInt() ?? 0,
      lastRound: lastRoundRaw == null ? null : LiveRound.fromJson(lastRoundRaw),
    );
  }
}

class LiveRound {
  final String bidder;
  final List<String> bidTeam;
  final int bid;
  final bool won;
  final Map<String, int> delta;

  const LiveRound({
    required this.bidder,
    required this.bidTeam,
    required this.bid,
    required this.won,
    required this.delta,
  });

  factory LiveRound.fromJson(Map<String, dynamic> json) {
    final d = Map<String, dynamic>.from(json['delta'] as Map? ?? {});
    return LiveRound(
      bidder: json['bidder'] as String? ?? '',
      bidTeam: (json['bidTeam'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      bid: (json['bid'] as num?)?.toInt() ?? 0,
      won: json['won'] as bool? ?? false,
      delta: d.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}
