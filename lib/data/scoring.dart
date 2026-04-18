import 'models/round.dart';
import 'models/session.dart';

/// Computes each player's total score for a session.
/// Iterates all rounds and applies the scoring rules.
/// This is the single source of truth for scores. Never cache.
Map<String, int> computeScores(Session session) {
  final scores = <String, int>{
    for (final p in session.players) p: 0,
  };
  final bonus = session.settings.effectiveBonus;
  for (final round in session.rounds) {
    _applyRound(round, session.players, bonus, scores);
  }
  return scores;
}

/// Computes the score delta for a single round, per player.
Map<String, int> computeRoundDelta(Round round, Session session) {
  final deltas = <String, int>{
    for (final p in session.players) p: 0,
  };
  final bonus = session.settings.effectiveBonus;
  _applyRound(round, session.players, bonus, deltas);
  return deltas;
}

void _applyRound(
  Round round,
  List<String> players,
  int bonus,
  Map<String, int> acc,
) {
  final bid = round.bidAmount;
  final teamSet = round.team.toSet();
  final teamSign = round.won ? 1 : -1;
  for (final p in players) {
    final onTeam = teamSet.contains(p);
    final delta = onTeam ? bid * teamSign : -bid * teamSign;
    acc[p] = (acc[p] ?? 0) + delta;
  }
  // Bonus for bidder only.
  if (bonus > 0) {
    acc[round.bidder] = (acc[round.bidder] ?? 0) + bonus * teamSign;
  }
}

/// Stats for the summary screen.
class PlayerScore {
  final String name;
  final int score;
  const PlayerScore(this.name, this.score);
}

class MostBidsWon {
  final String name;
  final int count;
  const MostBidsWon(this.name, this.count);
}

class BigSwing {
  final String name;
  final int amount;
  final int round;
  const BigSwing(this.name, this.amount, this.round);
}

class LongestStreak {
  final String name;
  final int streak;
  const LongestStreak(this.name, this.streak);
}

class BoldestBidder {
  final String name;
  final double avg;
  const BoldestBidder(this.name, this.avg);
}

class SessionStats {
  final List<PlayerScore> ranked;
  final MostBidsWon? mostBidsWon;
  final BigSwing? biggestSingleGain;
  final BigSwing? biggestSingleLoss;
  final LongestStreak? longestWinStreak;
  final BoldestBidder? boldestBidder;
  final int totalRounds;
  final Duration totalDuration;

  const SessionStats({
    required this.ranked,
    required this.mostBidsWon,
    required this.biggestSingleGain,
    required this.biggestSingleLoss,
    required this.longestWinStreak,
    required this.boldestBidder,
    required this.totalRounds,
    required this.totalDuration,
  });
}

SessionStats computeStats(Session session) {
  final scores = computeScores(session);
  final ranked = scores.entries
      .map((e) => PlayerScore(e.key, e.value))
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  MostBidsWon? mostBidsWon;
  BigSwing? biggestGain;
  BigSwing? biggestLoss;
  LongestStreak? longestWinStreak;
  BoldestBidder? boldestBidder;

  if (session.rounds.isNotEmpty) {
    final bidsWon = <String, int>{};
    for (final r in session.rounds) {
      if (r.won) bidsWon[r.bidder] = (bidsWon[r.bidder] ?? 0) + 1;
    }
    if (bidsWon.isNotEmpty) {
      final top = bidsWon.entries.reduce((a, b) => a.value >= b.value ? a : b);
      mostBidsWon = MostBidsWon(top.key, top.value);
    }

    for (var i = 0; i < session.rounds.length; i++) {
      final r = session.rounds[i];
      final deltas = computeRoundDelta(r, session);
      for (final entry in deltas.entries) {
        if (entry.value > 0) {
          if (biggestGain == null || entry.value > biggestGain.amount) {
            biggestGain = BigSwing(entry.key, entry.value, i + 1);
          }
        } else if (entry.value < 0) {
          if (biggestLoss == null || entry.value < biggestLoss.amount) {
            biggestLoss = BigSwing(entry.key, entry.value, i + 1);
          }
        }
      }
    }

    final streaks = <String, int>{for (final p in session.players) p: 0};
    final bestStreak = <String, int>{for (final p in session.players) p: 0};
    for (final r in session.rounds) {
      final teamSet = r.team.toSet();
      for (final p in session.players) {
        final onWinningSide =
            r.won ? teamSet.contains(p) : !teamSet.contains(p);
        if (onWinningSide) {
          streaks[p] = (streaks[p] ?? 0) + 1;
          if ((streaks[p] ?? 0) > (bestStreak[p] ?? 0)) {
            bestStreak[p] = streaks[p]!;
          }
        } else {
          streaks[p] = 0;
        }
      }
    }
    final topStreak =
        bestStreak.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (topStreak.isNotEmpty) {
      longestWinStreak =
          LongestStreak(topStreak.first.key, topStreak.first.value);
    }

    final bidTotals = <String, int>{};
    final bidCounts = <String, int>{};
    for (final r in session.rounds) {
      bidTotals[r.bidder] = (bidTotals[r.bidder] ?? 0) + r.bidAmount;
      bidCounts[r.bidder] = (bidCounts[r.bidder] ?? 0) + 1;
    }
    if (bidCounts.isNotEmpty) {
      final ranked = bidCounts.entries
          .map((e) => MapEntry(
              e.key, (bidTotals[e.key] ?? 0) / e.value))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      boldestBidder = BoldestBidder(ranked.first.key, ranked.first.value);
    }
  }

  return SessionStats(
    ranked: ranked,
    mostBidsWon: mostBidsWon,
    biggestSingleGain: biggestGain,
    biggestSingleLoss: biggestLoss,
    longestWinStreak: longestWinStreak,
    boldestBidder: boldestBidder,
    totalRounds: session.rounds.length,
    totalDuration: session.duration,
  );
}

