import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';

/// Presentational round-list tile shared by the host's board and the live
/// viewer: `#N · <title> · <signed delta>`. Callers map their own round
/// model (local [Round] or RTDB [LiveRound]) into plain display fields so
/// both screens render rounds identically.
class RoundListTile extends StatelessWidget {
  final int index;
  final String title;
  final String deltaLabel;

  /// Colours the delta — losses/fines red, wins green.
  final bool negative;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? onLongPressHint;

  const RoundListTile({
    super.key,
    required this.index,
    required this.title,
    required this.deltaLabel,
    required this.negative,
    this.onTap,
    this.onLongPress,
    this.onLongPressHint,
  });

  /// `"Nest (alone)"`, `"Nest & Fast"`, or `"Nest & 2 more"`.
  static String summarizeTeam(String bidder, List<String> team) {
    final others = team.where((n) => n != bidder).toList();
    if (others.isEmpty) return '$bidder (alone)';
    if (others.length == 1) return '$bidder & ${others.first}';
    return '$bidder & ${others.length} more';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

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
          button: onTap != null || onLongPress != null,
          label: 'Round $index, $title, $deltaLabel',
          onLongPressHint: onLongPressHint,
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
                  child: Text(
                    title,
                    style: text.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  deltaLabel,
                  style: text.bodyMedium?.copyWith(
                    color: negative
                        ? dangerColor(brightness)
                        : successColor(brightness),
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
}
