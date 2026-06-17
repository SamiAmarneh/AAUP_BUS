import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bus_company/data/bus_providers.dart';
import '../../bus_company/data/route_providers.dart';
import 'reservation_repository.dart';
import 'student_booking_local_storage.dart';

final studentBookingLocalStorageProvider = Provider<StudentBookingLocalStorage>(
  (ref) => StudentBookingLocalStorage(),
);

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(
    busRepository: ref.watch(busRepositoryProvider),
    routeRepository: ref.watch(routeRepositoryProvider),
  );
});
