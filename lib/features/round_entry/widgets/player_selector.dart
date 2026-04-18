import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../session_setup/widgets/player_chip.dart';

class PlayerSelector extends StatelessWidget {
  final List<String> players;
  final bool multiSelect;
  final Set<String> selected;
  final void Function(String) onToggle;
  final bool enabled;
  final String? excludeName;

  const PlayerSelector({
    super.key,
    required this.players,
    required this.multiSelect,
    required this.selected,
    required this.onToggle,
    this.enabled = true,
    this.excludeName,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = excludeName == null
        ? players
        : players.where((p) => p != excludeName).toList();
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final p in filtered)
              PlayerChip(
                name: p,
                selected: selected.contains(p),
                onTap: () => onToggle(p),
              ),
          ],
        ),
      ),
    );
  }
}
