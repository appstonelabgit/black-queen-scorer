import 'dart:async';

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
      'mode': session.settings.mode.name,
      'rounds': roundsJson,
      'scores': scores,
    };

    try {
      await FirebaseBootstrap.db.ref('live_sessions/$code').set(payload);
    } catch (e) {
      // Offline or permission failure — tolerate and retry on next change.
      debugPrint('LiveSessionWriter.sync failed: $e');
    }
  }

  /// Broadcasts an in-progress round (caller + bid chosen, result pending) so
  /// watchers see a "Current round" card before it's committed. No-op if the
  /// session was never shared — it does NOT create a code (only an already-live
  /// game announces its current hand).
  Future<void> syncCurrentRound(
    String sessionId, {
    required String bidder,
    required int bid,
    required List<String> team,
  }) async {
    if (!FirebaseBootstrap.initialized) return;
    final code = _codes?.get(sessionId);
    if (code == null) return;
    try {
      await FirebaseBootstrap.db.ref('live_sessions/$code').update({
        'currentRound': {
          'bidder': bidder,
          'bid': bid,
          'bidTeam': team,
        },
      });
    } catch (e) {
      debugPrint('LiveSessionWriter.syncCurrentRound failed: $e');
    }
  }

  /// Clears any in-progress round from the live record (scorer backed out of a
  /// new round without committing). Committing instead overwrites the whole
  /// node via [sync], which drops `currentRound` on its own. No-op if unshared.
  Future<void> clearCurrentRound(String sessionId) async {
    if (!FirebaseBootstrap.initialized) return;
    final code = _codes?.get(sessionId);
    if (code == null) return;
    try {
      await FirebaseBootstrap.db
          .ref('live_sessions/$code/currentRound')
          .remove();
    } catch (e) {
      debugPrint('LiveSessionWriter.clearCurrentRound failed: $e');
    }
  }

  /// Stamps `finishedAt` on a shared session's live record so watchers stop
  /// seeing it as "Live" once the host discards/deletes it without finishing.
  /// No-op if the session was never shared.
  Future<void> markEnded(String sessionId) async {
    if (!FirebaseBootstrap.initialized) return;
    final code = _codes?.get(sessionId);
    if (code == null) return;
    try {
      await FirebaseBootstrap.db.ref('live_sessions/$code').update({
        'finishedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('LiveSessionWriter.markEnded failed: $e');
    }
  }

  Map<String, dynamic> _roundToLiveJson(Round r, Session s) {
    final delta = computeRoundDelta(r, s);
    // Free-score round: no caller/bid concept — emit the entered points map and
    // the delta. Bid rounds keep their exact original JSON shape (below).
    if (r.isFree) {
      return {
        'scores': r.scores,
        'delta': delta,
      };
    }
    return {
      'bidder': r.bidder,
      'bidTeam': r.team,
      'bid': r.bidAmount,
      'won': r.won,
      'delta': delta,
    };
  }
}
