import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_refresh_constants.dart';
import '../../student/data/reservation_providers.dart';
import '../../trips/data/trip_providers.dart';

final adminActiveTripsCountProvider = StreamProvider<int>((ref) {
  final tripRepository = ref.watch(tripRepositoryProvider);

  return _polledCountStream(
    fetchCount: () async {
      final trips = await tripRepository.fetchAvailableTrips();
      return trips.length;
    },
  );
});

final adminBookingsTodayCountProvider = StreamProvider<int>((ref) {
  final reservationRepository = ref.watch(reservationRepositoryProvider);

  return _polledCountStream(
    fetchCount: reservationRepository.countBookingsToday,
  );
});

Stream<int> _polledCountStream({
  required Future<int> Function() fetchCount,
}) async* {
  while (true) {
    try {
      yield await fetchCount();
    } catch (_) {
      yield 0;
    }

    await Future<void>.delayed(
      const Duration(seconds: FirestoreRefreshConstants.listIntervalSeconds),
    );
  }
}
