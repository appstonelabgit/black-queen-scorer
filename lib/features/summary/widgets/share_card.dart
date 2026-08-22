import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/session.dart';
import '../../../data/scoring.dart';
import '../../session_setup/widgets/player_chip.dart';

/// The 1080x1350 image rendered off-screen when the user taps Share on the
/// summary. Mirrors the in-app summary's hierarchy — crest, winner banner,
/// final rankings — in the ScoreWise indigo/gold brand, on a fixed dark
/// palette independent of the app theme so the shared image always looks
/// the same.
class ShareCard extends StatelessWidget {
  final Session session;
  final SessionStats stats;

  const ShareCard({super.key, required this.session, required this.stats});

  static const _bgTop = Color(0xFF2A2452);
  static const _bgBottom = Color(0xFF14112B);
  static const _gold = AppColors.accentDark;
  static const _indigo = AppColors.primaryDark;

  @override
  Widget build(BuildContext context) {
    final ranked = stats.ranked;
    final tie = ranked.length >= 2 && ranked[0].score == ranked[1].score;
    return Material(
      color: _bgBottom,
      child: SizedBox(
        width: 1080,
        height: 1350,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 36),
                Text(
                  DateFormat.yMMMd().format(session.startedAt),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${plural(session.players.length, 'player')} · ${plural(stats.totalRounds, 'round')} · ${formatDuration(stats.totalDuration)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 22),
                ),
                if (ranked.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _winnerBanner(ranked.first, tie),
                ],
                const SizedBox(height: 32),
                Expanded(child: _rankings(ranked)),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    Strings.sharedFooter,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Crest + wordmark, matching Home's _Brand: gold crown over a spade on an
  /// indigo tile, "Score" white / "Wise" gold.
  Widget _header() {
    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_indigo, _indigo.withValues(alpha: 0.6)],
            ),
            border: Border.all(
              color: _gold.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                PhosphorIconsFill.spade,
                size: 46,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              const Icon(PhosphorIconsFill.crown, size: 23, color: _gold),
            ],
          ),
        ),
        const SizedBox(width: 22),
        const Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                    text: 'Score', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'Wise', style: TextStyle(color: _gold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _winnerBanner(PlayerScore winner, bool tie) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gold.withValues(alpha: 0.22),
            _gold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            tie ? PhosphorIconsFill.handshake : PhosphorIconsFill.trophy,
            size: 44,
            color: _gold,
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tie ? 'It\'s a tie!' : '${winner.name} wins!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${tie ? 'Top' : 'Final'} score ${formatScore(winner.score)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankings(List<PlayerScore> ranked) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ranked.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = ranked[i];
        final isTop = i == 0;
        return Container(
          decoration: BoxDecoration(
            color: isTop
                ? _gold.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: isTop ? _gold : Colors.white70,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: playerColor(p.name, Brightness.dark),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  playerInitial(p.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatScore(p.score),
                style: TextStyle(
                  color: p.score > 0
                      ? const Color(0xFF66BB6A)
                      : p.score < 0
                          ? const Color(0xFFEF5350)
                          : Colors.white70,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
