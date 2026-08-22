import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Compact per-player record shown beside a name on leaderboards:
/// `C:2 · W:3 · L:1` — calls made (as bidder), rounds won, rounds lost.
/// Renders nothing until the player has any history, so rows stay clean
/// before round 1.
class PlayerRecordLabel extends StatelessWidget {
  final int calls;
  final int wins;
  final int losses;
  const PlayerRecordLabel({
    super.key,
    required this.calls,
    required this.wins,
    required this.losses,
  });

  /// Screen-reader phrasing for the same record, for embedding in a row's
  /// semantics label. Empty when there is nothing to read.
  static String semanticsSuffix(int calls, int wins, int losses) =>
      calls + wins + losses > 0
          ? ', $calls calls, $wins rounds won, $losses lost'
          : '';

  @override
  Widget build(BuildContext context) {
    if (calls + wins + losses == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sep = TextSpan(
      text: ' · ',
      style: TextStyle(color: scheme.onSurfaceVariant),
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: 'C:$calls',
            style: TextStyle(color: scheme.onSurfaceVariant)),
        sep,
        TextSpan(
            text: 'W:$wins',
            style: TextStyle(color: successColor(scheme.brightness))),
        sep,
        TextSpan(
            text: 'L:$losses',
            style: TextStyle(color: dangerColor(scheme.brightness))),
      ]),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: text.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// One-line key explaining the record abbreviations, shown near a
/// leaderboard once records appear. Hidden from screen readers — row
/// semantics already spell the record out in full words.
class PlayerRecordLegend extends StatelessWidget {
  const PlayerRecordLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ExcludeSemantics(
      child: Text(
        'C = Call · W = Win · L = Loss',
        style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Tallies calls / round wins / round losses per player from bid rounds.
/// Every player is on the caller's side or the defending side each round, so
/// W/L accrue for everyone; free-score rounds carry no bid and are skipped.
({Map<String, int> calls, Map<String, int> wins, Map<String, int> losses})
    tallyPlayerRecords({
  required List<String> players,
  required Iterable<({String bidder, List<String> team, bool won})> rounds,
}) {
  final calls = <String, int>{};
  final wins = <String, int>{};
  final losses = <String, int>{};
  for (final r in rounds) {
    if (r.bidder.isEmpty) continue;
    calls[r.bidder] = (calls[r.bidder] ?? 0) + 1;
    final callers = r.team.isEmpty ? [r.bidder] : r.team;
    for (final p in players) {
      if (callers.contains(p) == r.won) {
        wins[p] = (wins[p] ?? 0) + 1;
      } else {
        losses[p] = (losses[p] ?? 0) + 1;
      }
    }
  }
  return (calls: calls, wins: wins, losses: losses);
}
