import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../data/scoring.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/shell_back_button.dart';
import '../session_setup/widgets/player_chip.dart';
import '../summary/widgets/stats_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: const Text(Strings.history),
      ),
      body: sessionsAsync.when(
        loading: () => const BrandedLoader(),
        error: (e, _) => ErrorState(
          title: 'Couldn\'t load history',
          message: 'Something went wrong reading your past sessions.',
          onRetry: () => ref.invalidate(allSessionsStreamProvider),
        ),
        data: (sessions) {
          final finished = sessions.where((s) => s.finishedAt != null).toList();
          if (finished.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsDuotone.clockCounterClockwise,
              title: Strings.emptyHistory,
            );
          }
          final stats = computeLifetimeStats(finished);
          final players = computePlayerLifetimes(finished);
          return ListView.builder(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: finished.length + 2,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: _LifetimeStatsBlock(stats: stats, players: players),
                );
              }
              if (i == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Text(
                    'Sessions (${finished.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: _HistoryTile(session: finished[i - 2]),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  final Session session;
  const _HistoryTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final scores = computeScores(session);
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winner = ranked.isNotEmpty ? ranked.first : null;

    final semanticsLabel = winner != null
        ? '${winner.key} won, ${formatScore(winner.value)}, '
            '${formatRelativeDate(session.finishedAt ?? session.startedAt)}, '
            '${plural(session.players.length, 'player')}, ${plural(session.rounds.length, 'round')}'
        : 'Session, '
            '${formatRelativeDate(session.finishedAt ?? session.startedAt)}, '
            '${plural(session.players.length, 'player')}, ${plural(session.rounds.length, 'round')}';

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: const Icon(PhosphorIconsRegular.trash, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context, ref);
      },
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => context.push('/history/${session.id}'),
          child: Semantics(
            button: true,
            label: semanticsLabel,
            onTapHint: 'View summary',
            child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                if (winner != null)
                  ExcludeSemantics(
                    child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: playerColor(winner.key, brightness),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          playerInitial(winner.key),
                          style: text.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: scheme.surfaceContainerHighest,
                                width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(PhosphorIconsFill.trophy,
                              size: 11, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            winner != null
                                ? '${winner.key} won'
                                : 'Session',
                            style: text.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (winner != null) ...[
                            const SizedBox(width: Spacing.xs),
                            Text(
                              formatScore(winner.value),
                              style: text.labelLarge?.copyWith(
                                color: winner.value >= 0
                                    ? successColor(brightness)
                                    : scheme.error,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatRelativeDate(session.finishedAt ?? session.startedAt)} '
                        '· ${DateFormat.jm().format(session.finishedAt ?? session.startedAt)} '
                        '· ${plural(session.players.length, 'player')} · ${plural(session.rounds.length, 'round')}',
                        style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(PhosphorIconsRegular.caretRight,
                    size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(sessionRepositoryProvider);
    final snapshot = session;
    await repo.delete(session.id);
    if (context.mounted) {
      // The stream re-inserts the session if Undo fires repo.save, so we
      // let the dismissible drop the row immediately and rely on the list
      // rebuild to restore it visually.
      AppToast.show(
        context,
        'Session deleted',
        style: ToastStyle.success,
        duration: const Duration(seconds: 3),
        actionLabel: 'Undo',
        onAction: () => repo.save(snapshot),
      );
    }
    return true;
  }
}

class _LifetimeStatsBlock extends StatelessWidget {
  final LifetimeStats stats;
  final List<PlayerLifetime> players;
  const _LifetimeStatsBlock({required this.stats, required this.players});

  void _openPlayer(BuildContext context, String name) =>
      context.push('/history/player/${Uri.encodeComponent(name)}');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cards = <Widget>[];

    final danger = dangerColor(scheme.brightness);
    final success = successColor(scheme.brightness);

    if (stats.mostSessionsWon != null) {
      final count = stats.mostSessionsWon!.wins;
      cards.add(StatsCard(
        icon: PhosphorIconsFill.crown,
        title: 'Top winner',
        value: stats.mostSessionsWon!.name,
        avatarName: stats.mostSessionsWon!.name,
        subtitle: '$count session${count == 1 ? '' : 's'}',
        onTap: () => _openPlayer(context, stats.mostSessionsWon!.name),
      ));
    }
    if (stats.topEarner != null) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.coins,
        title: 'Top earner',
        value: stats.topEarner!.name,
        avatarName: stats.topEarner!.name,
        accent: success,
        subtitle: formatScore(stats.topEarner!.total),
        onTap: () => _openPlayer(context, stats.topEarner!.name),
      ));
    }
    if (stats.biggestLoser != null) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.snowflake,
        title: 'Cold streak',
        value: stats.biggestLoser!.name,
        avatarName: stats.biggestLoser!.name,
        accent: danger,
        subtitle: formatScore(stats.biggestLoser!.total),
        onTap: () => _openPlayer(context, stats.biggestLoser!.name),
      ));
    }
    if (stats.mostBidsWon != null) {
      final count = stats.mostBidsWon!.count;
      cards.add(StatsCard(
        icon: PhosphorIconsFill.target,
        title: 'Most targets won',
        value: stats.mostBidsWon!.name,
        avatarName: stats.mostBidsWon!.name,
        subtitle: '$count ${count == 1 ? 'target' : 'targets'}',
        onTap: () => _openPlayer(context, stats.mostBidsWon!.name),
      ));
    }
    // Derived aggregate cards from the per-player records.
    final mostActive = players.isEmpty
        ? null
        : players.reduce((a, b) =>
            b.sessionsPlayed > a.sessionsPlayed ? b : a);
    if (mostActive != null && mostActive.sessionsPlayed > 0) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.fire,
        title: 'Most active',
        value: mostActive.name,
        avatarName: mostActive.name,
        subtitle: plural(mostActive.sessionsPlayed, 'session'),
        onTap: () => _openPlayer(context, mostActive.name),
      ));
    }
    // Best win rate among players with at least 2 sessions (avoids 1/1=100%).
    final rateEligible =
        players.where((p) => p.sessionsPlayed >= 2).toList();
    if (rateEligible.isNotEmpty) {
      final best = rateEligible
          .reduce((a, b) => b.winRate > a.winRate ? b : a);
      cards.add(StatsCard(
        icon: PhosphorIconsFill.chartLineUp,
        title: 'Best win rate',
        value: '${best.name} ${(best.winRate * 100).round()}%',
        accent: success,
        subtitle: '${best.sessionsWon}/${best.sessionsPlayed} sessions',
        onTap: () => _openPlayer(context, best.name),
      ));
    }
    // Sharpest caller among players with at least 3 calls.
    final callEligible = players.where((p) => p.callsMade >= 3).toList();
    if (callEligible.isNotEmpty) {
      final sharp = callEligible
          .reduce((a, b) => b.callerSuccess > a.callerSuccess ? b : a);
      cards.add(StatsCard(
        icon: PhosphorIconsFill.crosshair,
        title: 'Sharpest caller',
        value: '${sharp.name} ${(sharp.callerSuccess * 100).round()}%',
        subtitle: '${sharp.callsWon}/${sharp.callsMade} calls',
        onTap: () => _openPlayer(context, sharp.name),
      ));
    }
    if (stats.biggestSingleGain != null) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.trendUp,
        title: 'Biggest single win',
        accent: success,
        value:
            '${stats.biggestSingleGain!.name} ${formatScore(stats.biggestSingleGain!.amount)}',
        subtitle: 'Round ${stats.biggestSingleGain!.round}',
      ));
    }
    if (stats.biggestSingleLoss != null) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.trendDown,
        title: 'Biggest single loss',
        accent: danger,
        value:
            '${stats.biggestSingleLoss!.name} ${formatScore(stats.biggestSingleLoss!.amount)}',
        subtitle: 'Round ${stats.biggestSingleLoss!.round}',
      ));
    }
    if (stats.boldestBidder != null) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.cardsThree,
        title: 'Boldest caller',
        value: stats.boldestBidder!.name,
        avatarName: stats.boldestBidder!.name,
        subtitle: 'avg ${stats.boldestBidder!.avg.toStringAsFixed(0)}',
        onTap: () => _openPlayer(context, stats.boldestBidder!.name),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.chartLineUp,
                  size: 18, color: scheme.primary),
              const SizedBox(width: Spacing.sm),
              Text('Lifetime stats', style: text.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              _Headline(value: '${stats.sessionsPlayed}', label: 'Sessions'),
              _HDiv(),
              _Headline(value: '${stats.totalRounds}', label: 'Rounds'),
              _HDiv(),
              _Headline(value: '${stats.uniquePlayers}', label: 'Players'),
              _HDiv(),
              _Headline(
                  value: formatDuration(stats.totalPlayTime), label: 'Played'),
            ],
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: Spacing.sm,
              mainAxisSpacing: Spacing.sm,
              childAspectRatio: 1.7,
              children: cards,
            ),
          ],
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final String value;
  final String label;
  const _Headline({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: text.titleLarge?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _HDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 32,
      color: scheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
