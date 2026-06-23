import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await DefaultFirebaseOptions.initializeForCurrentPlatform();
}

Future<void> registerFirebaseMessagingBackgroundHandler() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
