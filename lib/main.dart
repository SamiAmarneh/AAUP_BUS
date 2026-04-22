import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DefaultFirebaseOptions.initializeForCurrentPlatform();
  runApp(const App());
}
