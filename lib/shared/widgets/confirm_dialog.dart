import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  destructive ? scheme.error : scheme.primary,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> typedDelete(
    BuildContext context, {
    required String title,
    required String body,
    String requiredText = 'DELETE',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TypedDeleteDialog(
        title: title,
        body: body,
        requiredText: requiredText,
      ),
    );
    return result ?? false;
  }
}

/// Owns the [TextEditingController] for its full lifetime so it isn't disposed
/// while the dialog's exit animation is still rebuilding the field.
class _TypedDeleteDialog extends StatefulWidget {
  final String title;
  final String body;
  final String requiredText;
  const _TypedDeleteDialog({
    required this.title,
    required this.body,
    required this.requiredText,
  });

  @override
  State<_TypedDeleteDialog> createState() => _TypedDeleteDialogState();
}

class _TypedDeleteDialogState extends State<_TypedDeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matches = _controller.text == widget.requiredText;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type "${widget.requiredText}" to confirm',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            minimumSize: const Size(80, 40),
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