class LifetimeTopEarner {
  final String name;
  final int total;
  const LifetimeTopEarner(this.name, this.total);
}

class MostSessionsWon {
  final String name;
  final int wins;
  const MostSessionsWon(this.name, this.wins);
}

class LifetimeStats {
  final int sessionsPlayed;
  final int totalRounds;
  final int uniquePlayers;
  final Duration totalPlayTime;
  final MostSessionsWon? mostSessionsWon;
  final LifetimeTopEarner? topEarner;
  final LifetimeTopEarner? biggestLoser;
  final MostBidsWon? mostBidsWon;
  final BigSwing? biggestSingleGain;
  final BigSwing? biggestSingleLoss;
  final BoldestBidder? boldestBidder;

  const LifetimeStats({
    required this.sessionsPlayed,
    required this.totalRounds,
    required this.uniquePlayers,
    required this.totalPlayTime,
    required this.mostSessionsWon,
    required this.topEarner,
    required this.biggestLoser,
    required this.mostBidsWon,
    required this.biggestSingleGain,
    required this.biggestSingleLoss,
    required this.boldestBidder,
  });

  bool get isEmpty => sessionsPlayed == 0;
}

LifetimeStats computeLifetimeStats(List<Session> sessions) {
  final finished = sessions.where((s) => s.finishedAt != null).toList();
  if (finished.isEmpty) {
    return const LifetimeStats(
      sessionsPlayed: 0,
      totalRounds: 0,
      uniquePlayers: 0,
      totalPlayTime: Duration.zero,
      mostSessionsWon: null,
      topEarner: null,
      biggestLoser: null,
      mostBidsWon: null,
      biggestSingleGain: null,
      biggestSingleLoss: null,
      boldestBidder: null,
    );
  }

  final uniquePlayers = <String, String>{};
  for (final s in finished) {
    for (final p in s.players) {
      uniquePlayers.putIfAbsent(p.toLowerCase(), () => p);
    }
  }

  final totalRounds = finished.fold<int>(0, (sum, s) => sum + s.rounds.length);
  final totalDuration = finished.fold<Duration>(
    Duration.zero,
    (sum, s) => sum + s.duration,
  );

  final sessionWins = <String, int>{};
  final cumulativeScore = <String, int>{};
  final bidsWon = <String, int>{};
  final bidTotals = <String, int>{};
  final bidCounts = <String, int>{};
  BigSwing? biggestGain;
  BigSwing? biggestLoss;

  for (final session in finished) {
    final scores = computeScores(session);
    int topScore = -1 << 62;
    String? topPlayer;
    for (final e in scores.entries) {
      cumulativeScore[e.key] =
          (cumulativeScore[e.key] ?? 0) + e.value;
      if (e.value > topScore) {
        topScore = e.value;
        topPlayer = e.key;
      }
    }
    if (topPlayer != null && scores[topPlayer]! != 0) {
      sessionWins[topPlayer] = (sessionWins[topPlayer] ?? 0) + 1;
    }

    for (var i = 0; i < session.rounds.length; i++) {
      final r = session.rounds[i];
      if (r.won) bidsWon[r.bidder] = (bidsWon[r.bidder] ?? 0) + 1;
      bidTotals[r.bidder] = (bidTotals[r.bidder] ?? 0) + r.bidAmount;
      bidCounts[r.bidder] = (bidCounts[r.bidder] ?? 0) + 1;

      final deltas = computeRoundDelta(r, session);
      for (final e in deltas.entries) {
        if (e.value > 0 &&
            (biggestGain == null || e.value > biggestGain.amount)) {
          biggestGain = BigSwing(e.key, e.value, i + 1);
        }
        if (e.value < 0 &&
            (biggestLoss == null || e.value < biggestLoss.amount)) {
          biggestLoss = BigSwing(e.key, e.value, i + 1);
        }
      }
    }
  }

  MostSessionsWon? mostSessionsWon;
  if (sessionWins.isNotEmpty) {
    final top =
        sessionWins.entries.reduce((a, b) => a.value >= b.value ? a : b);
    mostSessionsWon = MostSessionsWon(top.key, top.value);
  }

  LifetimeTopEarner? topEarner;
  LifetimeTopEarner? biggestLoser;
  if (cumulativeScore.isNotEmpty) {
    final sorted = cumulativeScore.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final bottom = sorted.last;
    if (top.value > 0) {
      topEarner = LifetimeTopEarner(top.key, top.value);
    }
    if (bottom.value < 0) {
      biggestLoser = LifetimeTopEarner(bottom.key, bottom.value);
    }
  }

  MostBidsWon? mostBidsWon;
  if (bidsWon.isNotEmpty) {
    final top = bidsWon.entries.reduce((a, b) => a.value >= b.value ? a : b);
    mostBidsWon = MostBidsWon(top.key, top.value);
  }

  BoldestBidder? boldestBidder;
  if (bidCounts.isNotEmpty) {
    final avgs = bidCounts.entries
        .map((e) => MapEntry(
            e.key, (bidTotals[e.key] ?? 0) / e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    boldestBidder = BoldestBidder(avgs.first.key, avgs.first.value);
  }

  return LifetimeStats(
    sessionsPlayed: finished.length,
    totalRounds: totalRounds,
    uniquePlayers: uniquePlayers.length,
    totalPlayTime: totalDuration,
    mostSessionsWon: mostSessionsWon,
    topEarner: topEarner,
    biggestLoser: biggestLoser,
    mostBidsWon: mostBidsWon,
    biggestSingleGain: biggestGain,
    biggestSingleLoss: biggestLoss,
    boldestBidder: boldestBidder,
  );
}
