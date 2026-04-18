import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/round.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'widgets/bid_keypad.dart';
import 'widgets/player_selector.dart';
import 'widgets/result_toggle.dart';

class RoundEntryScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String? roundId;
  const RoundEntryScreen({
    super.key,
    required this.sessionId,
    this.roundId,
  });

  @override
  ConsumerState<RoundEntryScreen> createState() => _RoundEntryScreenState();
}

class _RoundEntryScreenState extends ConsumerState<RoundEntryScreen>
    with TickerProviderStateMixin {
  String? _bidder;
  final Set<String> _teammates = {};
  String _bidStr = '';
  late final AnimationController _shakeBidder;
  late final AnimationController _shakeTeam;
  late final AnimationController _shakeBid;

  bool _initialised = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _shakeBidder = _makeShakeCtrl();
    _shakeTeam = _makeShakeCtrl();
    _shakeBid = _makeShakeCtrl();
  }

  AnimationController _makeShakeCtrl() => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );

  @override
  void dispose() {
    _shakeBidder.dispose();
    _shakeTeam.dispose();
    _shakeBid.dispose();
    super.dispose();
  }

  void _initialiseFromRound(Session session, Round? round) {
    if (_initialised) return;
    if (round != null) {
      _bidder = round.bidder;
      _teammates
        ..clear()
        ..addAll(round.team.where((p) => p != round.bidder));
      _bidStr = round.bidAmount.toString();
    }
    _initialised = true;
  }

  int get _bidValue {
    if (_bidStr.isEmpty) return 0;
    return int.tryParse(_bidStr) ?? 0;
  }

  bool get _canCommit =>
      _bidder != null && _bidValue > 0;

  void _pushDigit(String d) {
    Haptics.selection();
    setState(() {
      if (_bidStr == '0') _bidStr = '';
      final next = (_bidStr + d);
      // Ignore leading zeros and cap at 5 digits.
      if (next.length > 5) return;
      _bidStr = next;
      _dirty = true;
    });
  }

  void _pushDoubleZero() {
    if (_bidStr.isEmpty) return;
    _pushDigit('0');
    _pushDigit('0');
  }

  void _backspace() {
    Haptics.selection();
    setState(() {
      if (_bidStr.isNotEmpty) {
        _bidStr = _bidStr.substring(0, _bidStr.length - 1);
        _dirty = true;
      }
    });
  }

  Future<void> _commit(bool won, Session session) async {
    if (_bidder == null) {
      Haptics.warning();
      _shakeBidder.forward(from: 0);
      return;
    }
    if (_bidValue <= 0) {
      Haptics.warning();
      _shakeBid.forward(from: 0);
      return;
    }
    Haptics.medium();
    final team = <String>[_bidder!, ..._teammates];
    if (widget.roundId == null) {
      final round = Round.create(
        bidder: _bidder!,
        team: team,
        bidAmount: _bidValue,
        won: won,
      );
      final updated = session.copyWith(rounds: [...session.rounds, round]);
      await ref.read(sessionRepositoryProvider).save(updated);
    } else {
      final updatedRounds = session.rounds
          .map((r) => r.id == widget.roundId
              ? r.copyWith(
                  bidder: _bidder,
                  team: team,
                  bidAmount: _bidValue,
                  won: won,
                )
              : r)
          .toList();
      final updated = session.copyWith(rounds: updatedRounds);
      await ref.read(sessionRepositoryProvider).save(updated);
    }
    if (!mounted) return;
    if (context.canPop()) context.pop();
  }

  Future<void> _deleteRound(Session session) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete round?',
      body: 'This will recalculate all scores.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final updated = session.copyWith(
      rounds: session.rounds.where((r) => r.id != widget.roundId).toList(),
    );
    await ref.read(sessionRepositoryProvider).save(updated);
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _onWillPop() async {
    if (widget.roundId == null || !_dirty) return true;
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
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));
    return sessionAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session not found')),
            );
            context.pop();
          });
          return const Scaffold();
        }
        final round = widget.roundId == null
            ? null
            : session.rounds
                .firstWhere(
                  (r) => r.id == widget.roundId,
                  orElse: () => Round(
                    id: '',
                    bidder: '',
                    team: const [],
                    bidAmount: 0,
                    won: false,
                    createdAt: DateTime.now(),
                  ),
                );
        if (widget.roundId != null && round != null && round.id.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Round was deleted')),
            );
            context.pop();
          });
          return const Scaffold();
        }
        _initialiseFromRound(session, round);
        return _buildForm(session, round);
      },
    );
  }

  Widget _buildForm(Session session, Round? existingRound) {
    final editing = existingRound != null;
    final roundNum = editing
        ? session.rounds.indexWhere((r) => r.id == existingRound.id) + 1
        : session.rounds.length + 1;

    final bidNum = int.tryParse(_bidStr) ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (ok && mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(editing ? 'Edit Round $roundNum' : 'New Round'),
          actions: [
            if (editing)
              IconButton(
                tooltip: 'Delete round',
                icon: const Icon(PhosphorIconsRegular.trash),
                onPressed: () => _deleteRound(session),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              _section(
                'Who bid?',
                _shakeBidder,
                PlayerSelector(
                  players: session.players,
                  multiSelect: false,
                  selected: _bidder == null ? {} : {_bidder!},
                  onToggle: (p) {
                    setState(() {
                      if (_bidder == p) {
                        _bidder = null;
                      } else {
                        _bidder = p;
                        _teammates.remove(p);
                      }
                      _dirty = true;
                    });
                  },
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _section(
                'Who\'s with the bidder?',
                _shakeTeam,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bidder == null
                          ? Strings.pickBidderFirst
                          : 'Tap to add teammates. The bidder is always on the team.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    PlayerSelector(
                      players: session.players,
                      multiSelect: true,
                      selected: _teammates,
                      excludeName: _bidder,
                      enabled: _bidder != null,
                      onToggle: (p) {
                        setState(() {
                          if (_teammates.contains(p)) {
                            _teammates.remove(p);
                          } else {
                            _teammates.add(p);
                          }
                          _dirty = true;
                        });
                      },
                    ),
                    const SizedBox(height: Spacing.sm),
                    if (_bidder != null) _teamSplitLine(session),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _section(
                'Bid amount',
                _shakeBid,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: Spacing.md),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color: _bidStr.isEmpty
                              ? Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.4)
                              : Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _bidStr.isEmpty ? '0' : formatBid(bidNum),
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              fontWeight: FontWeight.w800,
                              color: _bidStr.isEmpty
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context)
                                      .colorScheme
                                      .secondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    BidKeypad(
                      onDigit: _pushDigit,
                      onDoubleZero: _pushDoubleZero,
                      onBackspace: _backspace,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Text('Result',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    _canCommit
                        ? 'Tap to save the round'
                        : 'Fill the fields above',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _canCommit
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              ResultToggle(
                enabled: _canCommit,
                onPick: (won) => _commit(won, session),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, AnimationController shake, Widget child) {
    return AnimatedBuilder(
      animation: shake,
      builder: (context, c) {
        final t = shake.value;
        final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 4) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _teamSplitLine(Session s) {
    final team = [s.players.firstWhere((p) => p == _bidder)];
    team.addAll(_teammates);
    final opp = s.players.where((p) => !team.contains(p)).toList();
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final teamBg = scheme.primary.withValues(alpha: 0.14);
    final teamBorder = scheme.primary.withValues(alpha: 0.35);
    final oppBg = brightness == Brightness.light
        ? const Color(0xFFC62828).withValues(alpha: 0.12)
        : const Color(0xFFEF5350).withValues(alpha: 0.14);
    final oppBorder = brightness == Brightness.light
        ? const Color(0xFFC62828).withValues(alpha: 0.30)
        : const Color(0xFFEF5350).withValues(alpha: 0.30);
    final text = Theme.of(context).textTheme;
    Widget pill(String label, int count, String list, Color bg, Color border) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + 2, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label · $count',
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  letterSpacing: 0.2,
                )),
            const SizedBox(height: 2),
            Text(list,
                style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: pill(Strings.teamLabel, team.length,
              team.join(', '), teamBg, teamBorder),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: pill(Strings.oppositionLabel, opp.length,
              opp.isEmpty ? '—' : opp.join(', '), oppBg, oppBorder),
        ),
      ],
    );
  }
}
