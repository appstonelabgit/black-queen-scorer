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
    apiKey: 'AIzaSyBlOFigB2sd6A9XquYbhYbEhoW3Z2jy5_E',
    appId: '1:497076648805:android:c3bc6d726cf3690e42ff8c',
    messagingSenderId: '497076648805',
    projectId: 'scorewise-9a7f6',
    databaseURL:
        'https://scorewise-9a7f6-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'scorewise-9a7f6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBR0FLpW_GFjPaE0kpkWOfr39rdfYFgIHI',
    appId: '1:497076648805:ios:f6862a03f047300642ff8c',
    messagingSenderId: '497076648805',
    projectId: 'scorewise-9a7f6',
    databaseURL:
        'https://scorewise-9a7f6-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'scorewise-9a7f6.firebasestorage.app',
    iosBundleId: 'com.blackqueenscorer.app',
  );
}
