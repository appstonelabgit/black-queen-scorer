import 'package:hive/hive.dart';

import 'round.dart';
import 'session.dart';
import 'session_settings.dart';

/// Marks a Round record written in the v2 (versioned) format. Legacy records
/// begin with the UUID's byte-length (36) as their first uint32, so this
/// sentinel — an impossible string length — is never produced by old data.
/// On read, seeing it means "v2"; anything else means "legacy, and that value
/// was actually the id's byte-length."
const int _kRoundV2Marker = 0xFFFFFFFF;

class RoundAdapter extends TypeAdapter<Round> {
  @override
  final int typeId = 1;

  @override
  Round read(BinaryReader reader) {
    final head = reader.readUint32();
    if (head == _kRoundV2Marker) {
      return _readV2(reader);
    }
    return _readLegacy(reader, idByteCount: head);
  }

  // Legacy layout (unchanged, byte-for-byte): id, bidder, teamLen, team[],
  // bidAmount(Int32), won(Bool), createdAt(Int). `head` already consumed the
  // id's uint32 length prefix, so read exactly that many bytes for the id.
  Round _readLegacy(BinaryReader reader, {required int idByteCount}) {
    final id = reader.readString(idByteCount);
    final bidder = reader.readString();
    final teamLen = reader.readUint32();
    final team = List<String>.generate(teamLen, (_) => reader.readString());
    final bidAmount = reader.readInt32();
    final won = reader.readBool();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return Round(
      id: id,
      bidder: bidder,
      team: List.unmodifiable(team),
      bidAmount: bidAmount,
      won: won,
      createdAt: createdAt,
    );
  }

  // v2 layout: marker(already read), isFree(Bool), id, createdAt(Int), then
  // either the free-score map or the bid fields.
  Round _readV2(BinaryReader reader) {
    final isFree = reader.readBool();
    final id = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    if (isFree) {
      final n = reader.readUint32();
      final scores = <String, int>{};
      for (var i = 0; i < n; i++) {
        final name = reader.readString();
        scores[name] = reader.readInt32();
      }
      return Round(
        id: id,
        bidder: '',
        team: const [],
        bidAmount: 0,
        won: false,
        createdAt: createdAt,
        scores: Map.unmodifiable(scores),
      );
    }
    final bidder = reader.readString();
    final teamLen = reader.readUint32();
    final team = List<String>.generate(teamLen, (_) => reader.readString());
    final bidAmount = reader.readInt32();
    final won = reader.readBool();
    return Round(
      id: id,
      bidder: bidder,
      team: List.unmodifiable(team),
      bidAmount: bidAmount,
      won: won,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, Round obj) {
    // Always write v2. Legacy records stay readable via the marker branch.
    writer.writeUint32(_kRoundV2Marker);
    writer.writeBool(obj.isFree);
    writer.writeString(obj.id);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    if (obj.isFree) {
      final scores = obj.scores!;
      writer.writeUint32(scores.length);
      for (final e in scores.entries) {
        writer.writeString(e.key);
        writer.writeInt32(e.value);
      }
      return;
    }
    writer.writeString(obj.bidder);
    writer.writeUint32(obj.team.length);
    for (final p in obj.team) {
      writer.writeString(p);
    }
    writer.writeInt32(obj.bidAmount);
    writer.writeBool(obj.won);
  }
}

/// Marks a SessionSettings record written in v2 format. The legacy first byte
/// is a bool (0 or 1), so this value can never begin old data. On read, seeing
/// it means "v2"; otherwise the byte was the legacy `bonusEnabled` bool.
const int _kSettingsV2Marker = 0xFE;

class SessionSettingsAdapter extends TypeAdapter<SessionSettings> {
  @override
  final int typeId = 2;

  @override
  SessionSettings read(BinaryReader reader) {
    final head = reader.readByte();
    if (head == _kSettingsV2Marker) {
      final bonusEnabled = reader.readBool();
      final bonusAmount = reader.readInt32();
      final modeIdx = reader.readByte();
      final mode = modeIdx < ScoreMode.values.length
          ? ScoreMode.values[modeIdx]
          : ScoreMode.bid;
      return SessionSettings(
        bonusEnabled: bonusEnabled,
        bonusAmount: bonusAmount,
        mode: mode,
      );
    }
    // Legacy: `head` was the bonusEnabled bool; amount follows; mode defaults.
    final bonusAmount = reader.readInt32();
    return SessionSettings(
      bonusEnabled: head != 0,
      bonusAmount: bonusAmount,
    );
  }

  @override
  void write(BinaryWriter writer, SessionSettings obj) {
    writer.writeByte(_kSettingsV2Marker);
    writer.writeBool(obj.bonusEnabled);
    writer.writeInt32(obj.bonusAmount);
    writer.writeByte(obj.mode.index);
  }
}

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 3;

  @override
  Session read(BinaryReader reader) {
    final id = reader.readString();
    final startedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasFinished = reader.readBool();
    final finishedAt = hasFinished
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final playersLen = reader.readUint32();
    final players =
        List<String>.generate(playersLen, (_) => reader.readString());
    final settings = SessionSettingsAdapter().read(reader);
    final roundsLen = reader.readUint32();
    final rounds = List<Round>.generate(
      roundsLen,
      (_) => RoundAdapter().read(reader),
    );
    return Session(
      id: id,
      startedAt: startedAt,
      finishedAt: finishedAt,
      players: List.unmodifiable(players),
      settings: settings,
      rounds: rounds,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.startedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.finishedAt != null);
    if (obj.finishedAt != null) {
      writer.writeInt(obj.finishedAt!.millisecondsSinceEpoch);
    }
    writer.writeUint32(obj.players.length);
    for (final p in obj.players) {
      writer.writeString(p);
    }
    SessionSettingsAdapter().write(writer, obj.settings);
    writer.writeUint32(obj.rounds.length);
    for (final r in obj.rounds) {
      RoundAdapter().write(writer, r);
    }
  }
}
