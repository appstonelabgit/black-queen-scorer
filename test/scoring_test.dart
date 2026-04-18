import 'package:flutter_test/flutter_test.dart';
import 'package:black_queen_scorer/data/models/round.dart';
import 'package:black_queen_scorer/data/models/session.dart';
import 'package:black_queen_scorer/data/models/session_settings.dart';
import 'package:black_queen_scorer/data/scoring.dart';

Session _session({
  List<String> players = const ['A', 'B', 'C', 'D', 'E'],
  SessionSettings settings = const SessionSettings.disabled(),
  List<Round> rounds = const [],
}) =>
    Session(
      id: 'sess',
      startedAt: DateTime(2026, 1, 1),
      finishedAt: null,
      players: players,
      settings: settings,
      rounds: rounds,
    );

Round _round({
  required String bidder,
  required List<String> team,
  required int bid,
  required bool won,
  String id = 'r',
  DateTime? createdAt,
}) =>
    Round(
      id: id,
      bidder: bidder,
      team: team,
      bidAmount: bid,
      won: won,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );

void main() {
  group('computeScores', () {
    test('empty session → all zeros', () {
      final s = _session();
      final scores = computeScores(s);
      expect(scores.values.every((v) => v == 0), isTrue);
      expect(scores.length, 5);
    });

    test('single round win, no bonus', () {
      final s = _session(rounds: [
        _round(bidder: 'A', team: ['A', 'B'], bid: 700, won: true),
      ]);
      final scores = computeScores(s);
      expect(scores['A'], 700);
      expect(scores['B'], 700);
      expect(scores['C'], -700);
      expect(scores['D'], -700);
      expect(scores['E'], -700);
    });

    test('single round win, with bonus (bidder only)', () {
      final s = _session(
        settings: const SessionSettings(bonusEnabled: true, bonusAmount: 100),
        rounds: [
          _round(bidder: 'A', team: ['A', 'B'], bid: 700, won: true),
        ],
      );
      final scores = computeScores(s);
      expect(scores['A'], 800);
      expect(scores['B'], 700);
      expect(scores['C'], -700);
      expect(scores['D'], -700);
      expect(scores['E'], -700);
    });

    test('single round loss, with bonus', () {
      final s = _session(
        settings: const SessionSettings(bonusEnabled: true, bonusAmount: 100),
        rounds: [
          _round(bidder: 'A', team: ['A', 'B'], bid: 700, won: false),
        ],
      );
      final scores = computeScores(s);
      expect(scores['A'], -800);
      expect(scores['B'], -700);
      expect(scores['C'], 700);
      expect(scores['D'], 700);
      expect(scores['E'], 700);
    });

    test('multi-round, same player bids twice with different outcomes', () {
      final s = _session(
        settings: const SessionSettings(bonusEnabled: true, bonusAmount: 50),
        rounds: [
          _round(
              bidder: 'A', team: ['A', 'B'], bid: 500, won: true, id: 'r1'),
          _round(
              bidder: 'A', team: ['A', 'C'], bid: 600, won: false, id: 'r2'),
        ],
      );
      final scores = computeScores(s);
      // Round 1 (win): A=+500+50=+550, B=+500, C=-500, D=-500, E=-500
      // Round 2 (loss): A=-600-50=-650, B=+600, C=-600, D=+600, E=+600
      // Totals: A=-100, B=+1100, C=-1100, D=+100, E=+100
      expect(scores['A'], -100);
      expect(scores['B'], 1100);
      expect(scores['C'], -1100);
      expect(scores['D'], 100);
      expect(scores['E'], 100);
    });

    test('bidder alone (team of 1)', () {
      final s = _session(
        settings: const SessionSettings(bonusEnabled: true, bonusAmount: 100),
        rounds: [
          _round(bidder: 'A', team: ['A'], bid: 650, won: false),
        ],
      );
      final scores = computeScores(s);
      expect(scores['A'], -750);
      expect(scores['B'], 650);
      expect(scores['C'], 650);
    });
  });

  group('computeRoundDelta', () {
    test('matches the worked example — win', () {
      final s = _session(
        settings: const SessionSettings(bonusEnabled: true, bonusAmount: 100),
      );
      final r = _round(bidder: 'A', team: ['A', 'B'], bid: 700, won: true);
      final d = computeRoundDelta(r, s);
      expect(d['A'], 800);
      expect(d['B'], 700);
      expect(d['C'], -700);
      expect(d['D'], -700);
      expect(d['E'], -700);
    });
  });

  group('computeStats', () {
    test('empty session — all zeros, no stats', () {
      final s = _session();
      final stats = computeStats(s);
      expect(stats.totalRounds, 0);
      expect(stats.mostBidsWon, isNull);
      expect(stats.biggestSingleGain, isNull);
      expect(stats.biggestSingleLoss, isNull);
      expect(stats.ranked.every((p) => p.score == 0), isTrue);
    });

    test('biggest gain and loss identified', () {
      final s = _session(
        rounds: [
          _round(
              bidder: 'A', team: ['A', 'B'], bid: 500, won: true, id: 'r1'),
          _round(
              bidder: 'C', team: ['C', 'D'], bid: 900, won: true, id: 'r2'),
        ],
      );
      final stats = computeStats(s);
      // Round 2 wins are the bigger gain (+900 to C, D).
      expect(stats.biggestSingleGain!.amount, 900);
      expect(stats.biggestSingleGain!.round, 2);
      // Biggest single loss is -900 (round 2 losers).
      expect(stats.biggestSingleLoss!.amount, -900);
      expect(stats.biggestSingleLoss!.round, 2);
    });

    test('longest win streak', () {
      final s = _session(
        rounds: [
          // A on winning team 3 times in a row.
          _round(
              bidder: 'A', team: ['A', 'B'], bid: 100, won: true, id: 'r1'),
          _round(
              bidder: 'A', team: ['A', 'C'], bid: 100, won: true, id: 'r2'),
          _round(
              bidder: 'D', team: ['D', 'E'], bid: 100, won: false, id: 'r3'),
          // Round 3: D loses. Means A, B, C are on winning side.
        ],
      );
      final stats = computeStats(s);
      expect(stats.longestWinStreak!.name, 'A');
      expect(stats.longestWinStreak!.streak, 3);
    });

    test('most bids won', () {
      final s = _session(
        rounds: [
          _round(
              bidder: 'B', team: ['B', 'C'], bid: 200, won: true, id: 'r1'),
          _round(
              bidder: 'B', team: ['B', 'D'], bid: 200, won: true, id: 'r2'),
          _round(
              bidder: 'A', team: ['A', 'E'], bid: 200, won: false, id: 'r3'),
        ],
      );
      final stats = computeStats(s);
      expect(stats.mostBidsWon!.name, 'B');
      expect(stats.mostBidsWon!.count, 2);
    });
  });
}
