import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/live/live_session_writer.dart';
import 'core/live/live_view_history.dart';
import 'data/storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initHive();
  await LiveSessionWriter.instance.init();
  await LiveViewHistory.instance.init();
  // Core (no network) — fast; gives ad config + RTDB a live [DEFAULT] app.
  await FirebaseBootstrap.initCore();
  // Anonymous auth is opt-in and network-bound. Never block app startup on
  // it — the app must open instantly and work fully offline. Kicked off in the
  // background; the Share flow re-invokes init() on demand if it isn't ready.
  unawaited(FirebaseBootstrap.init());
  runApp(const ProviderScope(child: BlackQueenScorerApp()));
}
