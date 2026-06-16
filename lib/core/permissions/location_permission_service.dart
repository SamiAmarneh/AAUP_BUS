import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class PermissionStorageKeys {
  static const String locationRequested = 'location_permission_requested';
}

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
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
    await _requestLocationPermission();
  }

  Future<LocationPermissionStatus> ensureGranted() async {
    if (kIsWeb) {
      return LocationPermissionStatus.granted;
    }

    try {
      final currentStatus = await Permission.locationWhenInUse.status;
      if (currentStatus.isGranted) {
        return LocationPermissionStatus.granted;
      }

      if (currentStatus.isPermanentlyDenied) {
        return LocationPermissionStatus.permanentlyDenied;
      }

      final updatedStatus = await _requestLocationPermission();
      if (updatedStatus.isGranted) {
        return LocationPermissionStatus.granted;
      }

      return updatedStatus.isPermanentlyDenied
          ? LocationPermissionStatus.permanentlyDenied
          : LocationPermissionStatus.denied;
    } catch (_) {
      return LocationPermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    try {
      return await Permission.locationWhenInUse.request();
    } catch (_) {
      return PermissionStatus.denied;
    }
  }
}
