import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/live/live_models.dart';
import '../../core/live/live_session_viewer.dart';
import '../../core/live/live_view_history.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/shell_back_button.dart';
import '../session_setup/widgets/player_chip.dart';
import '../summary/widgets/stats_card.dart';

class LiveViewerScreen extends StatefulWidget {
  final String code;
  const LiveViewerScreen({super.key, required this.code});

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  Future<bool>? _bootstrap;

  /// Signature of the last snapshot written to view history. Lets us record
  /// the game once and refresh only when the players or finished state
  /// actually change, instead of on every RTDB tick.
  String? _recordedSig;

  @override
  void initState() {
    super.initState();
    // Anonymous auth is required to read /live_sessions/{code}. If the
    // user opened this screen via a deep-link cold start, Firebase may
    // not have finished initializing yet.
    _bootstrap = FirebaseBootstrap.init();
  }

  /// Persists this game to "recently watched" so the user can re-open it
  /// later without the code. Idempotent per unchanged snapshot.
  void _recordView(LiveSessionState state) {
    final sig = '${state.finished}|${state.players.join(',')}';
    if (sig == _recordedSig) return;
    _recordedSig = sig;
    LiveViewHistory.instance.record(
      code: widget.code,
      players: state.players,
      finished: state.finished,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Watch live'),
            Text(
              widget.code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _bootstrap,
          builder: (context, bootSnap) {
            if (bootSnap.connectionState != ConnectionState.done) {
              return const BrandedLoader();
            }
            if (bootSnap.data != true) {
              return ErrorState(
                title: 'Can\'t connect',
                message:
                    'Live viewing needs a signed-in session. Check your internet, then open the link again.',
                onRetry: () => setState(() {
                  _bootstrap = FirebaseBootstrap.init();
                }),
              );
            }
            return StreamBuilder<LiveSessionState?>(
              stream: LiveSessionViewer.watch(widget.code),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorState(
                    title: 'Can\'t read this session',
                    message:
                        'The host may have signed out, or the session was blocked. Ask them to re-share the code.',
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const BrandedLoader();
                }
                final state = snap.data;
                if (state == null) {
                  return EmptyState(
                    icon: PhosphorIconsDuotone.magnifyingGlass,
                    title: 'No live game with code ${widget.code}',
                    subtitle:
                        'Check the code with whoever invited you, or ask them to start a new session.',
                  );
                }
                _recordView(state);
                return _LiveScoreboard(state: state);
              },
            );
          },
        ),
      ),
    );
  }
}

