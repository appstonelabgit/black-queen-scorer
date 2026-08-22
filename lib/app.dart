import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'core/ads/ad_service.dart';
import 'core/live/deep_link_handler.dart';
import 'core/router/app_router.dart';
import 'core/strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class ScoreWiseApp extends ConsumerStatefulWidget {
  const ScoreWiseApp({super.key});

  @override
  ConsumerState<ScoreWiseApp> createState() => _ScoreWiseAppState();
}

class _ScoreWiseAppState extends ConsumerState<ScoreWiseApp> {
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
