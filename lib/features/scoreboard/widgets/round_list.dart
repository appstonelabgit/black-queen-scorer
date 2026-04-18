import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/session.dart';
import '../../../shared/widgets/empty_state.dart';
import 'round_tile.dart';

typedef RoundAction = void Function(int index);

class RoundList extends StatelessWidget {
  final Session session;
  final RoundAction? onTap;
  final RoundAction? onLongPress;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  const RoundList({
    super.key,
    required this.session,
    this.onTap,
    this.onLongPress,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rounds = session.rounds;

    if (rounds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.lg),
        child: EmptyState(
          title: 'No rounds yet',
          subtitle: 'Tap New Round to begin.',
        ),
      );
    }

    final reversed = List.generate(rounds.length, (i) => rounds.length - 1 - i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleCollapsed,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: Spacing.sm, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Rounds (${rounds.length})',
                      style: text.titleMedium),
                ),
                Icon(
                  collapsed
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppDurations.base,
          curve: Curves.easeOutCubic,
          child: collapsed
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    for (final i in reversed) ...[
                      RoundTile(
                        index: i + 1,
                        round: rounds[i],
                        session: session,
                        onTap: onTap == null ? null : () => onTap!(i),
                        onLongPress: onLongPress == null
                            ? null
                            : () => onLongPress!(i),
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
