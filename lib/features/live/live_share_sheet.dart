import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';

/// Share sheet shown from Scoreboard when users want friends to watch
/// the current session live. Displays QR + short code + share/copy actions.
class LiveShareSheet extends StatelessWidget {
  final String code;

  const LiveShareSheet({super.key, required this.code});

  String get _shareUrl =>
      'https://appstonelabgit.github.io/black-queen-scorer/l/$code';
  String get _shareText =>
      'Watch our card night live on Black Queen Scorer:\n$_shareUrl\nOr enter code $code in the app.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Icon(PhosphorIconsFill.broadcast, color: scheme.primary, size: 34),
            const SizedBox(height: Spacing.sm),
            Text('Watch live', style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Anyone with the code can follow this session\'s scoreboard in real time.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.lg),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: QrImageView(
                data: _shareUrl,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F5132),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0A1F1A),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SelectableText(
              code,
              style: text.headlineMedium?.copyWith(
                letterSpacing: 6,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _shareUrl));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                    label: const Text('Copy link'),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Share.share(_shareText);
                    },
                    icon: const Icon(PhosphorIconsRegular.shareNetwork,
                        size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLiveShareSheet(BuildContext context, String code) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
    ),
    builder: (_) => LiveShareSheet(code: code),
  );
}
