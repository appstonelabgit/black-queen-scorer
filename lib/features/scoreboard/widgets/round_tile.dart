import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
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
    final posColor = successColor(brightness);
    final negColor = dangerColor(brightness);

    // Fine round (stored as a free-score round): one player loses the amount,
    // everyone else 0. Render its own compact summary rather than the bid shape.
    final bool isFine = round.isFree;
    late final String title;
    late final String deltaLabel;
    if (isFine) {
      final offender = round.scores!.entries.firstWhere(
        (e) => e.value < 0,
        orElse: () => const MapEntry('\u2014', 0),
      );
      final amountStr = formatBid(offender.value.abs());
      title = '${offender.key} \u00b7 Fine';
      deltaLabel = '\u2212$amountStr';
    } else {
      final teamLabel = _summarizeTeam(round);
      final bidStr = formatBid(round.bidAmount);
      final resultStr = won ? 'Won' : 'Lost';
      title = '$teamLabel \u00b7 target $bidStr \u00b7 $resultStr';
      deltaLabel =
          '${won ? '+' : '\u2212'}$bidStr / ${won ? '\u2212' : '+'}$bidStr';
    }

    final semanticsLabel = 'Round $index, $title, $deltaLabel';

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        onLongPress: onLongPress == null
            ? null
            : () {
                Haptics.selection();
                onLongPress!();
              },
        child: Semantics(
          button: true,
          label: semanticsLabel,
          onLongPressHint: 'Round options',
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
                      title,
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
                  color: (isFine || !won) ? negColor : posColor,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
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
