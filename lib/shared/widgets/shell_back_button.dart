import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// AppBar back button for screens that live inside the shell route and
/// were opened directly from Home. Pops normally if there's a predecessor,
/// otherwise goes home.
class ShellBackButton extends StatelessWidget {
  const ShellBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(PhosphorIconsRegular.caretLeft),
      tooltip: 'Back',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    );
  }
}
