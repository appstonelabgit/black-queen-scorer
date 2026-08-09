import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Our Realtime Database is region-scoped (both platforms → scorewise-9a7f6 in
/// europe-west1), so every FirebaseDatabase reference must pass the URL
/// explicitly — the options-level databaseURL is ignored by some versions of
/// the Flutter SDK. Source it from the per-platform [FirebaseOptions] so it
/// always matches the initialized app.
String get _rtdbUrl => DefaultFirebaseOptions.currentPlatform.databaseURL!;

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
  /// Initializes only the Firebase core app + RTDB persistence — no network
  /// auth. Fast and safe to await at startup so anything that needs a
  /// [FirebaseDatabase] handle (e.g. ad config) has a live `[DEFAULT]` app.
  /// Does NOT sign in; live-share features still require [init].
  static Future<void> initCore() async {
    if (_coreReady) return;
    // Firebase may have already been initialized by iOS native auto-init
    // (GoogleService-Info.plist) or a previous hot restart. Checking
    // `Firebase.apps.isEmpty` is racy against native init, so just attempt
    // the explicit init and treat a duplicate as success.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      // [DEFAULT] already exists — reuse it.
    }
    // Persistence can only be set once; a second call (e.g. hot restart)
    // throws and is safe to ignore.
    try {
      db.setPersistenceEnabled(true);
    } catch (_) {}
    _coreReady = true;
  }

  static Future<bool> init() async {
    if (_initialized) return true;
    try {
      await initCore();
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
