// GENERATED-STYLE PLACEHOLDER.
//
// Replace this file by running:  flutterfire configure
// (https://firebase.flutter.dev/docs/cli). The placeholder values let the
// project COMPILE, but Firebase.initializeApp() will fail at runtime until you
// drop in your real project's configuration.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'doorbell-REPLACE',
    authDomain: 'doorbell-REPLACE.firebaseapp.com',
    storageBucket: 'doorbell-REPLACE.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMio9rBWrzXmPlVyPN6gRp22es6KorFLQ',
    appId: '1:817903627471:android:2a58fb26c4fcd36a195bba',
    messagingSenderId: '817903627471',
    projectId: 'firstapp-a519e',
    storageBucket: 'firstapp-a519e.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJZkoO8YkHJu1AYFBZr-Hqh5J0mwe-A8U',
    appId: '1:817903627471:ios:70962fc03aa824b6195bba',
    messagingSenderId: '817903627471',
    projectId: 'firstapp-a519e',
    storageBucket: 'firstapp-a519e.firebasestorage.app',
    iosBundleId: 'com.doorbell.doorbell',
  );
}
