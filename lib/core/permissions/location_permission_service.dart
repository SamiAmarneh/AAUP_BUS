import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class PermissionStorageKeys {
  static const String locationRequested = 'location_permission_requested';
}

class LocationPermissionService {
  Future<void> requestOnFirstLaunch() async {
    if (kIsWeb) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final alreadyRequested =
        preferences.getBool(PermissionStorageKeys.locationRequested) ?? false;
    if (alreadyRequested) {
      return;
    }

    await preferences.setBool(PermissionStorageKeys.locationRequested, true);

    try {
      await Permission.locationWhenInUse.request();
    } catch (_) {
      // Permission flow may fail on unsupported platforms; app continues.
    }
  }
}
