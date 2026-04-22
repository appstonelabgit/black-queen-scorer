import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/session.dart';
import '../../data/models/session_settings.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/shell_back_button.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/bonus_toggle.dart';
import 'widgets/player_chip.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() =>
      _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  final _selected = <String>[];
  final _available = <String>[];
  final _newPlayerCtrl = TextEditingController();
  final _newPlayerFocus = FocusNode();
  bool _bonusEnabled = false;
  int _bonusAmount = 100;
  bool _guideOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recent = ref.read(recentPlayersProvider);
      setState(() => _available.addAll(recent));
    });
  }

  @override
  void dispose() {
    _newPlayerCtrl.dispose();
    _newPlayerFocus.dispose();
    super.dispose();
  }

  bool get _canStart => _selected.length >= 4 && _selected.length <= 12;

  void _toggle(String name) {
    setState(() {
      final lower = name.toLowerCase();
      final existing = _selected.indexWhere((p) => p.toLowerCase() == lower);
      if (existing >= 0) {
        _selected.removeAt(existing);
      } else {
        if (_selected.length >= 12) return;
        _selected.add(name);
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final name = _selected.removeAt(oldIndex);
      _selected.insert(newIndex, name);
    });
  }

  void _addNew() {
    final raw = _newPlayerCtrl.text.trim();
    if (raw.isEmpty) return;
    final lower = raw.toLowerCase();
    final alreadySelected =
        _selected.any((p) => p.toLowerCase() == lower);
    if (alreadySelected) {
      AppToast.show(
        context,
        Strings.alreadyAdded,
        style: ToastStyle.error,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    setState(() {
      if (!_available.any((p) => p.toLowerCase() == lower)) {
        _available.insert(0, raw);
      }
      if (_selected.length < 12) _selected.add(raw);
      _newPlayerCtrl.clear();
    });
    _newPlayerFocus.requestFocus();
  }

  Future<void> _start() async {
    if (!_canStart) return;
    Haptics.medium();
    final session = Session.create(
      players: List.of(_selected),
      settings: SessionSettings(
        bonusEnabled: _bonusEnabled,
        bonusAmount: _bonusAmount,
      ),
    );
    await ref.read(sessionRepositoryProvider).save(session);
    if (!mounted) return;
    context.go('/session/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: const Text('New Session'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
                children: [
                  _PlayersSection(
                    available: _available,
                    selected: _selected,
                    onToggle: _toggle,
                    controller: _newPlayerCtrl,
                    focusNode: _newPlayerFocus,
                    onSubmitNew: _addNew,
                  ),
                  if (_selected.length >= 2) ...[
                    const SizedBox(height: Spacing.md),
                    _SeatingSection(
                      selected: _selected,
                      onReorder: _reorder,
                      onRemove: _toggle,
                    ),
                  ],
                  const SizedBox(height: Spacing.md),
                  _BonusSection(
                    enabled: _bonusEnabled,
                    amount: _bonusAmount,
                    onEnabledChanged: (v) =>
                        setState(() => _bonusEnabled = v),
                    onAmountChanged: (v) =>
                        setState(() => _bonusAmount = v),
                  ),
                  const SizedBox(height: Spacing.md),
                  _QuickGuide(
                    open: _guideOpen,
                    onToggle: () =>
                        setState(() => _guideOpen = !_guideOpen),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
              ),
            ),
            _Footer(
              count: _selected.length,
              canStart: _canStart,
              onStart: _start,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared card shell for the three setup sections.
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({
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

class _SeatingSection extends StatelessWidget {
  final List<String> selected;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String name) onRemove;

  const _SeatingSection({
    required this.selected,
    required this.onReorder,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return _Section(
      icon: PhosphorIconsRegular.listNumbers,
      title: 'Seating order',
      subtitle:
          'Drag to match real-life seating. Makes picking teammates faster.',
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: selected.length,
        onReorder: onReorder,
        proxyDecorator: (child, _, __) => Material(
          color: Colors.transparent,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Radii.md),
          child: child,
        ),
        itemBuilder: (context, i) {
          final name = selected[i];
          return Padding(
            key: ValueKey(name),
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm, vertical: Spacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}',
                      style: text.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(name, style: text.titleMedium),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => onRemove(name),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: Icon(
                        PhosphorIconsRegular.dotsSixVertical,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayersSection extends StatelessWidget {
  final List<String> available;
  final List<String> selected;
  final void Function(String) onToggle;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitNew;

  const _PlayersSection({
    required this.available,
    required this.selected,
    required this.onToggle,
    required this.controller,
    required this.focusNode,
    required this.onSubmitNew,
  });

  @override
  Widget build(BuildContext context) {
    final byName = <String, String>{};
    for (final p in available) {
      byName[p.toLowerCase()] = p;
    }
    for (final p in selected) {
      byName.putIfAbsent(p.toLowerCase(), () => p);
    }
    final ordered = byName.values.toList();

    return _Section(
      icon: PhosphorIconsRegular.users,
      title: 'Players',
      subtitle: available.isEmpty
          ? 'Add 4–12 players to start.'
          : 'Tap to add. New names stay for next time.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ordered.isNotEmpty)
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final p in ordered)
                  PlayerChip(
                    name: p,
                    selected:
                        selected.any((s) => s.toLowerCase() == p.toLowerCase()),
                    onTap: () => onToggle(p),
                  ),
              ],
            ),
          if (ordered.isNotEmpty) const SizedBox(height: Spacing.md),
          TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: Strings.addNewPlayer,
              prefixIcon:
                  const Icon(PhosphorIconsRegular.userPlus, size: 18),
              suffixIcon: IconButton(
                tooltip: 'Add',
                icon: const Icon(PhosphorIconsRegular.plus),
                onPressed: onSubmitNew,
              ),
            ),
            onSubmitted: (_) => onSubmitNew(),
          ),
        ],
      ),
    );
  }
}

class _BonusSection extends StatelessWidget {
  final bool enabled;
  final int amount;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onAmountChanged;

  const _BonusSection({
    required this.enabled,
    required this.amount,
    required this.onEnabledChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: PhosphorIconsRegular.coins,
      title: 'Bonus for bidder',
      subtitle: Strings.bonusHelper,
      child: BonusToggle(
        enabled: enabled,
        amount: amount,
        onEnabledChanged: onEnabledChanged,
        onAmountChanged: onAmountChanged,
      ),
    );
  }
}

class _QuickGuide extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  const _QuickGuide({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md, vertical: Spacing.md),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.info,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                      child: Text(Strings.howScoringWorks,
                          style: text.titleMedium)),
                  AnimatedRotation(
                    duration: AppDurations.fast,
                    turns: open ? 0.5 : 0,
                    child: Icon(PhosphorIconsRegular.caretDown,
                        size: 18, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.base,
            curve: Curves.easeOutCubic,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.md, 0, Spacing.md, Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'On a win: bidder\'s team gets +bid. Opposition gets −bid. The bidder also gets +bonus (if enabled).\n\nOn a loss: reverse the signs.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.all(Spacing.sm),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(Radii.sm),
                            border: Border.all(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Bid 700, bonus 100\n'
                            'Team = A, B   Opp = C, D, E   Result: Won\n'
                            'A: +800    B: +700    C/D/E: −700',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int count;
  final bool canStart;
  final VoidCallback onStart;
  const _Footer({
    required this.count,
    required this.canStart,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hint = count < 4
        ? 'Pick at least ${4 - count} more'
        : count > 12
            ? 'Max 12 players'
            : 'Ready to start';

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
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Text(
                  '$count player${count == 1 ? '' : 's'} selected',
                  key: ValueKey('count-$count'),
                  style: text.bodyMedium,
                ),
              ),
              Text(
                hint,
                style: text.bodySmall?.copyWith(
                  color: canStart ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          AppButton(
            label: Strings.startSession,
            icon: PhosphorIconsRegular.playCircle,
            height: 56,
            onPressed: canStart ? onStart : null,
          ),
        ],
      ),
    );
  }
}
