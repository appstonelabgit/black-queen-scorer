import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/live/live_code.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/shell_back_button.dart';

/// Input formatter: uppercase, drop invalid characters, auto-insert the
/// dash after the 4th alphanumeric, cap at 8 alphanumerics.
class _LiveCodeFormatter extends TextInputFormatter {
  const _LiveCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .characters
        .take(8)
        .join();
    final formatted = cleaned.length <= 4
        ? cleaned
        : '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Lets a viewer type (or paste) a live-session code to jump into the
/// viewer. QR scanning is a separate entry on the home screen.
class WatchLiveScreen extends StatefulWidget {
  const WatchLiveScreen({super.key});

  @override
  State<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends State<WatchLiveScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go() {
    final code = normalizeLiveCode(_controller.text);
    if (!isValidLiveCode(code)) {
      setState(() => _error =
          'Codes look like ABCD-EFGH. Check what was shared with you.');
      return;
    }
    context.go('/live/$code');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const ShellBackButton(),
        title: const Text('Watch live'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.lg),
              Icon(PhosphorIconsFill.broadcast,
                  size: 56, color: scheme.primary),
              const SizedBox(height: Spacing.md),
              Text(
                'Enter the code',
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Anyone hosting a session can share a code that looks like ABCD-EFGH.',
                textAlign: TextAlign.center,
                style:
                    text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: Spacing.xl),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 9,
                style: text.headlineMedium?.copyWith(letterSpacing: 6),
                inputFormatters: const [_LiveCodeFormatter()],
                decoration: InputDecoration(
                  hintText: 'ABCD-EFGH',
                  counterText: '',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _go(),
              ),
              const SizedBox(height: Spacing.md),
              FilledButton.icon(
                onPressed: _go,
                icon: const Icon(PhosphorIconsRegular.arrowRight, size: 18),
                label: const Text('Watch live'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
