import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/session.dart';
import 'storage/players_repository.dart';
import 'storage/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  return PlayersRepository();
});

final allSessionsStreamProvider = StreamProvider<List<Session>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchAll();
});

final activeSessionProvider = Provider<Session?>((ref) {
  final sessions = ref.watch(allSessionsStreamProvider).value ?? const [];
  for (final s in sessions) {
    if (s.finishedAt == null) return s;
  }
  return null;
});

final sessionByIdProvider =
    StreamProvider.family<Session?, String>((ref, id) {
  return ref.watch(sessionRepositoryProvider).watch(id);
});

class RecentPlayersController extends StateNotifier<List<String>> {
  RecentPlayersController(this._repo) : super(_repo.getRecent());

  final PlayersRepository _repo;

  Future<void> remove(String name) async {
    await _repo.remove(name);
    state = _repo.getRecent();
  }

  Future<void> clear() async {
    await _repo.clear();
    state = _repo.getRecent();
  }

  Future<void> addMany(Iterable<String> names) async {
    await _repo.addMany(names);
    state = _repo.getRecent();
  }

  Future<void> add(String name) async {
    await _repo.addMany([name]);
    state = _repo.getRecent();
  }

  void refresh() {
    state = _repo.getRecent();
  }
}

final recentPlayersProvider =
    StateNotifierProvider<RecentPlayersController, List<String>>((ref) {
  return RecentPlayersController(ref.read(playersRepositoryProvider));
});
