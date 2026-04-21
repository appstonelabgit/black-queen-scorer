import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ads/ad_service.dart';
import 'core/live/deep_link_handler.dart';
import 'core/router/app_router.dart';
import 'core/strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class BlackQueenScorerApp extends ConsumerStatefulWidget {
  const BlackQueenScorerApp({super.key});

  @override
  ConsumerState<BlackQueenScorerApp> createState() =>
      _BlackQueenScorerAppState();
}

class _BlackQueenScorerAppState extends ConsumerState<BlackQueenScorerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final router = ref.read(appRouterProvider);
      await DeepLinkHandler.instance.attach(router);
      // Defer ad SDK init by one frame so cold-start paint is snappy.
      await Future.delayed(const Duration(milliseconds: 400));
      await AdService.initialize();
    });
  }

  @override
  void dispose() {
    DeepLinkHandler.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: Strings.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
