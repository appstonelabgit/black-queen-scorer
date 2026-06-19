import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../session_setup/widgets/player_chip.dart';

/// Two-column grid of [StatsCard]s whose row height scales with the user's
/// text size, so cards don't clip their value/subtitle at large accessibility
/// text scales (the old fixed childAspectRatio overflowed).
class StatsGrid extends StatelessWidget {
  final List<Widget> cards;
  const StatsGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final scale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
        // Fits the 3-line card (icon row + value + subtitle) with breathing
        // room, and grows with the text scale.
        mainAxisExtent: 100 * scale,
      ),
      children: cards,
    );
  }
}

/// A compact stat tile. Leads with either a player's colored avatar (when
/// [avatarName] is set) or a brand-tinted Phosphor [icon]. Optionally tappable
/// (e.g. to open a player's lifetime breakdown).
class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final String? avatarName;
  final Color? accent;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.avatarName,
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tint = accent ?? scheme.secondary;

    final leading = avatarName != null
        ? Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: playerColor(avatarName!, scheme.brightness),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              playerInitial(avatarName!),
              style: text.labelSmall
                  ?.copyWith(color: Colors.white, fontSize: 12),
            ),
          )
        : Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: tint),
          );

    final card = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + 4, vertical: Spacing.sm + 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: onTap != null
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: Spacing.xs + 2),
              Expanded(
                child: Text(
                  title,
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(PhosphorIconsRegular.caretRight,
                    size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: Spacing.xs + 2),
          Text(
            value,
            style: text.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: '$title, $value${subtitle != null ? ', $subtitle' : ''}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}
