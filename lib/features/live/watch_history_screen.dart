import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/live/live_view_history.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/shell_back_button.dart';

/// Full screen listing every live game the user has watched. Pushed from the
/// Watch Live sheet's "View all"; tapping a game opens its viewer.
class WatchHistoryScreen extends StatelessWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: const Text('Recently watched'),
        actions: [
          AnimatedBuilder(
            animation: LiveViewHistory.instance.listenable,
            builder: (context, _) {
              if (LiveViewHistory.instance.recent().isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  final ok = await ConfirmDialog.show(
                    context,
                    title: 'Clear watch history?',
                    body:
                        'This removes the list of games you\'ve watched. It won\'t affect anyone\'s session.',
                    confirmLabel: 'Clear',
                    destructive: true,
                  );
                  if (ok) await LiveViewHistory.instance.clear();
                },
                child: const Text('Clear'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: LiveViewHistory.instance.listenable,
          builder: (context, _) {
            final recent = LiveViewHistory.instance.recent();
            if (recent.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.broadcast,
                          size: 40, color: scheme.onSurfaceVariant),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Games you watch will show up here.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: recent.length,
              itemBuilder: (context, i) => LiveGameTile(
                game: recent[i],
                onPick: (code) => context.push('/live/$code'),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A single watched-game row — tap to open, ✕ to remove. Shared by the Watch
/// Live sheet's inline preview and the full history screen.
class LiveGameTile extends StatelessWidget {
  final ViewedLiveGame game;
  final ValueChanged<String> onPick;
  const LiveGameTile({super.key, required this.game, required this.onPick});

  String get _title {
    final p = game.players;
    if (p.isEmpty) return 'Live game';
    if (p.length <= 2) return p.join(', ');
    return '${p.take(2).join(', ')} +${p.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => onPick(game.code),
        child: Semantics(
          button: true,
          label:
              '$_title, ${game.code}, ${game.finished ? "ended" : "live"}',
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm, vertical: Spacing.sm),
            child: Row(
              children: [
                Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                alignment: Alignment.center,
                child: Icon(
                  game.finished
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsFill.broadcast,
                  size: 20,
                  color:
                      game.finished ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium
                            ?.copyWith(color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      '${game.code} · ${game.finished ? 'Ended' : 'Live'} · ${formatRelativeDate(game.lastViewedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
                IconButton(
                  tooltip: 'Remove ${game.code}',
                  iconSize: 18,
                  icon: Icon(PhosphorIconsRegular.x,
                      color: scheme.onSurfaceVariant),
                  onPressed: () {
                    Haptics.selection();
                    LiveViewHistory.instance.remove(game.code);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
