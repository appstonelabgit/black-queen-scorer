import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/live/live_code.dart';
import '../../core/live/live_view_history.dart';
import '../../core/theme/tokens.dart';
import 'watch_history_screen.dart';

/// How many recent games to show inline before collapsing the rest behind
/// a "View all" entry.
const _inlineRecentCount = 1;

/// Sheet result signalling the caller should open the full history screen
/// rather than navigate to a code.
const _viewAllResult = '__view_all__';

/// Opens the "watch a live game" code entry as a modal bottom sheet. On a
/// valid code it dismisses and navigates the caller into the viewer; on the
/// "View all" action it pushes the full history screen.
Future<void> showWatchLiveSheet(BuildContext context) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _WatchLiveSheet(),
  );
  if (result == null || !context.mounted) return;
  // push (not go) so screens are a standard push onto Home — gives the
  // platform push/pop transition, a working back button, and iOS edge-swipe
  // back instead of replacing the stack.
  if (result == _viewAllResult) {
    context.push('/watch-history');
  } else {
    context.push('/live/$result');
  }
}

/// Input formatter: uppercase, drop invalid characters, auto-insert the
/// dash after the 4th alphanumeric, cap at 8 alphanumerics.
class _LiveCodeFormatter extends TextInputFormatter {
  const _LiveCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .characters
        .take(8)
        .join();
    final formatted = cleaned.length <= 4
        ? cleaned
        : '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _WatchLiveSheet extends StatefulWidget {
  const _WatchLiveSheet();

  @override
  State<_WatchLiveSheet> createState() => _WatchLiveSheetState();
}

class _WatchLiveSheetState extends State<_WatchLiveSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) return;
    final formatted = const _LiveCodeFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: pasted),
    );
    setState(() {
      _controller.value = formatted;
      _error = null;
    });
  }

  void _go() {
    final code = normalizeLiveCode(_controller.text);
    if (!isValidLiveCode(code)) {
      setState(() => _error =
          'Codes look like ABCD-EFGH. Check what was shared with you.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final recent = LiveViewHistory.instance.recent();
    // Keep the list visible on open when there's history; only steal focus
    // (and raise the keyboard) when there's nothing to pick from.
    final autofocus = recent.isEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(PhosphorIconsFill.broadcast, size: 44, color: scheme.primary),
            const SizedBox(height: Spacing.sm),
            Text('Enter the code',
                style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.xs),
            Text(
              'Anyone hosting a session can share a code that looks like ABCD-EFGH.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _controller,
              autofocus: autofocus,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 9,
              style: text.headlineMedium?.copyWith(letterSpacing: 6),
              inputFormatters: const [_LiveCodeFormatter()],
              decoration: InputDecoration(
                hintText: 'ABCD-EFGH',
                counterText: '',
                errorText: _error,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Paste code',
                  icon: const Icon(PhosphorIconsRegular.clipboard),
                  onPressed: _paste,
                ),
              ),
              onSubmitted: (_) => _go(),
            ),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: _go,
              icon: const Icon(PhosphorIconsRegular.arrowRight, size: 18),
              label: const Text('Watch live'),
            ),
            _RecentlyWatched(
              onPick: (code) => Navigator.of(context).pop(code),
              onViewAll: () => Navigator.of(context).pop(_viewAllResult),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Recently watched" preview — shows the most recent game inline, with a
/// "View all" entry when there are more. Rebuilds against the history box so
/// removing or clearing updates in place. Renders nothing when empty.
class _RecentlyWatched extends StatelessWidget {
  final ValueChanged<String> onPick;
  final VoidCallback onViewAll;
  const _RecentlyWatched({required this.onPick, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: LiveViewHistory.instance.listenable,
      builder: (context, _) {
        final recent = LiveViewHistory.instance.recent();
        if (recent.isEmpty) return const SizedBox.shrink();
        final shown = recent.take(_inlineRecentCount).toList();
        final remaining = recent.length - shown.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Spacing.lg),
            Text('Recently watched',
                style:
                    text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: Spacing.xs),
            ...shown.map((g) => LiveGameTile(game: g, onPick: onPick)),
            if (remaining > 0)
              TextButton(
                onPressed: onViewAll,
                child: Text('View all ($remaining more)'),
              ),
          ],
        );
      },
    );
  }
}
