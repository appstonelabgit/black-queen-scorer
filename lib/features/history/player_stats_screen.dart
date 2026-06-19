import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import '../../data/scoring.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/shell_back_button.dart';
import '../session_setup/widgets/player_chip.dart';
import '../summary/widgets/stats_card.dart';

/// Per-player lifetime breakdown, reached by tapping a player in the History
/// stats. Computes the record live from all finished sessions.
class PlayerStatsScreen extends ConsumerWidget {
  final String name;
  const PlayerStatsScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: Text(name),
      ),
      body: sessionsAsync.when(
        loading: () => const BrandedLoader(),
        error: (e, _) => ErrorState(
          title: 'Couldn\'t load stats',
          message: 'Something went wrong reading past sessions.',
          onRetry: () => ref.invalidate(allSessionsStreamProvider),
        ),
        data: (sessions) {
          final all = computePlayerLifetimes(sessions);
          final lower = name.toLowerCase();
          final p = all.where((e) => e.name.toLowerCase() == lower).firstOrNull;
          if (p == null || p.sessionsPlayed == 0) {
            return const EmptyState(
              icon: PhosphorIconsDuotone.user,
              title: 'No record yet',
              subtitle: 'This player has no finished sessions.',
            );
          }
          return _Body(player: p);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PlayerLifetime player;
  const _Body({required this.player});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = scheme.brightness;
    final success = successColor(brightness);
    final danger = dangerColor(brightness);
    final netPositive = player.net >= 0;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          // Hero: avatar + name + net.
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.lg),
              border:
                  Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: playerColor(player.name, brightness),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    playerInitial(player.name),
                    style: text.headlineSmall?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(player.name, style: text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Net ${formatScore(player.net)}',
                        style: text.titleMedium?.copyWith(
                          color: netPositive ? success : danger,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
            childAspectRatio: 1.7,
            children: [
              StatsCard(
                icon: PhosphorIconsFill.crown,
                title: 'Win rate',
                value: '${(player.winRate * 100).round()}%',
                subtitle:
                    '${player.sessionsWon}/${player.sessionsPlayed} sessions',
              ),
              StatsCard(
                icon: PhosphorIconsFill.target,
                title: 'Caller success',
                value: player.callsMade == 0
                    ? '—'
                    : '${(player.callerSuccess * 100).round()}%',
                subtitle: '${player.callsWon}/${player.callsMade} calls',
              ),
              StatsCard(
                icon: PhosphorIconsFill.cardsThree,
                title: 'Avg call',
                value: player.callsMade == 0
                    ? '—'
                    : player.avgCall.toStringAsFixed(0),
                subtitle: plural(player.callsMade, 'call'),
              ),
              StatsCard(
                icon: PhosphorIconsFill.trophy,
                title: 'Sessions',
                value: '${player.sessionsPlayed}',
                subtitle: '${player.sessionsWon} won',
              ),
              StatsCard(
                icon: PhosphorIconsFill.trendUp,
                title: 'Best round',
                accent: success,
                value: formatScore(player.bestRound),
              ),
              StatsCard(
                icon: PhosphorIconsFill.trendDown,
                title: 'Worst round',
                accent: danger,
                value: formatScore(player.worstRound),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
