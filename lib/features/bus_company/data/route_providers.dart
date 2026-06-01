import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/route_profile.dart';
import 'route_repository.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository();
});

final activeRoutesProvider = StreamProvider<List<RouteProfile>>((ref) {
  return ref.watch(routeRepositoryProvider).watchActiveRoutes();
});
