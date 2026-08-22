import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../features/session_setup/widgets/player_chip.dart'
    show playerColor;
import 'player_record.dart';

/// The leaderboard row used by both the host's scoreboard and the live
/// viewer, so the two screens stay visually identical: rank (trophy for the
/// leader once play starts), avatar, name, C/W/L record, signed score.
///
/// Host-only extras are opt-in: [pulseDelta] animates the score colour on
/// changes. A trailing caret appears whenever the row is tappable.
class LeaderboardPlayerRow extends StatefulWidget {
  final int rank;
  final String name;
  final int score;

  /// Gates the rank-1 trophy — false before the first round is scored, when
  /// standings don't mean anything yet.
  final bool leading;
  final int calls;
  final int wins;
  final int losses;
  final VoidCallback? onTap;
  final int? pulseDelta;

  const LeaderboardPlayerRow({
    super.key,
    required this.rank,
    required this.name,
    required this.score,
    this.leading = true,
    this.calls = 0,
    this.wins = 0,
    this.losses = 0,
    this.onTap,
    this.pulseDelta,
  });

  @override
  State<LeaderboardPlayerRow> createState() => _LeaderboardPlayerRowState();
}

class _LeaderboardPlayerRowState extends State<LeaderboardPlayerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant LeaderboardPlayerRow old) {
    super.didUpdateWidget(old);
    if (widget.pulseDelta != null &&
        widget.pulseDelta != 0 &&
        widget.score != old.score) {
      final disableAnim = MediaQuery.of(context).disableAnimations;
      if (!disableAnim) {
        _ctrl.forward(from: 0);
      }
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
    final brightness = Theme.of(context).brightness;
    final isLeader = widget.leading && widget.rank == 1;
    final pulseColor = (widget.pulseDelta ?? 0) > 0
        ? successColor(brightness)
        : dangerColor(brightness);
    final record = widget.calls + widget.wins + widget.losses;

    Color baseColor() {
      if (widget.score == 0) return scheme.onSurfaceVariant;
      if (widget.score > 0) return successColor(brightness);
      return dangerColor(brightness);
    }

    return Semantics(
      button: widget.onTap != null,
      excludeSemantics: true,
      label:
          'Rank ${widget.rank}, ${widget.name}, ${formatScore(widget.score)}'
          '${PlayerRecordLabel.semanticsSuffix(widget.calls, widget.wins, widget.losses)}',
      onTapHint:
          widget.onTap == null ? null : 'View round-by-round history',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: widget.onTap == null
              ? null
              : () {
                  Haptics.selection();
                  widget.onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xs, vertical: Spacing.sm + 2),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: isLeader
                      ? Icon(PhosphorIconsFill.trophy,
                          color: scheme.secondary, size: 22)
                      : Text('${widget.rank}',
                          style: text.titleMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: Spacing.sm),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: playerColor(widget.name, brightness),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    playerInitial(widget.name),
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(widget.name,
                            style: text.bodyLarge,
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Record — calls made, rounds won, rounds lost.
                      // Appears once the first bid round is scored.
                      if (record > 0) ...[
                        const SizedBox(width: Spacing.sm),
                        Flexible(
                          child: PlayerRecordLabel(
                            calls: widget.calls,
                            wins: widget.wins,
                            losses: widget.losses,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final t = _ctrl.value;
                    final strength = t < 1 / 3 ? t * 3 : (1 - t) * 1.5;
                    final color = Color.lerp(
                        baseColor(), pulseColor, strength.clamp(0, 1))!;
                    return Text(
                      formatScore(widget.score),
                      style: text.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
                if (widget.onTap != null) ...[
                  const SizedBox(width: Spacing.xs),
                  Icon(PhosphorIconsRegular.caretRight,
                      size: 14, color: scheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
