import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/live/live_viewer_screen.dart';
import '../../features/live/watch_live_screen.dart';
import '../../features/round_entry/round_entry_screen.dart';
import '../../features/scoreboard/scoreboard_screen.dart';
import '../../features/session_setup/session_setup_screen.dart';
import '../../features/settings/manage_players_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/summary/summary_screen.dart';
import 'banner_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Home is outside the shell so it never shows the persistent banner.
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      // Every other screen lives inside the shell so they share a single
      // long-lived banner instance.
      ShellRoute(
        builder: (_, __, child) => BannerShell(child: child),
        routes: [
          GoRoute(
            path: '/setup',
            builder: (_, __) => const SessionSetupScreen(),
          ),
          GoRoute(
            path: '/session/:id',
            builder: (_, state) => ScoreboardScreen(
              sessionId: state.pathParameters['id']!,
              readOnly: false,
            ),
          ),
          GoRoute(
            path: '/session/:id/round/new',
            pageBuilder: (_, state) => CupertinoPage(
              key: state.pageKey,
              child: RoundEntryScreen(
                sessionId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/session/:id/round/:rid',
            pageBuilder: (_, state) => CupertinoPage(
              key: state.pageKey,
              child: RoundEntryScreen(
                sessionId: state.pathParameters['id']!,
                roundId: state.pathParameters['rid'],
              ),
            ),
          ),
          GoRoute(
            path: '/session/:id/summary',
            builder: (_, state) => SummaryScreen(
              sessionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/history/:id',
            builder: (_, state) => SummaryScreen(
              sessionId: state.pathParameters['id']!,
              fromHistory: true,
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/players',
            builder: (_, __) => const ManagePlayersScreen(),
          ),
          GoRoute(
            path: '/watch',
            builder: (_, __) => const WatchLiveScreen(),
          ),
          GoRoute(
            path: '/live/:code',
            builder: (_, state) => LiveViewerScreen(
              code: state.pathParameters['code']!,
            ),
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
      body: const Center(child: Text('Page not found')),
    ),
  );
});
