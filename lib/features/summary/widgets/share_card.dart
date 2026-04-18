import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/session.dart';
import '../../../data/scoring.dart';
import '../../session_setup/widgets/player_chip.dart';

class ShareCard extends StatelessWidget {
  final Session session;
  final SessionStats stats;

  const ShareCard({super.key, required this.session, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Fixed size for screenshot: 1080x1350.
    return Material(
      color: const Color(0xFF0A1F1A),
      child: SizedBox(
        width: 1080,
        height: 1350,
        child: Stack(
          children: [
            // Background gradient.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F5132),
                    Color(0xFF0A1F1A),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A017),
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'B',
                          style: TextStyle(
                            color: Color(0xFF0A1F1A),
                            fontWeight: FontWeight.w900,
                            fontSize: 44,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          Strings.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    DateFormat.yMMMd().format(session.startedAt),
                    style: const TextStyle(
                      color: Color(0xFFE8B931),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${session.players.length} players · ${stats.totalRounds} rounds · ${formatDuration(stats.totalDuration)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.ranked.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final p = stats.ranked[i];
                        final isTop = i == 0;
                        return Container(
                          decoration: BoxDecoration(
                            color: isTop
                                ? const Color(0xFFD4A017).withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 22),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isTop
                                        ? const Color(0xFFE8B931)
                                        : Colors.white70,
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
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}
