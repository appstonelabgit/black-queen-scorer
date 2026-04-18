import 'package:hive/hive.dart';

import 'round.dart';
import 'session.dart';
import 'session_settings.dart';

class RoundAdapter extends TypeAdapter<Round> {
  @override
  final int typeId = 1;

  @override
  Round read(BinaryReader reader) {
    final id = reader.readString();
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

  @override
  void write(BinaryWriter writer, Round obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.bidder);
    writer.writeUint32(obj.team.length);
    for (final p in obj.team) {
      writer.writeString(p);
    }
    writer.writeInt32(obj.bidAmount);
    writer.writeBool(obj.won);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}

class SessionSettingsAdapter extends TypeAdapter<SessionSettings> {
  @override
  final int typeId = 2;

  @override
  SessionSettings read(BinaryReader reader) {
    final bonusEnabled = reader.readBool();
    final bonusAmount = reader.readInt32();
    return SessionSettings(
      bonusEnabled: bonusEnabled,
      bonusAmount: bonusAmount,
    );
  }

  @override
  void write(BinaryWriter writer, SessionSettings obj) {
    writer.writeBool(obj.bonusEnabled);
    writer.writeInt32(obj.bonusAmount);
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
