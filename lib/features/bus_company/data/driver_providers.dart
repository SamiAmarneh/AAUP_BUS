import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/driver_profile.dart';
import 'driver_repository.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

final activeDriversProvider = StreamProvider<List<DriverProfile>>((ref) {
  return ref.watch(driverRepositoryProvider).watchActiveDrivers();
});
