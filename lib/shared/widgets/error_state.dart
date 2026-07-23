import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Branded error placeholder with an optional retry affordance.
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.icon = PhosphorIconsRegular.warningCircle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.error),
            const SizedBox(height: Spacing.md),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                message!,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Branded loading placeholder carrying the app's spade motif.
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.spade, size: 40, color: scheme.primary),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: scheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
