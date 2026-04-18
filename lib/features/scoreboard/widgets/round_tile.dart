import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/round.dart';
import '../../../data/models/session.dart';

class RoundTile extends StatelessWidget {
  final int index;
  final Round round;
  final Session session;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const RoundTile({
    super.key,
    required this.index,
    required this.round,
    required this.session,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final won = round.won;
    final posColor = brightness == Brightness.light
        ? const Color(0xFF2E7D32)
        : const Color(0xFF66BB6A);
    final negColor = brightness == Brightness.light
        ? const Color(0xFFC62828)
        : const Color(0xFFEF5350);

    final teamLabel = _summarizeTeam(round);
    final bidStr = formatBid(round.bidAmount);
    final resultStr = won ? 'Won' : 'Lost';
    final deltaLabel =
        '${won ? '+' : '\u2212'}$bidStr / ${won ? '\u2212' : '+'}$bidStr';

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm + 2),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('#$index',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$teamLabel · bid $bidStr · $resultStr',
                      style: text.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                deltaLabel,
                style: text.bodyMedium?.copyWith(
                  color: won ? posColor : negColor,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summarizeTeam(Round r) {
    if (r.team.length == 1) return '${r.bidder} (alone)';
    final others = r.team.where((n) => n != r.bidder).toList();
    if (others.length == 1) return '${r.bidder} & ${others.first}';
    return '${r.bidder} & ${others.length} more';
  }
}
