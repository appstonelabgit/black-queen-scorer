import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/live/live_session_writer.dart';
import 'data/storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initHive();
  await FirebaseBootstrap.init();
  await LiveSessionWriter.instance.init();
  runApp(const ProviderScope(child: BlackQueenScorerApp()));
}
