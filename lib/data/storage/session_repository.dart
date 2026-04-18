import 'dart:async';
import 'package:hive/hive.dart';

import '../models/session.dart';
import 'hive_boxes.dart';

abstract class SessionRepository {
  factory SessionRepository() => HiveSessionRepository();

  List<Session> getAll();
  Stream<List<Session>> watchAll();
  Session? getActive();
  Session? get(String id);
  Stream<Session?> watch(String id);
  Future<void> save(Session s);
  Future<void> delete(String id);
  Future<Session?> finish(String id);
}

class HiveSessionRepository implements SessionRepository {
  HiveSessionRepository()
      : _box = Hive.box<Session>(HiveBoxes.sessions);

  final Box<Session> _box;

  @override
  List<Session> getAll() {
    final items = _box.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return items;
  }

  @override
  Stream<List<Session>> watchAll() async* {
    yield getAll();
    await for (final _ in _box.watch()) {
      yield getAll();
    }
  }

  @override
  Session? getActive() {
    for (final s in _box.values) {
      if (s.finishedAt == null) return s;
    }
    return null;
  }

  @override
  Session? get(String id) => _box.get(id);

  @override
  Stream<Session?> watch(String id) async* {
    yield _box.get(id);
    await for (final event in _box.watch(key: id)) {
      if (event.deleted) {
        yield null;
      } else {
        yield event.value as Session?;
      }
    }
  }

  @override
  Future<void> save(Session s) => _box.put(s.id, s);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<Session?> finish(String id) async {
    final s = _box.get(id);
    if (s == null) return null;
    final updated = s.copyWith(finishedAt: DateTime.now());
    await _box.put(id, updated);
    return updated;
  }
}
