import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/driver_notification_background.dart';
import 'core/permissions/location_permission_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DefaultFirebaseOptions.initializeForCurrentPlatform();
  await registerFirebaseMessagingBackgroundHandler();
  await LocationPermissionService().requestOnFirstLaunch();
  runApp(const App());
}
