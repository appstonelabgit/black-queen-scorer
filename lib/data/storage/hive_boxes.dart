import 'package:hive_flutter/hive_flutter.dart';

import '../models/adapters.dart';
import '../models/session.dart';

class HiveBoxes {
  static const sessions = 'sessions';
  static const recentPlayers = 'recent_players';
  static const settings = 'settings';
}

Future<void> initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(RoundAdapter());
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(SessionSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SessionAdapter());

  await Future.wait([
    Hive.openBox<Session>(HiveBoxes.sessions),
    Hive.openBox(HiveBoxes.recentPlayers),
    Hive.openBox(HiveBoxes.settings),
  ]);
}
