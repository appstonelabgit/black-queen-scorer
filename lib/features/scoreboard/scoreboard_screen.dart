import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/ads/ad_service.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/live/live_session_writer.dart';
import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/round.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../data/scoring.dart';
import '../../features/live/live_share_sheet.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'widgets/player_row.dart';
import 'widgets/round_list.dart';

class ScoreboardScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final bool readOnly;
  const ScoreboardScreen({
    super.key,
    required this.sessionId,
    required this.readOnly,
  });

  @override
  ConsumerState<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends ConsumerState<ScoreboardScreen> {
  Map<String, int> _previousScores = const {};
  bool _roundsCollapsed = false;
  String? _lastHandledRoundId;

  @override
  Widget build(BuildContext context) {
    final asyncSession = ref.watch(sessionByIdProvider(widget.sessionId));
    return asyncSession.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Session not found')),
          );
        }
        return _build(session);
      },
    );
  }

  Widget _build(Session session) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final scores = computeScores(session);
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final roundsCount = session.rounds.length;
    final nextRoundN = roundsCount + 1;

    // Determine pulse deltas.
    final pulseDeltas = <String, int>{};
    for (final e in scores.entries) {
      final old = _previousScores[e.key] ?? 0;
      pulseDeltas[e.key] = e.value - old;
    }
    // Schedule update after frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_mapEq(_previousScores, scores)) {
        setState(() => _previousScores = Map.of(scores));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.readOnly
                  ? formatRelativeDate(
                      session.finishedAt ?? session.startedAt)
                  : 'Round $nextRoundN',
              style: text.titleLarge,
            ),
            Text(
              '${session.players.length} players · '
              '${widget.readOnly ? '${session.rounds.length} rounds' : formatDuration(session.duration)}',
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        titleSpacing: Spacing.md,
        toolbarHeight: 72,
        actions: widget.readOnly
            ? []
            : [
                IconButton(
                  tooltip: 'Share live',
                  icon: const Icon(PhosphorIconsRegular.broadcast),
                  onPressed: () => _onShareLive(session),
                ),
                IconButton(
                  tooltip: 'Session options',
                  icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                  onPressed: () => _showSessionOptions(session),
                ),
                IconButton(
                  tooltip: 'Finish session',
                  icon: const Icon(PhosphorIconsRegular.flagCheckered),
                  onPressed: () => _onFinish(session),
                ),
              ],
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: ListView(
            padding: const EdgeInsets.only(top: Spacing.sm, bottom: 16),
            children: [
              if (session.rounds.isEmpty && !widget.readOnly) ...[
                _EmptyRoundsBanner(),
                const SizedBox(height: Spacing.md),
              ],
              RepaintBoundary(
                child: Column(
                  children: [
                    for (var i = 0; i < ranked.length; i++) ...[
                      AnimatedSwitcher(
                        duration: AppDurations.slow,
                        switchInCurve: Curves.easeOutCubic,
                        child: PlayerRow(
                          key: ValueKey(ranked[i].key),
                          rank: i + 1,
                          name: ranked[i].key,
                          score: ranked[i].value,
                          pulseDelta: pulseDeltas[ranked[i].key],
                          onTap: () =>
                              _showPlayerDetail(session, ranked[i].key),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.sm),
              RoundList(
                session: session,
                collapsed: _roundsCollapsed,
                onToggleCollapsed: () => setState(
                    () => _roundsCollapsed = !_roundsCollapsed),
                onTap: widget.readOnly
                    ? null
                    : (i) {
                        context.push(
                          '/session/${session.id}/round/${session.rounds[i].id}',
                        );
                      },
                onLongPress: widget.readOnly
                    ? null
                    : (i) => _showRoundOptions(session, i),
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.md, 0, Spacing.md, Spacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _onFinish(session),
                      child: const Text(Strings.finishSession),
                    ),
                    const SizedBox(height: Spacing.xs),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                        ),
                        onPressed: () async {
                          Haptics.medium();
                          await _openNewRound(session);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(PhosphorIconsRegular.plus),
                            const SizedBox(width: Spacing.sm),
                            Text('New Round',
                                style: text.titleMedium
                                    ?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _openNewRound(Session s) async {
    final before = s.rounds.length;
    await context.push('/session/${s.id}/round/new');
    if (!mounted) return;
    final latest = ref.read(sessionRepositoryProvider).get(s.id);
    if (latest == null) return;
    if (latest.rounds.length > before) {
      final newRound = latest.rounds.last;
      if (_lastHandledRoundId != newRound.id) {
        _lastHandledRoundId = newRound.id;
        _showUndoSnackbar(latest, newRound, latest.rounds.length);
      }
    }
  }

  void _showUndoSnackbar(Session session, Round newRound, int roundNum) {
    AppToast.show(
      context,
      'Round $roundNum saved',
      style: ToastStyle.success,
      duration: const Duration(seconds: 4),
      actionLabel: 'Undo',
      onAction: () async {
        final current = ref.read(sessionRepositoryProvider).get(session.id);
        if (current == null) return;
        final updated = current.copyWith(
          rounds:
              current.rounds.where((r) => r.id != newRound.id).toList(),
        );
        await ref.read(sessionRepositoryProvider).save(updated);
      },
    );
  }

  Future<void> _onFinish(Session s) async {
    final ok = await ConfirmDialog.show(
      context,
      title: Strings.finishConfirmTitle,
      body: Strings.finishConfirmBody,
      confirmLabel: 'Finish',
    );
    if (!ok) return;
    if (!mounted) return;
    AdService.onSessionFinished();
    context.go('/session/${s.id}/summary');
  }

  Future<void> _onShareLive(Session s) async {
    if (!FirebaseBootstrap.initialized) {
      await FirebaseBootstrap.init();
    }
    final code = await LiveSessionWriter.instance.ensureCode(s.id);
    if (!mounted) return;
    if (code == null) {
      final err = FirebaseBootstrap.lastError;
      AppToast.show(
        context,
        err == null
            ? 'Live sharing needs internet. Try again later.'
            : 'Live sharing unavailable: $err',
        style: ToastStyle.error,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    // Await the first sync so the viewer never hits "no session found"
    // immediately after the host shares the code. Cap the wait so bad
    // networks don't freeze the button.
    try {
      await LiveSessionWriter.instance
          .sync(s)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // ignore — viewer will still pick up data once the write eventually lands
    }
    if (!mounted) return;
    await showLiveShareSheet(context, code);
  }

  void _showSessionOptions(Session session) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.flagCheckered),
              title: const Text(Strings.finishSession),
              onTap: () {
                Navigator.pop(ctx);
                _onFinish(session);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.trash,
                  color: Theme.of(context).colorScheme.error),
              title: Text(Strings.discardSession,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await ConfirmDialog.show(
                  context,
                  title: Strings.discardConfirmTitle,
                  body: Strings.discardConfirmBody,
                  confirmLabel: 'Discard',
                  destructive: true,
                );
                if (!ok) return;
                await ref
                    .read(sessionRepositoryProvider)
                    .delete(session.id);
                if (!mounted) return;
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoundOptions(Session session, int index) {
    final round = session.rounds[index];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.pencilSimple),
              title: const Text('Edit round'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(
                    '/session/${session.id}/round/${round.id}');
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.trash,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete round',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'Delete round?',
                  body: 'This will recalculate all scores.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!ok) return;
                final updated = session.copyWith(
                  rounds: session.rounds
                      .where((r) => r.id != round.id)
                      .toList(),
                );
                await ref
                    .read(sessionRepositoryProvider)
                    .save(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayerDetail(Session session, String name) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final deltas = <({int roundNum, int delta})>[];
        for (var i = 0; i < session.rounds.length; i++) {
          final d = computeRoundDelta(session.rounds[i], session);
          deltas.add((roundNum: i + 1, delta: d[name] ?? 0));
        }
        final total = deltas.fold<int>(0, (sum, e) => sum + e.delta);
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
              Text(name, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: Spacing.xs),
              Text('Total: ${formatScore(total)}',
                  style: Theme.of(ctx).textTheme.bodyLarge),
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
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacing.xs),
                  itemBuilder: (_, i) {
                    final d = deltas[deltas.length - 1 - i];
                    return Row(
                      children: [
                        SizedBox(
                            width: 56,
                            child: Text('Round ${d.roundNum}',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .bodySmall)),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          formatScore(d.delta),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                            color: d.delta == 0
                                ? Theme.of(ctx).colorScheme.onSurfaceVariant
                                : d.delta > 0
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
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

  bool _mapEq(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

class _EmptyRoundsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm + 2),
      child: Row(
        children: [
          Icon(PhosphorIconsFill.sparkle, color: scheme.secondary, size: 18),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('All scores at zero',
                    style: text.labelLarge?.copyWith(color: scheme.onSurface)),
                Text(
                  'Tap New Round below to begin.',
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
