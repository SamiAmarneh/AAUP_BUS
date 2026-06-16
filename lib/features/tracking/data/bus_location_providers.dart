import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bus_location_repository.dart';
import 'bus_location_tracking_controller.dart';

final busLocationRepositoryProvider = Provider<BusLocationRepository>((ref) {
  return BusLocationRepository();
});

final busLocationTrackingProvider = Provider<BusLocationTrackingController>((
  ref,
) {
  ref.keepAlive();
  final controller = BusLocationTrackingController(
    ref,
    ref.read(busLocationRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
