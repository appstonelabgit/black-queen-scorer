import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Listens for incoming universal / app links and custom `bqs://` URIs
/// and forwards them to the GoRouter instance. Initialise once from main.
class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> attach(GoRouter router) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _route(router, initial);
      _sub = _appLinks.uriLinkStream.listen(
        (uri) => _route(router, uri),
        onError: (e) => debugPrint('DeepLink error: $e'),
      );
    } catch (e) {
      debugPrint('DeepLink attach failed: $e');
    }
  }

  void _route(GoRouter router, Uri uri) {
    final path = _resolveRoute(uri);
    if (path == null) return;
    router.go(path);
  }

  String? _resolveRoute(Uri uri) {
    // https://appstonelabgit.github.io/black-queen-scorer/l/<code>
    if (uri.host == 'appstonelabgit.github.io') {
      final segs = uri.pathSegments;
      if (segs.length >= 3 &&
          segs[0] == 'black-queen-scorer' &&
          segs[1] == 'l') {
        return '/live/${segs[2]}';
      }
    }
    // bqs://live/<code>
    if (uri.scheme == 'bqs' && uri.host == 'live') {
      final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (code.isNotEmpty) return '/live/$code';
    }
    return null;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
