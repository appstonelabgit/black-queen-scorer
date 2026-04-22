import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

enum ToastStyle { neutral, success, error }

/// Branded top-of-screen toast. Replaces SnackBar where the message is a
/// short confirmation or error. Designed to match the app's emerald/gold
/// surface cards and slide in from above the status bar.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static _ToastKey? _key;

  /// Shows a toast. If one is already visible it is replaced immediately.
  /// Returns a handle the caller can use to dismiss the toast early
  /// (needed for undo flows that tie toast lifetime to a user action).
  static AppToastHandle show(
    BuildContext context,
    String message, {
    ToastStyle style = ToastStyle.neutral,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _dismissInternal();

    final overlay = Overlay.of(context, rootOverlay: true);
    final key = _ToastKey();
    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        key: key,
        message: message,
        style: style,
        icon: icon,
        actionLabel: actionLabel,
        onAction: () {
          onAction?.call();
          dismiss();
        },
      ),
    );
    overlay.insert(entry);
    _entry = entry;
    _key = key;

    _timer = Timer(duration, dismiss);
    return AppToastHandle._(entry);
  }

  static void dismiss() {
    _key?.currentState?.animateOut().then((_) => _dismissInternal());
  }

  static void _dismissInternal() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    _key = null;
  }
}

class AppToastHandle {
  final OverlayEntry _entry;
  AppToastHandle._(this._entry);

  void dismiss() {
    if (AppToast._entry == _entry) AppToast.dismiss();
  }
}

class _ToastKey extends GlobalKey<_ToastViewState> {
  const _ToastKey() : super.constructor();
}

class _ToastView extends StatefulWidget {
  final String message;
  final ToastStyle style;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastView({
    super.key,
    required this.message,
    required this.style,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.base,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> animateOut() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Color accent;
    IconData defaultIcon;
    switch (widget.style) {
      case ToastStyle.success:
        accent = scheme.primary;
        defaultIcon = PhosphorIconsFill.checkCircle;
        break;
      case ToastStyle.error:
        accent = scheme.error;
        defaultIcon = PhosphorIconsFill.warningCircle;
        break;
      case ToastStyle.neutral:
        accent = scheme.secondary;
        defaultIcon = PhosphorIconsFill.info;
        break;
    }

    return Positioned(
      top: mq.padding.top + Spacing.sm,
      left: Spacing.md,
      right: Spacing.md,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: AppToast.dismiss,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md, vertical: Spacing.sm + 2),
                child: Row(
                  children: [
                    Icon(widget.icon ?? defaultIcon, color: accent, size: 20),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: Spacing.sm),
                      TextButton(
                        onPressed: widget.onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
