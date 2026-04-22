import 'dart:async';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final finished = sessions.where((s) => s.finishedAt != null).toList();
          if (finished.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsDuotone.clockCounterClockwise,
              title: Strings.emptyHistory,
            );
          }
          final stats = computeLifetimeStats(finished);
          return ListView.builder(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: finished.length + 2,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: _LifetimeStatsBlock(stats: stats),
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
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                if (winner != null)
                  Stack(
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
                                    ? (brightness == Brightness.light
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF66BB6A))
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
                        '· ${session.players.length} players · ${session.rounds.length} rounds',
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
  const _LifetimeStatsBlock({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cards = <Widget>[];

    if (stats.mostSessionsWon != null) {
      final count = stats.mostSessionsWon!.wins;
      cards.add(StatsCard(
        emoji: '👑',
        title: 'Top winner',
        value: stats.mostSessionsWon!.name,
        subtitle: '$count session${count == 1 ? '' : 's'}',
      ));
    }
    if (stats.topEarner != null) {
      cards.add(StatsCard(
        emoji: '💸',
        title: 'Top earner',
        value: stats.topEarner!.name,
        subtitle: formatScore(stats.topEarner!.total),
      ));
    }
    if (stats.biggestLoser != null) {
      cards.add(StatsCard(
        emoji: '🧊',
        title: 'Cold streak',
        value: stats.biggestLoser!.name,
        subtitle: formatScore(stats.biggestLoser!.total),
      ));
    }
    if (stats.mostBidsWon != null) {
      final count = stats.mostBidsWon!.count;
      cards.add(StatsCard(
        emoji: '🎯',
        title: 'Most bids won',
        value: stats.mostBidsWon!.name,
        subtitle: '$count ${count == 1 ? 'bid' : 'bids'}',
      ));
    }
    if (stats.biggestSingleGain != null) {
      cards.add(StatsCard(
        emoji: '💰',
        title: 'Biggest single win',
        value:
            '${stats.biggestSingleGain!.name} ${formatScore(stats.biggestSingleGain!.amount)}',
        subtitle: 'Round ${stats.biggestSingleGain!.round}',
      ));
    }
    if (stats.biggestSingleLoss != null) {
      cards.add(StatsCard(
        emoji: '💣',
        title: 'Biggest single loss',
        value:
            '${stats.biggestSingleLoss!.name} ${formatScore(stats.biggestSingleLoss!.amount)}',
        subtitle: 'Round ${stats.biggestSingleLoss!.round}',
      ));
    }
    if (stats.boldestBidder != null) {
      cards.add(StatsCard(
        emoji: '🎲',
        title: 'Boldest bidder',
        value: stats.boldestBidder!.name,
        subtitle: 'avg ${stats.boldestBidder!.avg.toStringAsFixed(0)}',
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
