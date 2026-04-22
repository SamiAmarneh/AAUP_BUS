import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// From `android/app/google-services.json` (Android package `com.aaup.bus`).
/// For iOS/macOS/web, add those apps in the Firebase console and run
/// `flutterfire configure`, or add matching `FirebaseOptions` here.
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzrlynYB2Fu--tP_zWpamiLfIQeWaLD1s',
    appId: '1:898847540096:android:e017f15c3fe122571b3765',
    messagingSenderId: '898847540096',
    projectId: 'aaup-bus-tracking',
    storageBucket: 'aaup-bus-tracking.firebasestorage.app',
  );

  /// Call after [WidgetsFlutterBinding.ensureInitialized]. No-op on non-Android.
  static Future<void> initializeForCurrentPlatform() async {
    if (kIsWeb) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await Firebase.initializeApp(options: android);
  }
}