class _LiveScoreboard extends StatelessWidget {
  final LiveSessionState state;
  const _LiveScoreboard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sortedPlayers = [...state.players]
      ..sort((a, b) => (state.scores[b] ?? 0).compareTo(state.scores[a] ?? 0));
    final started = state.roundCount > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.sm, Spacing.md, Spacing.lg),
      children: [
        _StatusStrip(state: state),
        const SizedBox(height: Spacing.sm),
        Text(
          '${plural(state.players.length, 'player')} · '
          '${state.bonus > 0 ? "+${state.bonus} bonus" : "no bonus"}',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Leaderboard', style: text.titleMedium),
            const Spacer(),
            if (!started)
              Text('Waiting for round 1',
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        // Flat, divider-separated rows — lighter than per-row cards for a
        // potentially long leaderboard.
        for (var i = 0; i < sortedPlayers.length; i++) ...[
          if (i > 0)
            Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4)),
          _LeaderRow(
            rank: i + 1,
            name: sortedPlayers[i],
            score: state.scores[sortedPlayers[i]] ?? 0,
            leading: started,
            onTap: () =>
                _showLivePlayerDetail(context, state, sortedPlayers[i]),
          ),
        ],
        // When the game has ended, surface the same fun-stats analytics the
        // host sees on their summary — the watcher gets a complete recap.
        if (state.finished) ...[
          ...(() {
            final cards = _liveFunStats(context, state);
            if (cards.isEmpty) return <Widget>[];
            return [
              const SizedBox(height: Spacing.lg),
              Text('Final stats', style: text.titleMedium),
              const SizedBox(height: Spacing.sm),
              StatsGrid(cards: cards),
            ];
          })(),
        ] else ...[
          if (state.currentRound?.isValid ?? false) ...[
            const SizedBox(height: Spacing.lg),
            Text('Current round', style: text.titleMedium),
            const SizedBox(height: Spacing.sm),
            _CurrentRoundCard(
              round: state.currentRound!,
              roundNum: state.roundCount + 1,
            ),
          ],
          if (state.lastRound != null) ...[
            const SizedBox(height: Spacing.lg),
            Text('Last round', style: text.titleMedium),
            const SizedBox(height: Spacing.sm),
            _LastRoundCard(round: state.lastRound!),
          ],
        ],
        const SizedBox(height: Spacing.lg),
        Text(
          state.finished
              ? 'This game has ended.'
              : 'Updates live. Close anytime.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Minimal leaderboard row — rank (trophy for the leader once play starts),
/// avatar, name, signed score. No card chrome, just a hairline between rows.
class _LeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final bool leading;
  final VoidCallback? onTap;
  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLeader = leading && rank == 1;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs, vertical: Spacing.sm + 2),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: isLeader
                ? Icon(PhosphorIconsFill.trophy,
                    size: 18, color: scheme.secondary)
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(width: Spacing.sm),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: playerColor(name, scheme.brightness),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(playerInitial(name),
                style: text.labelLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(name, style: text.titleMedium)),
          Text(
            formatScore(score),
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: score == 0
                  ? scheme.onSurfaceVariant
                  : (score > 0
                      ? successColor(scheme.brightness)
                      : dangerColor(scheme.brightness)),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: Spacing.xs),
            Icon(PhosphorIconsRegular.caretRight,
                size: 14, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: 'Rank $rank, $name, ${formatScore(score)}',
      onTapHint: 'View round-by-round history',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }
}

