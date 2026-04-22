import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/strings.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/shell_back_button.dart';
import 'demo_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: const Text(Strings.settings),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spacing.md, Spacing.sm, Spacing.md, Spacing.lg),
          children: [
            _SettingsCard(
              icon: PhosphorIconsRegular.palette,
              title: 'Appearance',
              subtitle: 'Match system or pick a side.',
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(PhosphorIconsRegular.deviceMobile, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(PhosphorIconsRegular.sun, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(PhosphorIconsRegular.moon, size: 16),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (set) {
                  ref.read(themeControllerProvider.notifier).set(set.first);
                },
              ),
            ),
            const SizedBox(height: Spacing.md),
            _SettingsCard(
              icon: PhosphorIconsRegular.database,
              title: 'Data',
              subtitle:
                  'Nothing leaves your device — these controls only affect local storage.',
              child: Column(
                children: [
                  _ActionRow(
                    icon: PhosphorIconsRegular.users,
                    title: 'Manage recent players',
                    subtitle: 'Rename or delete saved names.',
                    onTap: () => context.push('/settings/players'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  _ActionRow(
                    icon: PhosphorIconsRegular.trash,
                    title: 'Delete all history',
                    subtitle: 'Every session will be removed permanently.',
                    destructive: true,
                    onTap: () async {
                      final ok = await ConfirmDialog.typedDelete(
                        context,
                        title: 'Delete all history?',
                        body:
                            'This permanently removes every finished and active session.',
                      );
                      if (!ok) return;
                      final repo = ref.read(sessionRepositoryProvider);
                      for (final s in repo.getAll()) {
                        await repo.delete(s.id);
                      }
                      if (!context.mounted) return;
                      AppToast.show(
                        context,
                        'All history deleted',
                        style: ToastStyle.success,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (kDebugMode &&
                !const bool.fromEnvironment('MARKETING',
                    defaultValue: false)) ...[
              const SizedBox(height: Spacing.md),
              _SettingsCard(
                icon: PhosphorIconsRegular.flask,
                title: 'Developer',
                subtitle: 'Debug-only. Hidden in release builds.',
                child: _ActionRow(
                  icon: PhosphorIconsRegular.sparkle,
                  title: 'Seed demo data',
                  subtitle:
                      'Populate 2 finished sessions + 1 active session + 8 recent players, for marketing screenshots.',
                  onTap: () async {
                    final ok = await ConfirmDialog.show(
                      context,
                      title: 'Seed demo data?',
                      body:
                          'Any existing sessions with ids demo-a / demo-b / demo-active will be overwritten.',
                      confirmLabel: 'Seed',
                    );
                    if (!ok) return;
                    await seedDemoData(
                      sessions: ref.read(sessionRepositoryProvider),
                      players: ref.read(playersRepositoryProvider),
                    );
                    ref.read(recentPlayersProvider.notifier).refresh();
                    if (!context.mounted) return;
                    AppToast.show(
                      context,
                      'Demo data seeded',
                      style: ToastStyle.success,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            const _AboutCard(),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: Spacing.sm),
              Text(title, style: text.titleMedium),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                subtitle!,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tint = destructive ? scheme.error : scheme.onSurface;
    final bg = destructive
        ? scheme.error.withValues(alpha: 0.08)
        : scheme.surface.withValues(alpha: 0.4);
    final border = destructive
        ? scheme.error.withValues(alpha: 0.35)
        : scheme.outlineVariant.withValues(alpha: 0.35);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm + 2),
          child: Row(
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: text.titleSmall?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight,
                  size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(
              color: scheme.secondary.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(PhosphorIconsFill.spade,
                  size: 34, color: Colors.black.withValues(alpha: 0.35)),
              Icon(PhosphorIconsFill.crown,
                  size: 18, color: scheme.secondary),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          Strings.appName,
          style: text.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          Strings.version,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Made for card nights.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
