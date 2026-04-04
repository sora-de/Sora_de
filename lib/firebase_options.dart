// Generated for project `sora-de` by FlutterFire CLI.
// To refresh: `dart pub global activate flutterfire_cli` then `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBRfN4r3wEBDLtarFiD51_TrEURE47Q2x8',
    appId: '1:442780655388:web:4e900c8082acb4d42764d9',
    messagingSenderId: '442780655388',
    projectId: 'sora-de',
    authDomain: 'sora-de.firebaseapp.com',
    storageBucket: 'sora-de.firebasestorage.app',
    measurementId: 'G-VSJ10EGKCD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZz14KnZCS8IqmaS8caD2gVaCI4YW382g',
    appId: '1:442780655388:android:348cd1d924da32b22764d9',
    messagingSenderId: '442780655388',
    projectId: 'sora-de',
    storageBucket: 'sora-de.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDPTa9dmPNlTZhdT-MyxUJDumDpobwRm6Y',
    appId: '1:442780655388:ios:e504e60a4e93cba92764d9',
    messagingSenderId: '442780655388',
    projectId: 'sora-de',
    storageBucket: 'sora-de.firebasestorage.app',
    iosBundleId: 'com.sorade.sorade',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDPTa9dmPNlTZhdT-MyxUJDumDpobwRm6Y',
    appId: '1:442780655388:ios:e504e60a4e93cba92764d9',
    messagingSenderId: '442780655388',
    projectId: 'sora-de',
    storageBucket: 'sora-de.firebasestorage.app',
    iosBundleId: 'com.sorade.sorade',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBRfN4r3wEBDLtarFiD51_TrEURE47Q2x8',
    appId: '1:442780655388:web:e6c518305dcb98082764d9',
    messagingSenderId: '442780655388',
    projectId: 'sora-de',
    authDomain: 'sora-de.firebaseapp.com',
    storageBucket: 'sora-de.firebasestorage.app',
    measurementId: 'G-PZDP1QMDBT',
  );

}