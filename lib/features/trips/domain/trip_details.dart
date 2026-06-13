import '../../bus_company/domain/bus_profile.dart';
import '../../bus_company/domain/route_profile.dart';
import '../domain/trip_profile.dart';

class TripDetails {
  const TripDetails({
    required this.trip,
    required this.bus,
    required this.route,
  });

  final TripProfile trip;
  final BusProfile bus;
  final RouteProfile route;

  String get routeLabel => '${route.startLocation} → ${route.endLocation}';
}
