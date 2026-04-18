import 'package:flutter_test/flutter_test.dart';
import 'package:black_queen_scorer/data/models/round.dart';
import 'package:black_queen_scorer/data/models/session.dart';
import 'package:black_queen_scorer/data/models/session_settings.dart';
import 'package:black_queen_scorer/data/scoring.dart';

Session _session({
  required List<String> players,
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

Round _r({
  required String bidder,
  required List<String> team,
  required int bid,
  required bool won,
}) =>
    Round(
      id: 'r',
      bidder: bidder,
      team: team,
      bidAmount: bid,
      won: won,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('all players on bidder\'s team (no opposition) — math runs safely', () {
    final s = _session(
      players: ['A', 'B', 'C', 'D'],
      rounds: [
        _r(bidder: 'A', team: ['A', 'B', 'C', 'D'], bid: 300, won: true),
      ],
    );
    final scores = computeScores(s);
    // Everyone on the team, nobody to lose — all +300.
    expect(scores.values.every((v) => v == 300), isTrue);
  });

  test('bid of 1', () {
    final s = _session(
      players: ['A', 'B', 'C', 'D'],
      rounds: [
        _r(bidder: 'A', team: ['A'], bid: 1, won: true),
      ],
    );
    final scores = computeScores(s);
    expect(scores['A'], 1);
    expect(scores['B'], -1);
  });

  test('bid of 99999', () {
    final s = _session(
      players: ['A', 'B', 'C', 'D'],
      rounds: [
        _r(bidder: 'A', team: ['A', 'B'], bid: 99999, won: false),
      ],
    );
    final scores = computeScores(s);
    expect(scores['A'], -99999);
    expect(scores['C'], 99999);
  });
}
