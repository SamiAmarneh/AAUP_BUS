import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../student/data/reservation_providers.dart';
import '../../student/domain/models/reservation_profile.dart';

final driverTripPassengersProvider = StreamProvider.autoDispose
    .family<List<ReservationProfile>, String>((ref, tripId) {
      final trimmedTripId = tripId.trim();
      if (trimmedTripId.isEmpty) {
        return Stream.value(const <ReservationProfile>[]);
      }

      return ref
          .watch(reservationRepositoryProvider)
          .watchReservationsForTrip(trimmedTripId);
    });
