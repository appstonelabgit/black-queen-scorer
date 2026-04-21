import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/round.dart';
import '../../data/models/session.dart';
import '../../data/scoring.dart';
import '../firebase/firebase_bootstrap.dart';
import 'live_code.dart';

/// Maps local session ids to their stable live share code. Stored in Hive
/// so that after a restart the same session keeps the same shareable URL.
const _codeBoxName = 'live_session_codes';

class LiveSessionWriter {
  static LiveSessionWriter? _instance;
  static LiveSessionWriter get instance => _instance ??= LiveSessionWriter._();
  LiveSessionWriter._();

  Box<String>? _codes;

  Future<void> init() async {
    _codes = await Hive.openBox<String>(_codeBoxName);
  }

  String? codeFor(String sessionId) => _codes?.get(sessionId);

  /// Returns an existing code for [sessionId] or creates a new one.
  /// No-op (returns null) if Firebase never came up.
  Future<String?> ensureCode(String sessionId) async {
    if (!FirebaseBootstrap.initialized) return null;
    final existing = _codes?.get(sessionId);
    if (existing != null) return existing;
    final code = generateLiveCode();
    await _codes?.put(sessionId, code);
    return code;
  }

  /// Pushes the current snapshot of [session] to RTDB. Safe to call on
  /// every round change — it's a single overwrite on a small payload.
  Future<void> sync(Session session) async {
    if (!FirebaseBootstrap.initialized) return;
    final code = await ensureCode(session.id);
    if (code == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final scores = computeScores(session);
    final roundsJson =
        session.rounds.map((r) => _roundToLiveJson(r, session)).toList();

    final payload = <String, dynamic>{
      'creatorUid': FirebaseBootstrap.uid,
      'createdAt': session.startedAt.millisecondsSinceEpoch,
      'updatedAt': now,
      'finishedAt': session.finishedAt?.millisecondsSinceEpoch,
      'players': session.players,
      'bonus': session.settings.effectiveBonus,
      'rounds': roundsJson,
      'scores': scores,
    };

    try {
      await FirebaseDatabase.instance.ref('live_sessions/$code').set(payload);
    } catch (e) {
      // Offline or permission failure — tolerate and retry on next change.
      debugPrint('LiveSessionWriter.sync failed: $e');
    }
  }

  Map<String, dynamic> _roundToLiveJson(Round r, Session s) {
    final delta = computeRoundDelta(r, s);
    return {
      'bidder': r.bidder,
      'bidTeam': r.team,
      'bid': r.bidAmount,
      'won': r.won,
      'delta': delta,
    };
  }
}
