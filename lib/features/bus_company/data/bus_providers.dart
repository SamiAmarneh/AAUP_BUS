import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../domain/bus_profile.dart';
import 'bus_repository.dart';

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepository();
});

final activeBusesProvider = StreamProvider<List<BusProfile>>((ref) {
  return ref.watch(busRepositoryProvider).watchActiveBuses();
});

final assignedBusForDriverProvider = StreamProvider<BusProfile?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) {
    return Stream<BusProfile?>.value(null);
  }
  return ref.watch(busRepositoryProvider).watchBusForDriver(profile.uid);
});
