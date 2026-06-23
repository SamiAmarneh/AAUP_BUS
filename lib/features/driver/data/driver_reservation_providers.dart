import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../student/data/reservation_providers.dart';
import '../../student/domain/models/reservation_profile.dart';
import '../../trips/data/trip_providers.dart';

final driverTripReservationsProvider =
    StreamProvider<List<ReservationProfile>>((ref) {
      final tripDetails = ref.watch(driverActiveTripDetailsStreamProvider).valueOrNull;
      final tripId = tripDetails?.trip.id;
      if (tripId == null || tripId.isEmpty) {
        return Stream.value(const <ReservationProfile>[]);
      }

      return ref
          .watch(reservationRepositoryProvider)
          .watchReservationsForTrip(tripId);
    });
