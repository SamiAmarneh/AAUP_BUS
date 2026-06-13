import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/auth_providers.dart';
import '../../bus_company/data/bus_providers.dart';
import '../../bus_company/data/route_providers.dart';
import '../domain/trip_details.dart';
import '../domain/trip_profile.dart';
import 'trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    busRepository: ref.watch(busRepositoryProvider),
  );
});

final activeTripForDriverProvider = StreamProvider<TripProfile?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) {
    return Stream<TripProfile?>.value(null);
  }
  return ref.watch(tripRepositoryProvider).watchActiveTripForDriver(profile.uid);
});

final driverActiveTripDetailsProvider = StreamProvider<TripDetails?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) {
    return Stream<TripDetails?>.value(null);
  }

  final tripRepository = ref.watch(tripRepositoryProvider);
  final busRepository = ref.watch(busRepositoryProvider);
  final routeRepository = ref.watch(routeRepositoryProvider);

  return tripRepository.watchActiveTripForDriver(profile.uid).asyncMap(
    (trip) async {
      if (trip == null) {
        return null;
      }

      final bus = await busRepository.fetchBusForDriver(profile.uid);
      final route = await routeRepository.fetchRouteById(trip.routeId);

      if (bus == null) {
        throw const AuthFailure(
          AuthFailureType.unknown,
          'No bus assigned. Contact your administrator.',
        );
      }

      if (route == null) {
        throw const AuthFailure(
          AuthFailureType.unknown,
          'Route details are unavailable.',
        );
      }

      return TripDetails(trip: trip, bus: bus, route: route);
    },
  );
});
