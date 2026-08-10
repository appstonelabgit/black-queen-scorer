// Backward-compatibility guard for the Hive binary adapters.
//
// The proven bid-contract data written by shipped versions MUST keep reading
// byte-identical after free-score mode was added. These tests write bytes in
// the *legacy* (pre-v2) layout by hand and assert the current adapters read
// them correctly, plus round-trip the new v2 (bid + free) records.
//
// Imports reach into hive's `src/` for the concrete binary buffer impls — the
// standard approach for unit-testing TypeAdapters without spinning up a box.
// ignore_for_file: implementation_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

import 'package:scorewise/data/models/adapters.dart';
import 'package:scorewise/data/models/round.dart';
import 'package:scorewise/data/models/session.dart';
import 'package:scorewise/data/models/session_settings.dart';

BinaryWriterImpl _writer() => BinaryWriterImpl(TypeRegistryImpl());
BinaryReader _reader(List<int> bytes) =>
    BinaryReaderImpl(bytes as dynamic, TypeRegistryImpl());

// --- Legacy writers: byte-for-byte copies of the pre-v2 adapter.write code ---

void _writeLegacyRound(
  BinaryWriter w, {
  required String id,
  required String bidder,
  required List<String> team,
  required int bidAmount,
  required bool won,
  required int createdMs,
}) {
  w.writeString(id);
  w.writeString(bidder);
  w.writeUint32(team.length);
  for (final p in team) {
    w.writeString(p);
  }
  w.writeInt32(bidAmount);
  w.writeBool(won);
  w.writeInt(createdMs);
}

void _writeLegacySettings(
  BinaryWriter w, {
  required bool bonusEnabled,
  required int bonusAmount,
}) {
  w.writeBool(bonusEnabled);
  w.writeInt32(bonusAmount);
}

void main() {
  group('RoundAdapter legacy read', () {
    test('reads a shipped bid round unchanged (scores stays null)', () {
      final w = _writer();
      final created = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      _writeLegacyRound(
        w,
        id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', // 36-char UUID
        bidder: 'Asha',
        team: ['Asha', 'Ravi'],
        bidAmount: 7,
        won: true,
        createdMs: created.millisecondsSinceEpoch,
      );

      final r = RoundAdapter().read(_reader(w.toBytes()));

      expect(r.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(r.bidder, 'Asha');
      expect(r.team, ['Asha', 'Ravi']);
      expect(r.bidAmount, 7);
      expect(r.won, isTrue);
      expect(r.createdAt, created);
      expect(r.scores, isNull, reason: 'legacy record must be a bid round');
      expect(r.isFree, isFalse);
    });
  });

  group('RoundAdapter v2 round-trip', () {
    test('bid round survives write -> read', () {
      final original = Round(
        id: 'bid-id-000000000000000000000000000000',
        bidder: 'Meera',
        team: ['Meera', 'Sam'],
        bidAmount: 9,
        won: false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000001000),
      );
      final w = _writer();
      RoundAdapter().write(w, original);
      final r = RoundAdapter().read(_reader(w.toBytes()));
      expect(r, original);
      expect(r.scores, isNull);
    });

    test('free-score round survives write -> read', () {
      final original = Round.free(scores: {'Meera': 12, 'Sam': -3, 'Ravi': 0});
      final w = _writer();
      RoundAdapter().write(w, original);
      final r = RoundAdapter().read(_reader(w.toBytes()));
      expect(r.isFree, isTrue);
      expect(r.scores, {'Meera': 12, 'Sam': -3, 'Ravi': 0});
      expect(r.id, original.id);
      // Adapter stores millisecond precision (always has, bid and free alike).
      expect(r.createdAt.millisecondsSinceEpoch,
          original.createdAt.millisecondsSinceEpoch);
    });
  });

  group('SessionSettingsAdapter legacy read', () {
    test('reads shipped settings, defaults mode to bid', () {
      final w = _writer();
      _writeLegacySettings(w, bonusEnabled: true, bonusAmount: 500);
      final s = SessionSettingsAdapter().read(_reader(w.toBytes()));
      expect(s.bonusEnabled, isTrue);
      expect(s.bonusAmount, 500);
      expect(s.mode, ScoreMode.bid);
    });

    test('reads shipped settings with bonus disabled', () {
      final w = _writer();
      _writeLegacySettings(w, bonusEnabled: false, bonusAmount: 0);
      final s = SessionSettingsAdapter().read(_reader(w.toBytes()));
      expect(s.bonusEnabled, isFalse);
      expect(s.bonusAmount, 0);
      expect(s.mode, ScoreMode.bid);
    });
  });

  group('SessionSettingsAdapter v2 round-trip', () {
    test('free mode survives write -> read', () {
      const original =
          SessionSettings(bonusEnabled: false, bonusAmount: 0, mode: ScoreMode.free);
      final w = _writer();
      SessionSettingsAdapter().write(w, original);
      final s = SessionSettingsAdapter().read(_reader(w.toBytes()));
      expect(s, original);
      expect(s.mode, ScoreMode.free);
    });
  });

  group('SessionAdapter end-to-end legacy read', () {
    test('a full legacy session (settings + rounds) reads as a bid session', () {
      final w = _writer();
      final started = DateTime.fromMillisecondsSinceEpoch(1699999990000);
      final created = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      // Mirror the original SessionAdapter.write byte layout exactly.
      w.writeString('sess-id-0000000000000000000000000000');
      w.writeInt(started.millisecondsSinceEpoch);
      w.writeBool(false); // no finishedAt
      w.writeUint32(2);
      w.writeString('Asha');
      w.writeString('Ravi');
      _writeLegacySettings(w, bonusEnabled: true, bonusAmount: 250);
      w.writeUint32(1);
      _writeLegacyRound(
        w,
        id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        bidder: 'Asha',
        team: ['Asha', 'Ravi'],
        bidAmount: 5,
        won: true,
        createdMs: created.millisecondsSinceEpoch,
      );

      final s = SessionAdapter().read(_reader(w.toBytes()));

      expect(s.id, 'sess-id-0000000000000000000000000000');
      expect(s.startedAt, started);
      expect(s.finishedAt, isNull);
      expect(s.players, ['Asha', 'Ravi']);
      expect(s.settings.bonusEnabled, isTrue);
      expect(s.settings.bonusAmount, 250);
      expect(s.settings.mode, ScoreMode.bid);
      expect(s.rounds, hasLength(1));
      expect(s.rounds.single.bidAmount, 5);
      expect(s.rounds.single.won, isTrue);
      expect(s.rounds.single.scores, isNull);
    });
  });

  group('SessionAdapter v2 round-trip', () {
    test('a free-score session survives write -> read', () {
      final original = Session.create(
        players: ['Asha', 'Ravi', 'Meera'],
        settings: const SessionSettings(
            bonusEnabled: false, bonusAmount: 0, mode: ScoreMode.free),
      ).copyWith(rounds: [
        Round.free(scores: {'Asha': 10, 'Ravi': 4, 'Meera': -2}),
      ]);

      final w = _writer();
      SessionAdapter().write(w, original);
      final s = SessionAdapter().read(_reader(w.toBytes()));

      expect(s.settings.mode, ScoreMode.free);
      expect(s.rounds, hasLength(1));
      expect(s.rounds.single.scores, {'Asha': 10, 'Ravi': 4, 'Meera': -2});
    });
  });
}
