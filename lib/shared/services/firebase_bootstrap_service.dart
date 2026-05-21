import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../firebase_options.dart';

class FirebaseBootstrapService {
  /// Initializes core Firebase SDKs used across Shootr.
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await FirebaseMessaging.instance.requestPermission();
    FirebaseAnalytics.instance;
    FirebaseAuth.instance;
    FirebaseFirestore.instance;
    FirebaseFunctions.instance;
    FirebaseStorage.instance;
  }
}
