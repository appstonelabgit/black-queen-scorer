import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ads/ad_service.dart';
import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../live/watch_live_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsStreamProvider);
    final active = ref.watch(activeSessionProvider);
    final allSessions = sessionsAsync.value ?? const <Session>[];
    final finished = allSessions.where((s) => s.finishedAt != null).toList();
    final lifetimeRounds =
        finished.fold<int>(0, (sum, s) => sum + s.rounds.length);
    final uniquePlayers = <String>{
      for (final s in finished)
        for (final p in s.players) p.toLowerCase(),
    }.length;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _FeltBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.sm, Spacing.lg, Spacing.lg),
              children: [
                const _Brand(),
                const SizedBox(height: Spacing.lg),
                if (active != null) ...[
                  _ResumeCard(session: active),
                  const SizedBox(height: Spacing.md),
                ],
                _PrimaryCta(
                  active: active,
                  onStart: () async {
                    Haptics.medium();
                    if (active != null) {
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
                          .delete(active.id);
                    }
                    if (context.mounted) context.push('/setup');
                  },
                ),
                const SizedBox(height: Spacing.md),
                if (finished.isNotEmpty)
                  _StatsCard(
                    sessions: finished.length,
                    rounds: lifetimeRounds,
                    players: uniquePlayers,
                    onTap: () => context.push('/history'),
                  )
                else
                  const _WelcomeHint(),
                const SizedBox(height: Spacing.md),
                const _SponsoredAd(),
                const SizedBox(height: Spacing.md),
                Center(
                  child: Text(
                    ref.watch(appVersionProvider).value ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _GlassActionBar(
        onShareApp: () {
          SharePlus.instance.share(
            ShareParams(
              text:
                  'Black Queen Scorer — fast offline scorer for Court Piece, Rang, 29, Partner 29. Live-share your card night.\n'
                  'Get it: https://appstonelabgit.github.io/black-queen-scorer/',
              subject: 'Black Queen Scorer',
            ),
          );
        },
        onWatchLive: () => showWatchLiveSheet(context),
        onSettings: () => context.push('/settings'),
      ),
    );
  }
}

class _FeltBackdrop extends StatelessWidget {
  const _FeltBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.surface,
                    scheme.surface,
                  ]
                : [
                    scheme.primary.withValues(alpha: 0.08),
                    scheme.surface,
                    scheme.surface,
                  ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: 60,
              child: Opacity(
                opacity: isDark ? 0.06 : 0.08,
                child: Icon(
                  PhosphorIconsFill.spade,
                  size: 180,
                  color: scheme.secondary,
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 40,
              child: Opacity(
                opacity: isDark ? 0.05 : 0.06,
                child: Icon(
                  PhosphorIconsFill.club,
                  size: 140,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted-glass action bar pinned to the bottom of Home. Blurs whatever
/// felt/content sits behind it and floats the three primary actions, freeing
/// the top of the screen for the native ad.
class _GlassActionBar extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onWatchLive;
  final VoidCallback onShareApp;
  const _GlassActionBar({
    required this.onSettings,
    required this.onWatchLive,
    required this.onShareApp,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? 0.55 : 0.7),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: Spacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BarAction(
                    icon: PhosphorIconsRegular.shareNetwork,
                    label: 'Share',
                    onTap: onShareApp,
                  ),
                  _BarAction(
                    icon: PhosphorIconsRegular.broadcast,
                    label: 'Watch live',
                    onTap: onWatchLive,
                  ),
                  _BarAction(
                    icon: PhosphorIconsRegular.gearSix,
                    label: 'Settings',
                    onTap: onSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: scheme.onSurface),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Native ad with a quiet "Sponsored" caption so it reads as paid placement,
/// not app content. Caption + ad appear together — both hidden until an ad
/// actually loads, so no orphan label floats on screen.
class _SponsoredAd extends StatelessWidget {
  const _SponsoredAd();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.readyNotifier,
      builder: (_, ready, __) {
        if (!ready) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: AdService.nativeExhausted,
          builder: (_, exhausted, __) {
            // Hide the whole block only once the native ad has exhausted its
            // retries — not on a transient failure mid-retry, which would
            // unmount the slot and kill the retry loop.
            if (exhausted) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: Spacing.xs, bottom: 6),
                  child: Text(
                    'Sponsored',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                AdService.nativeMedium(),
              ],
            );
          },
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    const titleStyle = TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      fontSize: 26,
      height: 1.1,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Crest: gold queen-on-spade mark over emerald card felt.
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(
              color: scheme.secondary.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                PhosphorIconsFill.spade,
                size: 32,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              Icon(
                PhosphorIconsFill.crown,
                size: 16,
                color: scheme.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: titleStyle,
                  children: [
                    TextSpan(
                      text: 'Black ',
                      style: titleStyle.copyWith(color: scheme.onSurface),
                    ),
                    TextSpan(
                      text: 'Queen',
                      style: titleStyle.copyWith(color: scheme.secondary),
                    ),
                    TextSpan(
                      text: ' Scorer',
                      style: titleStyle.copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Strings.tagline,
                style:
                    text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final Session? active;
  final VoidCallback onStart;
  const _PrimaryCta({required this.active, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.secondary, 0.25)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onStart,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(PhosphorIconsRegular.plus,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: Spacing.sm + 4),
                const Flexible(
                  child: Text(
                    Strings.startNewSession,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHint extends StatelessWidget {
  const _WelcomeHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(PhosphorIconsRegular.sparkle,
                color: scheme.secondary, size: 20),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ready when you are',
                    style: text.titleMedium?.copyWith(
                        color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  'Add 4–12 players, pick a bonus, start tallying rounds.',
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

class _StatsCard extends StatelessWidget {
  final int sessions;
  final int rounds;
  final int players;
  final VoidCallback onTap;

  const _StatsCard({
    required this.sessions,
    required this.rounds,
    required this.players,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsRegular.clockCounterClockwise,
                      size: 18, color: scheme.onSurface),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                      child: Text('Your history',
                          style: text.titleMedium
                              ?.copyWith(color: scheme.onSurface))),
                  Icon(PhosphorIconsRegular.caretRight,
                      size: 16, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: Spacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatCell(label: 'Sessions', value: '$sessions'),
                    _Divider(),
                    _StatCell(label: 'Rounds', value: '$rounds'),
                    _Divider(),
                    _StatCell(label: 'Players', value: '$players'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.headlineMedium?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _ResumeCard extends ConsumerStatefulWidget {
  final Session session;
  const _ResumeCard({required this.session});

  @override
  ConsumerState<_ResumeCard> createState() => _ResumeCardState();
}

class _ResumeCardState extends ConsumerState<_ResumeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = 1;
    } else if (!_started) {
      _started = true;
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final s = widget.session;
    final summary =
        '${plural(s.players.length, 'player')} · ${plural(s.rounds.length, 'round')} · ${formatDuration(s.duration)}';

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: () => context.push('/session/${s.id}'),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              color: scheme.primary.withValues(alpha: 0.14),
              border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.35), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(PhosphorIconsFill.playCircle,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Session in progress',
                            style: text.titleMedium
                                ?.copyWith(color: scheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                  IconButton(
                    iconSize: 20,
                    tooltip: Strings.discardSession,
                    icon: Icon(PhosphorIconsRegular.xCircle,
                        color: scheme.error),
                    onPressed: () async {
                      Haptics.selection();
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
                          .delete(s.id);
                    },
                  ),
                  const SizedBox(width: Spacing.xs),
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
}
