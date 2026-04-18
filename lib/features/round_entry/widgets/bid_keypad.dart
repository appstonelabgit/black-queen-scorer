import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/haptics.dart';

class BidKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDoubleZero;
  final VoidCallback onBackspace;

  const BidKeypad({
    super.key,
    required this.onDigit,
    required this.onDoubleZero,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  Expanded(
                    child: _KeypadButton(
                      label: row[i],
                      onTap: () => onDigit(row[i]),
                    ),
                  ),
                  if (i < row.length - 1) const SizedBox(width: Spacing.sm),
                ],
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _KeypadButton(label: '00', onTap: onDoubleZero),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _KeypadButton(label: '0', onTap: () => onDigit('0')),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _KeypadButton.icon(
                icon: PhosphorIconsRegular.backspace,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({required String this.label, required this.onTap})
      : icon = null;
  const _KeypadButton.icon({required IconData this.icon, required this.onTap})
      : label = null;

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) => _c.reverse(),
      onTap: () {
        Haptics.light();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(
          scale: 1 - _c.value,
          child: child,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: widget.label != null
              ? Text(widget.label!,
                  style: text.headlineMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ))
              : Icon(widget.icon, size: 24),
        ),
      ),
    );
  }
}
