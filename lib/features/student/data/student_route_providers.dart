import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_refresh_constants.dart';
import '../../bus_company/data/route_providers.dart';
import '../../bus_company/data/route_repository.dart';
import '../../bus_company/domain/route_profile.dart';

/// Guest-safe route list using one-shot fetches (same rules as stream).
final studentActiveRoutesProvider = StreamProvider<List<RouteProfile>>((ref) {
  final routeRepository = ref.watch(routeRepositoryProvider);

  return _activeRoutesStream(routeRepository: routeRepository);
});

Stream<List<RouteProfile>> _activeRoutesStream({
  required RouteRepository routeRepository,
}) async* {
  while (true) {
    try {
      yield await routeRepository.fetchActiveRoutes();
    } catch (_) {
      yield [];
    }

    await Future<void>.delayed(
      const Duration(seconds: FirestoreRefreshConstants.listIntervalSeconds),
    );
  }
}
