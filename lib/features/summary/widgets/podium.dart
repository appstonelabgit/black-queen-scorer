import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/scoring.dart';
import '../../session_setup/widgets/player_chip.dart';

class Podium extends StatelessWidget {
  final List<PlayerScore> top;
  const Podium({super.key, required this.top});

  @override
  Widget build(BuildContext context) {
    if (top.length < 3) return const SizedBox.shrink();
    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _Step(
              player: top[1],
              color: const Color(0xFFC0C0C0),
              height: 110,
              place: 2,
            ),
          ),
          Expanded(
            child: _Step(
              player: top[0],
              color: const Color(0xFFFFD700),
              height: 150,
              place: 1,
              highlight: true,
            ),
          ),
          Expanded(
            child: _Step(
              player: top[2],
              color: const Color(0xFFCD7F32),
              height: 80,
              place: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final PlayerScore player;
  final Color color;
  final double height;
  final int place;
  final bool highlight;
  const _Step({
    required this.player,
    required this.color,
    required this.height,
    required this.place,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final avatar = playerColor(player.name, brightness);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: highlight ? 54 : 44,
          height: highlight ? 54 : 44,
          decoration: BoxDecoration(
            color: avatar,
            shape: BoxShape.circle,
            border: highlight
                ? Border.all(color: scheme.secondary, width: 2.5)
                : null,
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: scheme.secondary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            playerInitial(player.name),
            style: (highlight ? text.titleLarge : text.titleMedium)
                ?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        Text(
          formatScore(player.score),
          style: text.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.md)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: text.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 32 : 26,
            ),
          ),
        ),
      ],
    );
  }
}
