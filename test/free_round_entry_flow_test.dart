import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:scorewise/data/models/session.dart';
import 'package:scorewise/data/models/session_settings.dart';
import 'package:scorewise/data/providers.dart';
import 'package:scorewise/data/scoring.dart';
import 'package:scorewise/data/storage/session_repository.dart';
import 'package:scorewise/features/round_entry/round_entry_screen.dart';

class FakeSessionRepository implements SessionRepository {
  final Map<String, Session> _data = {};
  final StreamController<Session?> _single =
      StreamController<Session?>.broadcast();
  String? _watchedId;

  @override
  List<Session> getAll() => _data.values.toList();

  @override
  Stream<List<Session>> watchAll() async* {
    yield getAll();
  }

  @override
  Session? getActive() {
    for (final s in _data.values) {
      if (s.finishedAt == null) return s;
    }
    return null;
  }

  @override
  Session? get(String id) => _data[id];

  @override
  Stream<Session?> watch(String id) async* {
    _watchedId = id;
    yield _data[id];
    await for (final s in _single.stream) {
      if (s == null || s.id == id) yield s;
    }
  }

  @override
  Future<void> save(Session s) async {
    _data[s.id] = s;
    if (_watchedId == s.id) _single.add(s);
  }

  @override
  Future<void> delete(String id) async {
    _data.remove(id);
    if (_watchedId == id) _single.add(null);
  }

  @override
  Future<Session?> finish(String id) async {
    final s = _data[id];
    if (s == null) return null;
    final updated = s.copyWith(finishedAt: DateTime.now());
    _data[id] = updated;
    _single.add(updated);
    return updated;
  }

  Future<void> dispose() => _single.close();
}

Session _freeSession() => Session.create(
      players: ['A', 'B', 'C', 'D'],
      settings: const SessionSettings(
          bonusEnabled: false, bonusAmount: 0, mode: ScoreMode.free),
    );

Future<FakeSessionRepository> _pump(WidgetTester tester, Session session) async {
  final repo = FakeSessionRepository();
  await repo.save(session);
  final router = GoRouter(
    initialLocation: '/round',
    routes: [
      GoRoute(
        path: '/round',
        builder: (_, __) => RoundEntryScreen(sessionId: session.id),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return repo;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(900, 2400);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('free session routes to the free entry form', (tester) async {
    final repo = await _pump(tester, _freeSession());

    // Free UI markers — never the bid form's "Who called?".
    expect(find.text('Save round'), findsOneWidget);
    expect(find.text('Who called?'), findsNothing);
    // One tappable value box per player, all unset.
    expect(find.text('Tap to set'), findsNWidgets(4));

    await repo.dispose();
  });

  testWidgets('enter a score and a penalty, then save the round',
      (tester) async {
    final repo = await _pump(tester, _freeSession());

    // Player rows carry a pencil affordance in player order: A=0, B=1, …
    final pencils = find.byIcon(PhosphorIconsRegular.pencilSimple);

    // A gets +7.
    await tester.tap(pencils.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // B gets a −5 penalty.
    await tester.tap(pencils.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penalty'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('5'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save round'));
    await tester.pump(const Duration(milliseconds: 300));

    final saved = repo.getAll().first;
    expect(saved.rounds.length, 1);
    final r = saved.rounds.first;
    expect(r.isFree, isTrue);
    expect(r.scores, {'A': 7, 'B': -5, 'C': 0, 'D': 0});

    final scores = computeScores(saved);
    expect(scores, {'A': 7, 'B': -5, 'C': 0, 'D': 0});

    await repo.dispose();
  });
}
