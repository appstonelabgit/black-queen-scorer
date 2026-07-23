import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/round.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../session_setup/widgets/player_chip.dart' show playerColor;
import 'widgets/bid_keypad.dart';

/// Free-score round entry (Option A): every player on one screen, each with a
/// tappable value box. Tapping a box opens the same numeric keypad used by the
/// bid flow, with a +/− toggle for penalties. One "Save round" commits them all.
///
/// This is a sibling of the bid entry form; the router picks between them by
/// [Session.settings.isFreeScore]. The bid engine is untouched.
class FreeRoundEntryView extends ConsumerStatefulWidget {
  final Session session;
  final Round? existingRound;

  const FreeRoundEntryView({
    super.key,
    required this.session,
    required this.existingRound,
  });

  @override
  ConsumerState<FreeRoundEntryView> createState() => _FreeRoundEntryViewState();
}

class _FreeRoundEntryViewState extends ConsumerState<FreeRoundEntryView> {
  late final Map<String, int> _scores;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRound?.scores;
    _scores = {
      for (final p in widget.session.players) p: existing?[p] ?? 0,
    };
  }

  bool get _editing => widget.existingRound != null;

  int get _total => _scores.values.fold(0, (a, b) => a + b);

  /// At least one non-zero entry — an all-zero round carries no information.
  bool get _canSave => _dirty && _scores.values.any((v) => v != 0);

  /// Opens the keypad sheet to edit one player's score, sign included.
  void _editPlayer(String player) {
    Haptics.selection();
    // Local edit buffer; only written back on Done so Cancel is a no-op.
    var digits = _scores[player]!.abs() == 0 ? '' : _scores[player]!.abs().toString();
    var negative = _scores[player]! < 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final text = Theme.of(ctx).textTheme;
            final scheme = Theme.of(ctx).colorScheme;
            final n = int.tryParse(digits) ?? 0;
            final signed = negative ? -n : n;

            void pushDigit(String d) {
              Haptics.selection();
              if (digits == '0') digits = '';
              final next = digits + d;
              if (next.length > 5) return;
              setSheet(() => digits = next);
            }

            void backspace() {
              Haptics.selection();
              if (digits.isNotEmpty) {
                setSheet(() => digits = digits.substring(0, digits.length - 1));
              }
            }

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.lg, 0, Spacing.lg, Spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(player, style: text.titleMedium),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        digits.isEmpty
                            ? '0'
                            : '${negative ? '−' : ''}${formatBid(n)}',
                        style: text.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: digits.isEmpty
                              ? scheme.onSurfaceVariant
                              : negative
                                  ? dangerColor(scheme.brightness)
                                  : scheme.secondary,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      // Penalty / plus toggle. Full-width so it reads as a mode
                      // switch, not a keypad key.
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Add'),
                              icon: Icon(PhosphorIconsRegular.plus, size: 16),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Penalty'),
                              icon: Icon(PhosphorIconsRegular.minus, size: 16),
                            ),
                          ],
                          selected: {negative},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) {
                            Haptics.selection();
                            setSheet(() => negative = s.first);
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      BidKeypad(
                        onDigit: pushDigit,
                        onDoubleZero: () {
                          if (digits.isEmpty) return;
                          pushDigit('0');
                          pushDigit('0');
                        },
                        onBackspace: backspace,
                      ),
                      const SizedBox(height: Spacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _scores[player] = signed;
                              _dirty = true;
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    Haptics.medium();
    final scores = Map<String, int>.from(_scores);
    final Session updated;
    if (_editing) {
      final id = widget.existingRound!.id;
      updated = widget.session.copyWith(
        rounds: widget.session.rounds
            .map((r) => r.id == id ? r.copyWith(scores: scores) : r)
            .toList(),
      );
    } else {
      updated = widget.session.copyWith(
        rounds: [...widget.session.rounds, Round.free(scores: scores)],
      );
    }
    await ref.read(sessionRepositoryProvider).save(updated);
    if (!mounted) return;
    if (context.canPop()) context.pop();
  }

  Future<void> _deleteRound() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete round?',
      body: 'This will recalculate all scores.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final id = widget.existingRound!.id;
    final updated = widget.session.copyWith(
      rounds: widget.session.rounds.where((r) => r.id != id).toList(),
    );
    await ref.read(sessionRepositoryProvider).save(updated);
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    final ok = await ConfirmDialog.show(
      context,
      title: 'Discard changes?',
      body: 'Your edits will not be saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    return ok;
  }

  @override
  Widget build(BuildContext _) {
    final roundNum = _editing
        ? widget.session.rounds
                .indexWhere((r) => r.id == widget.existingRound!.id) +
            1
        : widget.session.rounds.length + 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (!mounted) return;
        if (ok) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit Round $roundNum' : 'New Round'),
          actions: [
            if (_editing)
              IconButton(
                tooltip: 'Delete round',
                icon: const Icon(PhosphorIconsRegular.trash),
                onPressed: _deleteRound,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Spacing.md),
                  children: [
                    Text(
                      'Tap a player to enter their points for this round.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: Spacing.md),
                    for (final p in widget.session.players) ...[
                      _PlayerScoreRow(
                        name: p,
                        value: _scores[p]!,
                        onTap: () => _editPlayer(p),
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                    const SizedBox(height: Spacing.xl),
                  ],
                ),
              ),
              _Footer(
                total: _total,
                canSave: _canSave,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One player's row: avatar, name, and a tappable signed value box.
class _PlayerScoreRow extends StatelessWidget {
  final String name;
  final int value;
  final VoidCallback onTap;

  const _PlayerScoreRow({
    required this.name,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isZero = value == 0;
    final isNeg = value < 0;
    final valueColor = isZero
        ? scheme.onSurfaceVariant
        : isNeg
            ? dangerColor(scheme.brightness)
            : scheme.secondary;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: isZero
                  ? scheme.outlineVariant.withValues(alpha: 0.4)
                  : valueColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: playerColor(name, scheme.brightness),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  playerInitial(name),
                  style: text.labelLarge
                      ?.copyWith(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(name, style: text.titleMedium)),
              Text(
                isZero
                    ? 'Tap to set'
                    : '${isNeg ? '−' : '+'}${value.abs()}',
                style: (isZero ? text.bodyMedium : text.headlineSmall)?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: valueColor,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Icon(PhosphorIconsRegular.pencilSimple,
                  size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int total;
  final bool canSave;
  final VoidCallback onSave;

  const _Footer({
    required this.total,
    required this.canSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Round total', style: text.bodyMedium),
              Text(
                '$total',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton.icon(
            onPressed: canSave ? onSave : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(PhosphorIconsRegular.check),
            label: const Text('Save round'),
          ),
        ],
      ),
    );
  }
}
