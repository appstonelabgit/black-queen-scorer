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
import '../scoreboard/widgets/player_row.dart';

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

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        _StatusStrip(state: state),
        const SizedBox(height: Spacing.md),
        _HeadlineCard(state: state),
        const SizedBox(height: Spacing.md),
        Text('Leaderboard', style: text.titleMedium),
        const SizedBox(height: Spacing.sm),
        ...sortedPlayers.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final name = entry.value;
          final score = state.scores[name] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: PlayerRow(rank: rank, name: name, score: score),
          );
        }),
        if (state.lastRound != null) ...[
          const SizedBox(height: Spacing.lg),
          Text('Last round', style: text.titleMedium),
          const SizedBox(height: Spacing.sm),
          _LastRoundCard(round: state.lastRound!),
        ],
        const SizedBox(height: Spacing.lg),
        Text(
          'Updates automatically. Close this screen anytime.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
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

class _HeadlineCard extends StatelessWidget {
  final LiveSessionState state;
  const _HeadlineCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final leader = state.scores.entries.isEmpty
        ? null
        : state.scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsFill.crown, color: scheme.secondary, size: 32),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader == null ? 'No rounds yet' : 'Leading: ${leader.key}',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${plural(state.players.length, 'player')} · '
                  '${state.bonus > 0 ? "+${state.bonus} bonus" : "no bonus"}',
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (leader != null)
            Text(
              formatScore(leader.value),
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
