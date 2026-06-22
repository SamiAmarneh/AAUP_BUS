import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_refresh_constants.dart';
import '../../tracking/data/bus_location_providers.dart';
import '../../tracking/data/bus_location_repository.dart';
import '../../tracking/domain/bus_location_constants.dart';
import '../../tracking/domain/tracked_bus_details.dart';
import '../../trips/data/trip_providers.dart';
import '../../trips/data/trip_repository.dart';

final studentTrackedBusesProvider = StreamProvider<List<TrackedBusDetails>>((
  ref,
) {
  final tripRepository = ref.watch(tripRepositoryProvider);
  final busLocationRepository = ref.watch(busLocationRepositoryProvider);

  return _trackedBusesStream(
    tripRepository: tripRepository,
    busLocationRepository: busLocationRepository,
  );
});

Stream<List<TrackedBusDetails>> _trackedBusesStream({
  required TripRepository tripRepository,
  required BusLocationRepository busLocationRepository,
}) async* {
  while (true) {
    try {
      yield await _fetchTrackedBuses(
        tripRepository: tripRepository,
        busLocationRepository: busLocationRepository,
      );
    } catch (_) {
      yield [];
    }

    await Future<void>.delayed(
      const Duration(seconds: FirestoreRefreshConstants.listIntervalSeconds),
    );
  }
}

Future<List<TrackedBusDetails>> _fetchTrackedBuses({
  required TripRepository tripRepository,
  required BusLocationRepository busLocationRepository,
}) async {
  final activeTrips = await tripRepository.fetchActiveTripDetails();
  if (activeTrips.isEmpty) {
    return [];
  }

  final busIds = activeTrips.map((trip) => trip.bus.id).toList();
  final locations = await busLocationRepository.fetchLatestLocationsForBuses(
    busIds,
  );

  final now = DateTime.now();
  final staleThreshold = const Duration(
    seconds: BusLocationConstants.staleLocationThresholdSeconds,
  );

  final trackedBuses =
      activeTrips
          .map((tripDetails) {
            if (!tripDetails.hasAvailableSeats) {
              return null;
            }

            final location = locations[tripDetails.bus.id];
            if (location == null) {
              return null;
            }

            final age = now.difference(location.timestamp);
            if (age > staleThreshold) {
              return null;
            }

            return TrackedBusDetails(
              tripDetails: tripDetails,
              location: location,
            );
          })
          .whereType<TrackedBusDetails>()
          .toList();

  return trackedBuses;
}

Future<void> refreshStudentLiveTracking(WidgetRef ref) async {
  ref.invalidate(studentTrackedBusesProvider);
  await ref.read(studentTrackedBusesProvider.future);
}
