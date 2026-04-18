import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../session_setup/widgets/player_chip.dart' show playerColor;

class PlayerRow extends StatefulWidget {
  final int rank;
  final String name;
  final int score;
  final VoidCallback? onTap;
  final int? pulseDelta;

  const PlayerRow({
    super.key,
    required this.rank,
    required this.name,
    required this.score,
    this.onTap,
    this.pulseDelta,
  });

  @override
  State<PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<PlayerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant PlayerRow old) {
    super.didUpdateWidget(old);
    if (widget.pulseDelta != null &&
        widget.pulseDelta != 0 &&
        widget.score != old.score) {
      final disableAnim = MediaQuery.of(context).disableAnimations;
      if (!disableAnim) {
        _ctrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final avatar = playerColor(widget.name, brightness);
    final isGold = widget.rank == 1;
    final pulseColor = (widget.pulseDelta ?? 0) > 0
        ? (brightness == Brightness.light
            ? const Color(0xFF2E7D32)
            : const Color(0xFF66BB6A))
        : (brightness == Brightness.light
            ? const Color(0xFFC62828)
            : const Color(0xFFEF5350));

    Color baseColor() {
      if (widget.score == 0) return scheme.onSurfaceVariant;
      if (widget.score > 0) {
        return brightness == Brightness.light
            ? const Color(0xFF2E7D32)
            : const Color(0xFF66BB6A);
      }
      return brightness == Brightness.light
          ? const Color(0xFFC62828)
          : const Color(0xFFEF5350);
    }

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm + 2),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: isGold
                    ? Icon(PhosphorIconsFill.trophy,
                        color: scheme.secondary, size: 22)
                    : Text('${widget.rank}',
                        style: text.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant)),
              ),
              const SizedBox(width: Spacing.sm),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: avatar, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  playerInitial(widget.name),
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(widget.name,
                    style: text.bodyLarge, overflow: TextOverflow.ellipsis),
              ),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _ctrl.value;
                  final strength = t < 1 / 3 ? t * 3 : (1 - t) * 1.5;
                  final color = Color.lerp(
                          baseColor(), pulseColor, strength.clamp(0, 1))!;
                  return Text(
                    formatScore(widget.score),
                    style: text.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
