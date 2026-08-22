import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/share_origin.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../data/scoring.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/leaderboard_row.dart';
import 'widgets/podium.dart';
import 'widgets/share_card.dart';
import 'widgets/stats_card.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final bool fromHistory;
  const SummaryScreen({
    super.key,
    required this.sessionId,
    this.fromHistory = false,
  });

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen>
    with TickerProviderStateMixin {
  final _screenshotController = ScreenshotController();
  late final AnimationController _confetti;
  late final AnimationController _entrance;
  bool _finalised = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final disable = MediaQuery.of(context).disableAnimations;
      if (disable) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
        if (!widget.fromHistory) _confetti.forward();
      }
      _finaliseSession();
    });
  }

  Future<void> _deleteSession(Session session) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete session?',
      body: 'This permanently removes it from History.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(sessionRepositoryProvider).delete(session.id);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _finaliseSession() async {
    if (_finalised) return;
    _finalised = true;
    if (widget.fromHistory) return;
    final repo = ref.read(sessionRepositoryProvider);
    final s = repo.get(widget.sessionId);
    if (s == null) return;
    if (s.finishedAt == null) {
      await repo.finish(widget.sessionId);
    }
    try {
      await ref.read(recentPlayersProvider.notifier).addMany(s.players);
    } catch (_) {/* ignore */}
  }

  @override
  void dispose() {
    _confetti.dispose();
    _entrance.dispose();
    super.dispose();
  }

  int get _quipSeed => widget.sessionId.hashCode;

  /// Elastic pop for the winner banner — the emotional headline gets a
  /// springier entrance than the rest of the page.
  Widget _popIn(Widget child) {
    final scale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.75, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.4, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }

  /// Fade+slide a summary section in, staggered along the entrance timeline.
  Widget _reveal(double start, double end, Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.10), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  Future<void> _share(Session session, SessionStats stats) async {
    if (_sharing) return;
    Haptics.medium();
    setState(() => _sharing = true);
    try {
      // Fixed targetSize + a clean MediaQueryData: without them the card is
      // laid out at the phone's logical width (and the user's text scale),
      // which crushed the 1080px design into a wrapped, truncated mess.
      final Uint8List bytes = await _screenshotController.captureFromWidget(
        InheritedTheme.captureAll(
          context,
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1080, 1350),
              devicePixelRatio: 1,
            ),
            child: ShareCard(session: session, stats: stats),
          ),
        ),
        pixelRatio: 1,
        targetSize: const Size(1080, 1350),
        delay: const Duration(milliseconds: 10),
      );
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/scorewise_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '${Strings.appName} — ${stats.ranked.firstOrNull?.name ?? 'Winner'} won!',
          sharePositionOrigin: shareOriginOf(context),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          "Couldn't share: $e",
          style: ToastStyle.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSession = ref.watch(sessionByIdProvider(widget.sessionId));
    return asyncSession.when(
      loading: () => const Scaffold(body: BrandedLoader()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          title: 'Couldn\'t load the summary',
          message: 'Something went wrong reading this session.',
          onRetry: () => ref.invalidate(sessionByIdProvider(widget.sessionId)),
        ),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: PhosphorIconsDuotone.cardsThree,
              title: 'Session not found',
              subtitle: 'It may have been removed.',
            ),
          );
        }
        return _buildSummary(session);
      },
    );
  }

  Widget _buildSummary(Session session) {
    final stats = computeStats(session);
    final statCards = _buildStatCards(stats);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final dateTitle = formatRelativeDate(
        session.finishedAt ?? session.startedAt);

    return Scaffold(
      appBar: AppBar(
        leading: widget.fromHistory
            ? null
            : IconButton(
                icon: const Icon(PhosphorIconsRegular.x),
                onPressed: () => context.go('/'),
              ),
        automaticallyImplyLeading: widget.fromHistory,
        title: Text(widget.fromHistory ? dateTitle : 'Session Complete'),
        actions: widget.fromHistory
            ? [
                IconButton(
                  tooltip: 'Delete session',
                  icon: const Icon(PhosphorIconsRegular.trash),
                  onPressed: () => _deleteSession(session),
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                _reveal(
                  0.0,
                  0.35,
                  Column(
                    children: [
                      Text(
                        widget.fromHistory
                            ? 'Session Summary'
                            : '🎉 Session Complete',
                        style: text.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        '${plural(session.players.length, 'player')} · ${plural(stats.totalRounds, 'round')} · ${formatDuration(stats.totalDuration)}',
                        style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (stats.ranked.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  _popIn(
                    Builder(builder: (context) {
                      final tie = stats.ranked.length >= 2 &&
                          stats.ranked[0].score == stats.ranked[1].score;
                      return _WinnerBanner(
                        name: stats.ranked.first.name,
                        score: stats.ranked.first.score,
                        tie: tie,
                        quip: _pick(
                            tie ? _tieQuips : _winnerQuips, _quipSeed),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                if (stats.ranked.length >= 3)
                  _reveal(0.25, 0.65,
                      Podium(top: stats.ranked.take(3).toList())),
                const SizedBox(height: Spacing.lg),
                _reveal(
                  0.4,
                  0.8,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Final Rankings', style: text.titleMedium),
                      const SizedBox(height: Spacing.sm),
                      for (var i = 0; i < stats.ranked.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              color: scheme.outlineVariant
                                  .withValues(alpha: 0.4)),
                        LeaderboardPlayerRow(
                          rank: i + 1,
                          name: stats.ranked[i].name,
                          score: stats.ranked[i].score,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                if (statCards.isNotEmpty)
                  _reveal(
                    0.55,
                    1.0,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Fun Stats', style: text.titleMedium),
                        const SizedBox(height: Spacing.sm),
                        StatsGrid(cards: statCards),
                      ],
                    ),
                  ),
                const SizedBox(height: Spacing.lg),
                AppButton(
                  label: _sharing ? 'Preparing…' : 'Share',
                  icon: PhosphorIconsRegular.shareFat,
                  onPressed: _sharing
                      ? null
                      : () => _share(session, stats),
                ),
                const SizedBox(height: Spacing.sm),
                AppButton(
                  label: 'View all rounds',
                  kind: AppButtonKind.outlined,
                  icon: PhosphorIconsRegular.listNumbers,
                  onPressed: () {
                    Haptics.selection();
                    context.push('/history/${session.id}/rounds');
                  },
                ),
                if (!widget.fromHistory) ...[
                  const SizedBox(height: Spacing.sm),
                  AppButton(
                    label: 'Back to Home',
                    kind: AppButtonKind.outlined,
                    icon: PhosphorIconsRegular.house,
                    onPressed: () {
                      Haptics.selection();
                      context.go('/');
                    },
                  ),
                ],
                const SizedBox(height: Spacing.lg),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_confetti.value),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatCards(SessionStats stats) {
    // Lead with the headline achievements (target wins, streaks), then the
    // big single-round swings, with flavour stats last — so the grid scans
    // top-down from most to least useful.
    final scheme = Theme.of(context).colorScheme;
    final danger = dangerColor(scheme.brightness);
    final success = successColor(scheme.brightness);
    final cards = <Widget>[];
    if (stats.mostBidsWon != null) {
      final count = stats.mostBidsWon!.count;
      cards.add(StatsCard(
        icon: PhosphorIconsFill.target,
        title: 'Most targets won',
        value: stats.mostBidsWon!.name,
        avatarName: stats.mostBidsWon!.name,
        subtitle: '$count ${count == 1 ? 'target' : 'targets'}',
      ));
    }
    if (stats.longestWinStreak != null) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.flame,
        title: 'Longest win streak',
        value: stats.longestWinStreak!.name,
        avatarName: stats.longestWinStreak!.name,
        subtitle: '${stats.longestWinStreak!.streak} in a row',
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
        subtitle:
            'avg ${stats.boldestBidder!.avg.toStringAsFixed(0)}',
      ));
    }
    // A gentle roast for last place — only in games big enough that it's
    // clearly a joke, and never when the "loser" actually tied the winner.
    if (stats.ranked.length >= 3 &&
        stats.ranked.last.score != stats.ranked.first.score) {
      cards.add(StatsCard(
        icon: PhosphorIconsFill.smileyMeh,
        title: 'The wooden spoon',
        value: stats.ranked.last.name,
        avatarName: stats.ranked.last.name,
        subtitle: _pick(_spoonQuips, _quipSeed),
      ));
    }
    return cards;
  }
}

/// One-liners for the summary. Picked deterministically per session so the
/// joke doesn't reshuffle on rebuild or when reopening from History.
const _winnerQuips = [
  'Skill? Luck? We may never know.',
  'Someone check their sleeves. 🃏',
  'The cards feared them tonight.',
  'Frame this. Print it. Hang it.',
  'Retire now — go out on top.',
  'Statistically suspicious. Officially impressive.',
];

const _tieQuips = [
  'Nobody loses. Nobody wins. Rematch?',
  'Two crowns, one throne. Awkward.',
  'Settle it over the next deal.',
];

const _spoonQuips = [
  'Carried the vibes, not the points.',
  'Moral support MVP.',
  'The comeback starts next game.',
  'Shuffled beautifully, though.',
  'Bravely kept everyone else off last place.',
];

String _pick(List<String> list, int seed) => list[seed.abs() % list.length];

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t >= 1) return;
    final rng = math.Random(42);
    // Brand palette: indigos + golds with a couple of card-table accents.
    final colors = const [
      Color(0xFFE7B84B),
      Color(0xFF6257E8),
      Color(0xFF4338CA),
      Color(0xFFD9A31E),
      Color(0xFFEF5350),
      Color(0xFFFFFFFF),
    ];
    for (var i = 0; i < 90; i++) {
      final x0 = rng.nextDouble() * size.width;
      final fallSpeed = 0.6 + rng.nextDouble() * 0.8;
      final sway = (rng.nextDouble() - 0.5) * 60;
      final phase = rng.nextDouble() * math.pi * 2;
      final x = x0 + math.sin(t * math.pi * 3 + phase) * sway * t;
      final y = (t * fallSpeed) * (size.height + 60) - 20;
      final rotation = t * (rng.nextDouble() - 0.5) * 8;
      final color = colors[rng.nextInt(colors.length)]
          .withValues(alpha: (1 - t).clamp(0.0, 1.0));
      final circle = rng.nextDouble() < 0.3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final paint = Paint()..color = color;
      if (circle) {
        canvas.drawCircle(Offset.zero, 4.5, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-4, -8, 8, 16), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// The emotional peak of the summary — a gold-accented banner naming the
/// winner (or declaring a tie). Shown for every game, including 2-player
/// ones that don't qualify for the 3-step podium.
class _WinnerBanner extends StatelessWidget {
  final String name;
  final int score;
  final bool tie;
  final String quip;
  const _WinnerBanner(
      {required this.name,
      required this.score,
      required this.tie,
      required this.quip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg, vertical: Spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.secondary.withValues(alpha: 0.22),
            scheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            tie ? PhosphorIconsFill.handshake : PhosphorIconsFill.trophy,
            size: 34,
            color: scheme.secondary,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tie ? 'It\'s a tie!' : '$name wins!',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tie
                      ? 'Top score ${formatScore(score)}'
                      : 'Final score ${formatScore(score)}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quip,
                  style: text.bodySmall?.copyWith(
                    color: scheme.secondary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
