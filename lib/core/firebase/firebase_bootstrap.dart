import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Our Realtime Database lives in asia-southeast1, not the Firebase SDK
/// default (us-central1). Every FirebaseDatabase reference must pass this
/// URL explicitly — the options-level databaseURL is ignored by some
/// versions of the Flutter SDK.
const _rtdbUrl =
    'https://black-queen-scorer-default-rtdb.asia-southeast1.firebasedatabase.app';

class FirebaseBootstrap {
  static bool _coreReady = false;
  static bool _initialized = false;
  static String? _uid;
  static Object? _lastError;

  static String? get uid => _uid;
  static bool get initialized => _initialized;
  static Object? get lastError => _lastError;

  /// Region-aware RTDB handle. Use this everywhere instead of
  /// `FirebaseDatabase.instance`.
  static FirebaseDatabase get db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _rtdbUrl,
      );

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
        db.setPersistenceEnabled(true);
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
