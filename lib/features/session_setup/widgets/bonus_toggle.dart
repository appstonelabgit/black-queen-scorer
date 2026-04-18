import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/strings.dart';
import '../../../core/theme/tokens.dart';

class BonusToggle extends StatelessWidget {
  final bool enabled;
  final int amount;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onAmountChanged;

  const BonusToggle({
    super.key,
    required this.enabled,
    required this.amount,
    required this.onEnabledChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(Strings.enableBonus, style: text.bodyLarge),
              ),
              Switch.adaptive(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
        ),
        AnimatedSize(
          duration: AppDurations.base,
          curve: Curves.easeOutCubic,
          child: enabled
              ? Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: TextFormField(
                    initialValue: amount.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: Strings.bonusAmount,
                      hintText: '100',
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      onAmountChanged(n.clamp(0, 9999));
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: Spacing.xs),
        Text(Strings.bonusHelper,
            style: text.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
