import 'package:flutter_test/flutter_test.dart';
import 'package:black_queen_scorer/data/models/round.dart';
import 'package:black_queen_scorer/data/models/session.dart';
import 'package:black_queen_scorer/data/models/session_settings.dart';

void main() {
  test('Round.create ensures bidder is in team', () {
    final r = Round.create(
      bidder: 'A',
      team: ['B', 'C'],
      bidAmount: 500,
      won: true,
    );
    expect(r.team.contains('A'), isTrue);
    expect(r.team.first, 'A');
  });

  test('Round.create dedupes bidder even if caller adds it', () {
    final r = Round.create(
      bidder: 'A',
      team: ['A', 'B'],
      bidAmount: 500,
      won: true,
    );
    expect(r.team.where((p) => p == 'A').length, 1);
  });

  test('Round copyWith preserves id and createdAt', () {
    final r = Round.create(
      bidder: 'A',
      team: ['B'],
      bidAmount: 100,
      won: true,
    );
    final r2 = r.copyWith(bidAmount: 500);
    expect(r2.id, r.id);
    expect(r2.createdAt, r.createdAt);
    expect(r2.bidAmount, 500);
  });

  test('Session.isActive reflects finishedAt correctly', () {
    final s = Session.create(
      players: ['A', 'B', 'C', 'D'],
      settings: const SessionSettings.disabled(),
    );
    expect(s.isActive, isTrue);
    final finished = s.copyWith(finishedAt: DateTime(2026, 1, 1));
    expect(finished.isActive, isFalse);
  });

  test('Round toJson / fromJson round-trips', () {
    final r = Round.create(
      bidder: 'A',
      team: ['B', 'C'],
      bidAmount: 700,
      won: false,
    );
    final restored = Round.fromJson(r.toJson());
    expect(restored, r);
  });
}
