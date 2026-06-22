import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../tracking/domain/tracked_bus_details.dart';

abstract final class GeoDistanceFormatter {
  static const double metersPerKilometer = 1000;
  static const int metersPerKilometerThreshold = 1000;

  static double distanceMetersFromUser({
    required LatLng userPosition,
    required TrackedBusDetails trackedBus,
  }) {
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      trackedBus.location.latitude,
      trackedBus.location.longitude,
    );
  }

  static String formatAwayLabel(double distanceMeters) {
    if (distanceMeters < metersPerKilometerThreshold) {
      return '${distanceMeters.round()} m away';
    }

    final distanceKm = distanceMeters / metersPerKilometer;
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  static List<TrackedBusDetails> sortByNearest({
    required LatLng userPosition,
    required List<TrackedBusDetails> trackedBuses,
  }) {
    final sorted = [...trackedBuses]
      ..sort(
        (first, second) => distanceMetersFromUser(
          userPosition: userPosition,
          trackedBus: first,
        ).compareTo(
          distanceMetersFromUser(
            userPosition: userPosition,
            trackedBus: second,
          ),
        ),
      );
    return sorted;
  }
}
