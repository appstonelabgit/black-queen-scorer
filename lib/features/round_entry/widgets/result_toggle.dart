import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/haptics.dart';

class ResultToggle extends StatelessWidget {
  final void Function(bool won) onPick;
  final bool enabled;

  const ResultToggle({
    super.key,
    required this.onPick,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final success = brightness == Brightness.light
        ? const Color(0xFF2E7D32)
        : const Color(0xFF388E3C);
    final danger = brightness == Brightness.light
        ? const Color(0xFFC62828)
        : const Color(0xFFB71C1C);
    return Row(
      children: [
        Expanded(
          child: _Btn(
            label: Strings.resultWon,
            icon: PhosphorIconsBold.check,
            color: success,
            onTap: enabled ? () => onPick(true) : null,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _Btn(
            label: Strings.resultLost,
            icon: PhosphorIconsBold.x,
            color: danger,
            onTap: enabled ? () => onPick(false) : null,
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
      lowerBound: 0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _c.forward() : null,
      onTapUp: enabled ? (_) => _c.reverse() : null,
      onTapCancel: enabled ? () => _c.reverse() : null,
      onTap: enabled
          ? () {
              Haptics.medium();
              widget.onTap!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(
          scale: 1 - _c.value,
          child: child,
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: Spacing.sm),
                Text(
                  widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
