import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/round.dart';
import '../../../data/models/session.dart';
import '../../../shared/widgets/round_list_tile.dart';

/// Maps a local [Round] onto the shared [RoundListTile] so the host's round
/// list renders identically to the live viewer's.
class RoundTile extends StatelessWidget {
  final int index;
  final Round round;
  final Session session;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const RoundTile({
    super.key,
    required this.index,
    required this.round,
    required this.session,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final won = round.won;

    // Fine round (stored as a free-score round): one player loses the amount,
    // everyone else 0. Render its own compact summary rather than the bid shape.
    final bool isFine = round.isFree;
    late final String title;
    late final String deltaLabel;
    if (isFine) {
      final offender = round.scores!.entries.firstWhere(
        (e) => e.value < 0,
        orElse: () => const MapEntry('—', 0),
      );
      final amountStr = formatBid(offender.value.abs());
      title = '${offender.key} · Fine';
      deltaLabel = '−$amountStr';
    } else {
      final teamLabel = RoundListTile.summarizeTeam(round.bidder, round.team);
      final bidStr = formatBid(round.bidAmount);
      final resultStr = won ? 'Won' : 'Lost';
      title = '$teamLabel · target $bidStr · $resultStr';
      deltaLabel =
          '${won ? '+' : '−'}$bidStr / ${won ? '−' : '+'}$bidStr';
    }

    return RoundListTile(
      index: index,
      title: title,
      deltaLabel: deltaLabel,
      negative: isFine || !won,
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressHint: onLongPress == null ? null : 'Round options',
    );
  }
}