/// Bottom sheet with a player's per-round score history for the current live
/// game — mirrors what the host sees when tapping a player on the scoreboard,
/// plus their caller record. Built entirely from the live snapshot.
void _showLivePlayerDetail(
    BuildContext context, LiveSessionState state, String name) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final textTheme = Theme.of(ctx).textTheme;
      final brightness = scheme.brightness;
      final deltas = <({int roundNum, int delta})>[];
      var callsMade = 0;
      var callsWon = 0;
      for (var i = 0; i < state.rounds.length; i++) {
        final r = state.rounds[i];
        deltas.add((roundNum: i + 1, delta: r.delta[name] ?? 0));
        if (r.bidder == name) {
          callsMade++;
          if (r.won) callsWon++;
        }
      }
      final total = state.scores[name] ??
          deltas.fold<int>(0, (sum, e) => sum + e.delta);
      return Padding(
        padding: EdgeInsets.only(
          left: Spacing.md,
          right: Spacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: playerColor(name, brightness),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(playerInitial(name),
                      style:
                          textTheme.titleMedium?.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: textTheme.titleLarge),
                      Text(
                        'Total ${formatScore(total)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: total == 0
                              ? scheme.onSurfaceVariant
                              : (total > 0
                                  ? successColor(brightness)
                                  : dangerColor(brightness)),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              callsMade == 0
                  ? 'No calls yet'
                  : 'Called $callsMade · won $callsWon · lost ${callsMade - callsWon}',
              style: textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.sm),
            if (deltas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.md),
                child: Text('No rounds yet.'),
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: deltas.length,
                separatorBuilder: (_, __) => const SizedBox(height: Spacing.xs),
                itemBuilder: (_, i) {
                  final d = deltas[deltas.length - 1 - i];
                  return Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text('Round ${d.roundNum}',
                            style: textTheme.bodySmall),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        formatScore(d.delta),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: d.delta == 0
                              ? scheme.onSurfaceVariant
                              : d.delta >= 0
                                  ? successColor(brightness)
                                  : dangerColor(brightness),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Fun-stat cards computed from a finished live session's rounds — mirrors
/// the host's summary "Fun Stats" so a watcher gets the full recap.
List<Widget> _liveFunStats(BuildContext context, LiveSessionState state) {
  final rounds = state.rounds;
  if (rounds.isEmpty) return const [];
  final scheme = Theme.of(context).colorScheme;
  final success = successColor(scheme.brightness);
  final danger = dangerColor(scheme.brightness);

  final wonBy = <String, int>{};
  final bidTotals = <String, int>{};
  final bidCounts = <String, int>{};
  String? gainName;
  var gain = -1 << 62;
  var gainRound = 0;
  String? lossName;
  var loss = 1 << 62;
  var lossRound = 0;

  for (var i = 0; i < rounds.length; i++) {
    final r = rounds[i];
    if (r.won) wonBy[r.bidder] = (wonBy[r.bidder] ?? 0) + 1;
    bidTotals[r.bidder] = (bidTotals[r.bidder] ?? 0) + r.bid;
    bidCounts[r.bidder] = (bidCounts[r.bidder] ?? 0) + 1;
    r.delta.forEach((name, v) {
      if (v > gain) {
        gain = v;
        gainName = name;
        gainRound = i + 1;
      }
      if (v < loss) {
        loss = v;
        lossName = name;
        lossRound = i + 1;
      }
    });
  }

  final cards = <Widget>[];
  if (wonBy.isNotEmpty) {
    final top = wonBy.entries.reduce((a, b) => b.value > a.value ? b : a);
    cards.add(StatsCard(
      icon: PhosphorIconsFill.target,
      title: 'Most targets won',
      value: top.key,
      avatarName: top.key,
      subtitle: plural(top.value, 'target'),
    ));
  }
  if (bidCounts.isNotEmpty) {
    final avgs = bidCounts.entries
        .map((e) => MapEntry(e.key, (bidTotals[e.key] ?? 0) / e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    cards.add(StatsCard(
      icon: PhosphorIconsFill.cardsThree,
      title: 'Boldest caller',
      value: avgs.first.key,
      avatarName: avgs.first.key,
      subtitle: 'avg ${avgs.first.value.toStringAsFixed(0)}',
    ));
  }
  if (gainName != null && gain > 0) {
    cards.add(StatsCard(
      icon: PhosphorIconsFill.trendUp,
      accent: success,
      title: 'Biggest single win',
      value: '$gainName ${formatScore(gain)}',
      subtitle: 'Round $gainRound',
    ));
  }
  if (lossName != null && loss < 0) {
    cards.add(StatsCard(
      icon: PhosphorIconsFill.trendDown,
      accent: danger,
      title: 'Biggest single loss',
      value: '$lossName ${formatScore(loss)}',
      subtitle: 'Round $lossRound',
    ));
  }
  return cards;
}

class _StatusStrip extends StatelessWidget {
  final LiveSessionState state;
  const _StatusStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLive = !state.finished;
    final liveColor = successColor(scheme.brightness);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isLive ? liveColor : scheme.outline)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: (isLive ? liveColor : scheme.outline)
                  .withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLive
                    ? PhosphorIconsFill.circle
                    : PhosphorIconsRegular.checkCircle,
                size: 12,
                color: isLive ? liveColor : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(isLive ? 'Live' : 'Finished'),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Round ${state.roundCount}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// The round the host is entering right now — caller and bid are set, result
/// pending. Accented to read as "in play" and distinct from the finished
/// "Last round" card below it.
class _CurrentRoundCard extends StatelessWidget {
  final LiveCurrentRound round;
  final int roundNum;
  const _CurrentRoundCard({required this.round, required this.roundNum});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = scheme.secondary;
    final teamLabel = round.bidTeam.isEmpty
        ? round.bidder
        : round.bidTeam.join(' + ');
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.circle, size: 12, color: accent),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  '${round.bidder} called ${round.bid}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  'Round $roundNum · in play',
                  style: text.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Team: $teamLabel',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _LastRoundCard extends StatelessWidget {
  final LiveRound round;
  const _LastRoundCard({required this.round});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final resultColor =
        round.won ? successColor(scheme.brightness) : dangerColor(scheme.brightness);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                round.won
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsFill.xCircle,
                color: resultColor,
                size: 20,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${round.bidder} called ${round.bid}',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                round.won ? 'Won' : 'Lost',
                style: text.titleSmall?.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Team: ${round.bidTeam.join(" + ")}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
