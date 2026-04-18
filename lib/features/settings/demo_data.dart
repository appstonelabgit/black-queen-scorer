import '../../data/models/round.dart';
import '../../data/models/session.dart';
import '../../data/models/session_settings.dart';
import '../../data/storage/players_repository.dart';
import '../../data/storage/session_repository.dart';

/// Seeds realistic-looking session data into the real on-device Hive boxes.
/// Only called from a debug-only Settings menu item used to populate the
/// simulator for marketing screenshots.
Future<void> seedDemoData({
  required SessionRepository sessions,
  required PlayersRepository players,
}) async {
  final now = DateTime.now();
  const roster = [
    'Arvind',
    'Nilay',
    'Kaka',
    'Hitesh',
    'Nitin',
    'Roxy',
    'Malik',
    'Priya',
  ];

  final sessionA = Session(
    id: 'demo-a',
    startedAt: now.subtract(const Duration(days: 3, hours: 2, minutes: 30)),
    finishedAt: now.subtract(const Duration(days: 3, hours: 1, minutes: 8)),
    players: const ['Arvind', 'Nilay', 'Kaka', 'Hitesh', 'Nitin', 'Priya'],
    settings: const SessionSettings(bonusEnabled: true, bonusAmount: 100),
    rounds: [
      Round(
        id: 'a1',
        bidder: 'Arvind',
        team: const ['Arvind', 'Nilay'],
        bidAmount: 700,
        won: true,
        createdAt: now.subtract(const Duration(days: 3, hours: 2, minutes: 20)),
      ),
      Round(
        id: 'a2',
        bidder: 'Kaka',
        team: const ['Kaka', 'Hitesh'],
        bidAmount: 600,
        won: false,
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),
      Round(
        id: 'a3',
        bidder: 'Arvind',
        team: const ['Arvind', 'Priya'],
        bidAmount: 800,
        won: true,
        createdAt: now.subtract(const Duration(days: 3, hours: 1, minutes: 45)),
      ),
      Round(
        id: 'a4',
        bidder: 'Nitin',
        team: const ['Nitin', 'Hitesh'],
        bidAmount: 650,
        won: true,
        createdAt: now.subtract(const Duration(days: 3, hours: 1, minutes: 25)),
      ),
    ],
  );

  final sessionB = Session(
    id: 'demo-b',
    startedAt: now.subtract(const Duration(days: 1, hours: 4)),
    finishedAt: now.subtract(const Duration(days: 1, hours: 2, minutes: 55)),
    players: const ['Roxy', 'Malik', 'Arvind', 'Nilay', 'Kaka', 'Hitesh'],
    settings: const SessionSettings.disabled(),
    rounds: [
      Round(
        id: 'b1',
        bidder: 'Roxy',
        team: const ['Roxy', 'Malik'],
        bidAmount: 550,
        won: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 3, minutes: 50)),
      ),
      Round(
        id: 'b2',
        bidder: 'Arvind',
        team: const ['Arvind', 'Nilay'],
        bidAmount: 750,
        won: false,
        createdAt: now.subtract(const Duration(days: 1, hours: 3, minutes: 30)),
      ),
      Round(
        id: 'b3',
        bidder: 'Roxy',
        team: const ['Roxy', 'Kaka'],
        bidAmount: 900,
        won: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ],
  );

  final sessionActive = Session(
    id: 'demo-active',
    startedAt: now.subtract(const Duration(minutes: 42)),
    finishedAt: null,
    players: const [
      'Arvind',
      'Nilay',
      'Kaka',
      'Hitesh',
      'Nitin',
      'Roxy',
      'Priya',
      'Malik',
    ],
    settings: const SessionSettings(bonusEnabled: true, bonusAmount: 100),
    rounds: [
      Round(
        id: 'live1',
        bidder: 'Arvind',
        team: const ['Arvind', 'Nilay'],
        bidAmount: 700,
        won: true,
        createdAt: now.subtract(const Duration(minutes: 35)),
      ),
      Round(
        id: 'live2',
        bidder: 'Kaka',
        team: const ['Kaka', 'Hitesh', 'Priya'],
        bidAmount: 850,
        won: false,
        createdAt: now.subtract(const Duration(minutes: 22)),
      ),
      Round(
        id: 'live3',
        bidder: 'Roxy',
        team: const ['Roxy', 'Malik'],
        bidAmount: 600,
        won: true,
        createdAt: now.subtract(const Duration(minutes: 9)),
      ),
    ],
  );

  await sessions.save(sessionA);
  await sessions.save(sessionB);
  await sessions.save(sessionActive);
  await players.addMany(roster);
}
