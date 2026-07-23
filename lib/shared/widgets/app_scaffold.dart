import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final Color? background;
  final bool safeArea;
  final EdgeInsetsGeometry padding;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomBar,
    this.floatingActionButton,
    this.background,
    this.safeArea = true,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: body);
    return Scaffold(
      backgroundColor: background,
      appBar: appBar,
      body: safeArea ? SafeArea(child: content) : content,
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
