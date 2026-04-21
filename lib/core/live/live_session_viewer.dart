import 'package:firebase_database/firebase_database.dart';

import 'live_models.dart';

/// Subscribes to a live session at `/live_sessions/{code}` and emits a new
/// [LiveSessionState] whenever the host writes. Returns null when the code
/// doesn't exist (either never registered or was deleted post-finish).
class LiveSessionViewer {
  static Stream<LiveSessionState?> watch(String code) {
    final ref = FirebaseDatabase.instance.ref('live_sessions/$code');
    return ref.onValue.map((event) {
      final v = event.snapshot.value;
      if (v == null) return null;
      return LiveSessionState.fromJson(
          code, Map<dynamic, dynamic>.from(v as Map));
    });
  }
}
