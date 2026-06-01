import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/bus_profile.dart';
import 'bus_repository.dart';

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepository();
});

final activeBusesProvider = StreamProvider<List<BusProfile>>((ref) {
  return ref.watch(busRepositoryProvider).watchActiveBuses();
});
