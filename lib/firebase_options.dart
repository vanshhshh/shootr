import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config.
///
/// Android is configured from `android/app/google-services.json`.
/// Replace the remaining placeholder values before enabling web or iOS.
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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:000000000000:web:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'shootr-staging',
    authDomain: 'shootr-staging.firebaseapp.com',
    storageBucket: 'shootr-staging.appspot.com',
    measurementId: 'G-REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmymfVjFo1QegWc0g9AtoIlTKXx3OfXjM',
    appId: '1:1039072577992:android:19e33b5a0b5055330b98fd',
    messagingSenderId: '1039072577992',
    projectId: 'shootr-app',
    storageBucket: 'shootr-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:000000000000:ios:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'shootr-staging',
    storageBucket: 'shootr-staging.appspot.com',
    iosBundleId: 'com.shootr.app',
  );
}
