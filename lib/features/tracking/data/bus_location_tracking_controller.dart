import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/permissions/location_permission_service.dart';
import '../../trips/data/trip_providers.dart';
import '../../trips/domain/trip_profile.dart';
import '../domain/bus_location_constants.dart';
import 'bus_location_repository.dart';

class BusLocationTrackingController {
  BusLocationTrackingController(this._ref, this._repository) {
    _activeTripSubscription = _ref.listen(
      activeTripForDriverProvider,
      (_, next) => _handleActiveTripChange(next),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final BusLocationRepository _repository;
  ProviderSubscription<AsyncValue<TripProfile?>>? _activeTripSubscription;
  Timer? _publishTimer;
  String? _trackedBusId;
  bool _isPublishing = false;

  void _handleActiveTripChange(AsyncValue<TripProfile?> next) {
    next.when(
      data: (trip) {
        final shouldTrack = trip != null && trip.isActive;
        if (!shouldTrack) {
          _stopTracking();
          return;
        }
        _startTracking(trip.busId);
      },
      loading: _stopTracking,
      error: (_, __) => _stopTracking(),
    );
  }

  void _startTracking(String busId) {
    if (_trackedBusId == busId && _publishTimer != null) {
      return;
    }

    _stopTracking();
    _trackedBusId = busId;
    unawaited(_publishCurrentLocation());
    _publishTimer = Timer.periodic(
      const Duration(seconds: BusLocationConstants.publishIntervalSeconds),
      (_) => unawaited(_publishCurrentLocation()),
    );
  }

  void _stopTracking() {
    _publishTimer?.cancel();
    _publishTimer = null;
    _trackedBusId = null;
  }

  Future<void> _publishCurrentLocation() async {
    if (_isPublishing || _trackedBusId == null || kIsWeb) {
      return;
    }

    _isPublishing = true;
    try {
      final busId = _trackedBusId;
      if (busId == null) {
        return;
      }

      final permissionStatus =
          await LocationPermissionService().ensureGranted();
      if (permissionStatus != LocationPermissionStatus.granted) {
        _stopTracking();
        return;
      }

      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _repository.publishLocation(
        busId: busId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Skip failed interval; next tick will retry.
    } finally {
      _isPublishing = false;
    }
  }

  void dispose() {
    _activeTripSubscription?.close();
    _stopTracking();
  }
}
