import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/live/live_models.dart';
import '../../core/live/live_session_viewer.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/shell_back_button.dart';

class LiveViewerScreen extends StatefulWidget {
  final String code;
  const LiveViewerScreen({super.key, required this.code});

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  Future<bool>? _bootstrap;

  @override
  void initState() {
    super.initState();
    // Anonymous auth is required to read /live_sessions/{code}. If the
    // user opened this screen via a deep-link cold start, Firebase may
    // not have finished initializing yet.
    _bootstrap = FirebaseBootstrap.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: Text(widget.code),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _bootstrap,
          builder: (context, bootSnap) {
            if (bootSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (bootSnap.data != true) {
              return _ErrorState(
                title: 'Can\'t connect',
                message:
                    'Live viewing needs a signed-in Firebase session. Check your internet, then open the link again.',
              );
            }
            return StreamBuilder<LiveSessionState?>(
              stream: LiveSessionViewer.watch(widget.code),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorState(
                    title: 'Can\'t read this session',
                    message:
                        'The host may have signed out, or the session was blocked. Ask them to re-share the code.',
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final state = snap.data;
                if (state == null) {
                  return _EmptyState(code: widget.code);
                }
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
          return _LeaderRow(rank: rank, name: name, score: score);
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isLive ? Colors.green : scheme.outline)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: (isLive ? Colors.green : scheme.outline)
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
                color: isLive ? Colors.green : scheme.onSurfaceVariant,
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
                  '${state.players.length} players · '
                  '${state.bonus > 0 ? "+${state.bonus} bonus" : "no bonus"}',
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (leader != null)
            Text(
              '${leader.value}',
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  const _LeaderRow(
      {required this.rank, required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank.',
              style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(name, style: text.titleMedium),
          ),
          Text(
            '$score',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: score >= 0 ? scheme.primary : scheme.error,
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
                color: round.won ? scheme.primary : scheme.error,
                size: 20,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${round.bidder} bid ${round.bid}',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                round.won ? 'Won' : 'Lost',
                style: text.titleSmall?.copyWith(
                  color: round.won ? scheme.primary : scheme.error,
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

class _ErrorState extends StatelessWidget {
  final String title;
  final String message;
  const _ErrorState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.warningCircle,
              size: 64, color: scheme.error),
          const SizedBox(height: Spacing.md),
          Text(title,
              style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Spacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String code;
  const _EmptyState({required this.code});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.magnifyingGlass,
              size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: Spacing.md),
          Text('No live session with code $code',
              style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Spacing.sm),
          Text(
            'Check the code with whoever invited you, or ask them to start a new session.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
