import 'package:flutter_test/flutter_test.dart';

import 'package:black_queen_scorer/data/models/round.dart';
import 'package:black_queen_scorer/data/models/session.dart';
import 'package:black_queen_scorer/data/models/session_settings.dart';
import 'package:black_queen_scorer/data/scoring.dart';

Session _freeSession(List<String> players, List<Map<String, int>> rounds) {
  return Session(
    id: 'free-sess',
    startedAt: DateTime(2026, 1, 1, 10),
    finishedAt: DateTime(2026, 1, 1, 11),
    players: players,
    settings: const SessionSettings(
        bonusEnabled: false, bonusAmount: 0, mode: ScoreMode.free),
    rounds: [for (final r in rounds) Round.free(scores: r)],
  );
}

void main() {
  group('free-score computeScores', () {
    test('accumulates per-player points across rounds, incl. negatives', () {
      final s = _freeSession(['Asha', 'Ravi', 'Meera'], [
        {'Asha': 10, 'Ravi': 4, 'Meera': -2},
        {'Asha': -5, 'Ravi': 8, 'Meera': 3},
      ]);
      expect(computeScores(s), {'Asha': 5, 'Ravi': 12, 'Meera': 1});
    });

    test('a player missing from a round scores 0 for that round', () {
      final s = _freeSession(['Asha', 'Ravi'], [
        {'Asha': 7}, // Ravi absent
      ]);
      expect(computeScores(s), {'Asha': 7, 'Ravi': 0});
    });

    test('ignores the caller bonus even if settings carried one', () {
      final s = Session(
        id: 'x',
        startedAt: DateTime(2026, 1, 1, 10),
        finishedAt: DateTime(2026, 1, 1, 11),
        players: ['Asha', 'Ravi'],
        // bonus enabled but mode free → bonus must not apply.
        settings: const SessionSettings(
            bonusEnabled: true, bonusAmount: 100, mode: ScoreMode.free),
        rounds: [
          Round.free(scores: {'Asha': 3, 'Ravi': 1}),
        ],
      );
      expect(computeScores(s), {'Asha': 3, 'Ravi': 1});
    });
  });

  group('free-score computeRoundDelta', () {
    test('returns the entered numbers, 0 for players not in the round', () {
      final s = _freeSession(['Asha', 'Ravi', 'Meera'], [
        {'Asha': 6, 'Meera': -4},
      ]);
      final delta = computeRoundDelta(s.rounds.single, s);
      expect(delta, {'Asha': 6, 'Ravi': 0, 'Meera': -4});
    });
  });

  group('free-score computeStats', () {
    test('bid-only stats are null; swing stats + ranking still work', () {
      final s = _freeSession(['Asha', 'Ravi'], [
        {'Asha': 10, 'Ravi': -3},
        {'Asha': -1, 'Ravi': 20},
      ]);
      final stats = computeStats(s);

      expect(stats.mostBidsWon, isNull);
      expect(stats.longestWinStreak, isNull);
      expect(stats.boldestBidder, isNull);

      // Ravi ends on 17, Asha on 9.
      expect(stats.ranked.first.name, 'Ravi');
      expect(stats.ranked.first.score, 17);
      expect(stats.totalRounds, 2);

      // Biggest single-round swing = Ravi +20 in round 2.
      expect(stats.biggestSingleGain?.name, 'Ravi');
      expect(stats.biggestSingleGain?.amount, 20);
      expect(stats.biggestSingleGain?.round, 2);
      // Biggest loss = Ravi -3 in round 1.
      expect(stats.biggestSingleLoss?.amount, -3);
    });
  });

  group('free-score lifetime aggregates', () {
    test('free session contributes net + swings, no caller pollution', () {
      final s = _freeSession(['Asha', 'Ravi'], [
        {'Asha': 12, 'Ravi': 5},
      ]);
      final lifetimes = computePlayerLifetimes([s]);
      final asha = lifetimes.firstWhere((p) => p.name == 'Asha');
      expect(asha.net, 12);
      expect(asha.callsMade, 0, reason: 'free rounds are not calls');
      expect(asha.bestRound, 12);
    });
  });
}
