import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  static bool _coreReady = false;
  static bool _initialized = false;
  static String? _uid;
  static Object? _lastError;

  static String? get uid => _uid;
  static bool get initialized => _initialized;
  static Object? get lastError => _lastError;

  /// Safe to call multiple times. Retries anonymous auth on each call if
  /// it previously failed, which is how the Scoreboard's "Share live" flow
  /// recovers from a cold-start auth flake (common on iOS simulator's
  /// keychain).
  static Future<bool> init() async {
    if (_initialized) return true;
    try {
      if (!_coreReady) {
        // Firebase may have already been initialized by a native call or
        // a previous hot-reload — in either case skip the explicit init.
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        _coreReady = true;
      }
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user?.uid;
      _initialized = true;
      _lastError = null;
      return true;
    } catch (e, st) {
      _lastError = e;
      debugPrint('Firebase init failed: $e\n$st');
      return false;
    }
  }
}
