import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:black_queen_scorer/data/models/session.dart';
import 'package:black_queen_scorer/data/models/session_settings.dart';
import 'package:black_queen_scorer/data/providers.dart';
import 'package:black_queen_scorer/data/scoring.dart';
import 'package:black_queen_scorer/data/storage/session_repository.dart';
import 'package:black_queen_scorer/features/round_entry/round_entry_screen.dart';
import 'package:black_queen_scorer/features/round_entry/widgets/result_toggle.dart';
import 'package:black_queen_scorer/features/session_setup/widgets/player_chip.dart';

class FakeSessionRepository implements SessionRepository {
  final Map<String, Session> _data = {};
  final StreamController<Session?> _single =
      StreamController<Session?>.broadcast();
  String? _watchedId;

  @override
  List<Session> getAll() {
    final items = _data.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return items;
  }

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

void main() {
  setUp(() {
    // Give the test viewport enough room for the full Round Entry form.
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(900, 2400);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('Round Entry renders for a session', (tester) async {
    final repo = FakeSessionRepository();
    final session = Session.create(
      players: ['A', 'B', 'C', 'D'],
      settings: const SessionSettings.disabled(),
    );
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
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Who bid?'), findsOneWidget);
    expect(find.text('Bid amount'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);

    await repo.dispose();
  });

  testWidgets(
      'Round Entry: pick bidder → pick team → enter bid → tap Won saves round',
      (tester) async {
    final repo = FakeSessionRepository();
    final session = Session.create(
      players: ['A', 'B', 'C', 'D'],
      settings: const SessionSettings.disabled(),
    );
    await repo.save(session);

    final router = GoRouter(
      initialLocation: '/round',
      routes: [
        GoRoute(
          path: '/round',
          builder: (_, __) => RoundEntryScreen(sessionId: session.id),
        ),
        GoRoute(
          path: '/done',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Popped'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final chipsA =
        find.byWidgetPredicate((w) => w is PlayerChip && w.name == 'A');
    final chipsB =
        find.byWidgetPredicate((w) => w is PlayerChip && w.name == 'B');

    await tester.tap(chipsA.first);
    await tester.pump(const Duration(milliseconds: 200));

    // There are now two B chips — one in the bidder section (first) and one
    // in the team section (second). We want the team-section one.
    await tester.tap(chipsB.at(1));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('00'));
    await tester.pump(const Duration(milliseconds: 150));

    final resultToggle = find.byType(ResultToggle);
    await tester.scrollUntilVisible(resultToggle, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 100));

    final wonFinder = find.descendant(
      of: resultToggle,
      matching: find.text('Won'),
    );
    await tester.tap(wonFinder);
    await tester.pump(const Duration(milliseconds: 300));

    final updated = repo.get(session.id)!;
    expect(updated.rounds.length, 1);
    final r = updated.rounds.first;
    expect(r.bidder, 'A');
    expect(r.team.contains('B'), isTrue);
    expect(r.bidAmount, 700);
    expect(r.won, isTrue);

    final scores = computeScores(updated);
    expect(scores['A'], 700);
    expect(scores['B'], 700);
    expect(scores['C'], -700);
    expect(scores['D'], -700);

    await repo.dispose();
  });
}
