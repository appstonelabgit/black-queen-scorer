import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/providers.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../session_setup/widgets/player_chip.dart';

class ManagePlayersScreen extends ConsumerWidget {
  const ManagePlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(recentPlayersProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent players'),
        actions: [
          if (players.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'Clear all?',
                  body: 'Every saved name will be removed.',
                  confirmLabel: 'Clear all',
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(recentPlayersProvider.notifier).clear();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recent players cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: SafeArea(
        child: players.isEmpty
            ? const EmptyState(
                icon: PhosphorIconsDuotone.users,
                title: 'No saved players',
                subtitle:
                    'Names you use in sessions show up here so you can reuse them.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.md, Spacing.sm, Spacing.md, Spacing.lg),
                itemCount: players.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Spacing.sm),
                itemBuilder: (context, i) {
                  final name = players[i];
                  return Dismissible(
                    key: ValueKey(name.toLowerCase()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                          const EdgeInsets.symmetric(horizontal: Spacing.md),
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: const Icon(PhosphorIconsRegular.trash,
                          color: Colors.white),
                    ),
                    confirmDismiss: (_) async => await _confirmRemove(
                      context: context,
                      ref: ref,
                      name: name,
                    ),
                    child: _PlayerRow(
                      name: name,
                      onDelete: () => _confirmRemove(
                        context: context,
                        ref: ref,
                        name: name,
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: players.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.md, 0, Spacing.md, Spacing.md),
                child: Text(
                  '${players.length} saved · swipe or tap the trash to remove one',
                  textAlign: TextAlign.center,
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
    );
  }

  Future<bool> _confirmRemove({
    required BuildContext context,
    required WidgetRef ref,
    required String name,
  }) async {
    Haptics.selection();
    await ref.read(recentPlayersProvider.notifier).remove(name);
    if (!context.mounted) return true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    bool undone = false;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed $name'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            undone = true;
            await ref.read(recentPlayersProvider.notifier).add(name);
          },
        ),
      ),
    );
    return !undone;
  }
}

class _PlayerRow extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;
  const _PlayerRow({required this.name, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: playerColor(name, brightness),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              playerInitial(name),
              style: text.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(name, style: text.bodyLarge),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: Icon(PhosphorIconsRegular.trash, color: scheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
