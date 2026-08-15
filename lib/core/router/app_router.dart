import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/history_screen.dart';
import '../../features/history/player_stats_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/live/live_viewer_screen.dart';
import '../../features/live/watch_history_screen.dart';
import '../../features/round_entry/round_entry_screen.dart';
import '../../features/scoreboard/scoreboard_screen.dart';
import '../../features/session_setup/session_setup_screen.dart';
import '../../features/settings/manage_players_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/summary/summary_screen.dart';
import '../theme/guilloche_background.dart';
import 'banner_shell.dart';

/// Wraps a screen in its own opaque guilloché background. Painted per-page
/// (rather than once beneath the whole Navigator) so every route fully
/// occludes the one beneath it during a slide transition — otherwise the
/// transparent scaffolds let the outgoing screen bleed through the incoming
/// one for the length of the animation.
Widget _engraved(Widget child) => EngravedBackground(child: child);

/// Platform-adaptive page — Cupertino on iOS (slide-from-right + edge
/// swipe-back), Material on Android (fade-up + system back).
Page<T> _adaptivePage<T>({required LocalKey key, required Widget child}) {
  if (Platform.isIOS) {
    return CupertinoPage<T>(key: key, child: child);
  }
  return MaterialPage<T>(key: key, child: child);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Home is outside the shell so it never shows the persistent banner.
      GoRoute(
        path: '/',
        builder: (_, __) => _engraved(const HomeScreen()),
      ),
      // Every other screen lives inside the shell so they share a single
      // long-lived banner instance.
      ShellRoute(
        builder: (_, __, child) => BannerShell(child: child),
        routes: [
          GoRoute(
            path: '/setup',
            builder: (_, __) => _engraved(const SessionSetupScreen()),
          ),
          GoRoute(
            path: '/session/:id',
            builder: (_, state) => _engraved(ScoreboardScreen(
              sessionId: state.pathParameters['id']!,
              readOnly: false,
            )),
          ),
          GoRoute(
            path: '/session/:id/round/new',
            pageBuilder: (_, state) => _adaptivePage(
              key: state.pageKey,
              child: _engraved(RoundEntryScreen(
                sessionId: state.pathParameters['id']!,
              )),
            ),
          ),
          GoRoute(
            path: '/session/:id/round/:rid',
            pageBuilder: (_, state) => _adaptivePage(
              key: state.pageKey,
              child: _engraved(RoundEntryScreen(
                sessionId: state.pathParameters['id']!,
                roundId: state.pathParameters['rid'],
              )),
            ),
          ),
          GoRoute(
            path: '/session/:id/summary',
            builder: (_, state) => _engraved(SummaryScreen(
              sessionId: state.pathParameters['id']!,
            )),
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => _engraved(const HistoryScreen()),
          ),
          GoRoute(
            path: '/history/player/:name',
            builder: (_, state) => _engraved(PlayerStatsScreen(
              name: Uri.decodeComponent(state.pathParameters['name']!),
            )),
          ),
          GoRoute(
            path: '/history/:id',
            builder: (_, state) => _engraved(SummaryScreen(
              sessionId: state.pathParameters['id']!,
              fromHistory: true,
            )),
          ),
          GoRoute(
            path: '/history/:id/rounds',
            builder: (_, state) => _engraved(ScoreboardScreen(
              sessionId: state.pathParameters['id']!,
              readOnly: true,
            )),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => _engraved(const SettingsScreen()),
          ),
          GoRoute(
            path: '/settings/players',
            builder: (_, __) => _engraved(const ManagePlayersScreen()),
          ),
          GoRoute(
            path: '/live/:code',
            builder: (_, state) => _engraved(LiveViewerScreen(
              code: state.pathParameters['code']!,
            )),
          ),
          GoRoute(
            path: '/watch-history',
            builder: (_, __) => _engraved(const WatchHistoryScreen()),
          ),
        ],
      ),
      // Deep-link alias so https://…/l/CODE universal links resolve.
      GoRoute(
        path: '/l/:code',
        redirect: (_, state) => '/live/${state.pathParameters['code']}',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to home'),
            ),
          ],
        ),
      ),
    ),
  );
});
