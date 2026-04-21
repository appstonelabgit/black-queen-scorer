import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static String? _uid;

  static String? get uid => _uid;
  static bool get initialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user?.uid;
      _initialized = true;
    } catch (e, st) {
      // Offline or Firebase failure must never break the core app.
      debugPrint('Firebase init failed: $e\n$st');
    }
  }
}
