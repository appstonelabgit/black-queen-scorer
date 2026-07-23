import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';

enum AppButtonKind { filled, outlined, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconData? icon;
  final Color? color;
  final double height;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.filled,
    this.icon,
    this.color,
    this.height = 52,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: Spacing.sm),
              Text(label),
            ],
          );

    Widget btn;
    switch (kind) {
      case AppButtonKind.filled:
        btn = FilledButton(
          onPressed: onPressed == null
              ? null
              : () {
                  Haptics.light();
                  onPressed!();
                },
          style: FilledButton.styleFrom(
            backgroundColor: color,
            minimumSize: Size(expanded ? double.infinity : 0, height),
          ),
          child: child,
        );
        break;
      case AppButtonKind.outlined:
        btn = OutlinedButton(
          onPressed: onPressed == null
              ? null
              : () {
                  Haptics.selection();
                  onPressed!();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            minimumSize: Size(expanded ? double.infinity : 0, height),
          ),
          child: child,
        );
        break;
      case AppButtonKind.text:
        btn = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: color),
          child: child,
        );
        break;
    }
    return btn;
  }
}
