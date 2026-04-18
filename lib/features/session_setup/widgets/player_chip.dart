import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';

class PlayerChip extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  const PlayerChip({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final avatarColor = _colorFor(name, scheme.brightness);
    final bg = selected
        ? scheme.secondary.withValues(alpha: 0.18)
        : scheme.surfaceContainerHighest;
    final borderColor = selected
        ? scheme.secondary
        : scheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: InkWell(
            onTap: enabled
                ? () {
                    Haptics.selection();
                    onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm + 2,
                vertical: Spacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      playerInitial(name),
                      style: text.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(name, style: text.bodyMedium),
                  if (selected) ...[
                    const SizedBox(width: Spacing.xs),
                    Icon(Icons.check, size: 16, color: scheme.secondary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _colorFor(String name, Brightness b) {
  final palette = b == Brightness.light
      ? const [
          Color(0xFF0F5132),
          Color(0xFFB7791F),
          Color(0xFF6B46C1),
          Color(0xFFC53030),
          Color(0xFF2C7A7B),
          Color(0xFF975A16),
          Color(0xFFB83280),
        ]
      : const [
          Color(0xFF198754),
          Color(0xFFE8B931),
          Color(0xFF9F7AEA),
          Color(0xFFFC8181),
          Color(0xFF4FD1C5),
          Color(0xFFF6AD55),
          Color(0xFFF687B3),
        ];
  final key = name.toLowerCase();
  var hash = 0;
  for (var i = 0; i < key.length; i++) {
    hash = (hash * 31 + key.codeUnitAt(i)) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

Color playerColor(String name, Brightness b) => _colorFor(name, b);
