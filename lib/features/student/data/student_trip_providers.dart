import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_refresh_constants.dart';
import '../../trips/data/trip_repository.dart';
import '../../trips/data/trip_providers.dart';
import '../../trips/domain/trip_details.dart';

final selectedRouteFilterProvider = StateProvider<String?>((ref) => null);

final studentAvailableTripsProvider = StreamProvider<List<TripDetails>>((ref) {
  final routeId = ref.watch(selectedRouteFilterProvider);
  final tripRepository = ref.watch(tripRepositoryProvider);

  return _availableTripsStream(
    tripRepository: tripRepository,
    routeId: routeId,
  );
});

Stream<List<TripDetails>> _availableTripsStream({
  required TripRepository tripRepository,
  required String? routeId,
}) async* {
  while (true) {
    try {
      yield await tripRepository.fetchAvailableTripDetails(routeId: routeId);
    } catch (_) {
      yield [];
    }

    await Future<void>.delayed(
      const Duration(seconds: FirestoreRefreshConstants.listIntervalSeconds),
    );
  }
}
