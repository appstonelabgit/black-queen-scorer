// Hand-written equivalent of what `flutterfire configure` would generate.
// Values taken from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist.
//
// This file is committed — Firebase config keys here are not secrets.
// Security is enforced by Realtime Database rules + App Check (optional).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not configured for $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAB7p5qPsg4shNbrvopRob8Jad2xuUWMQ',
    appId: '1:908672463707:android:6cb0a9aa12b2f93346e07e',
    messagingSenderId: '908672463707',
    projectId: 'black-queen-scorer',
    databaseURL:
        'https://black-queen-scorer-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'black-queen-scorer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAj5c_5oKrtYC1p-G75HnJAgYvhpbpQ7fo',
    appId: '1:908672463707:ios:1d61eeccc8622f8146e07e',
    messagingSenderId: '908672463707',
    projectId: 'black-queen-scorer',
    databaseURL:
        'https://black-queen-scorer-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'black-queen-scorer.firebasestorage.app',
    iosBundleId: 'com.blackqueenscorer.app',
  );
}
