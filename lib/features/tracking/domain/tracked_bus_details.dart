import '../../trips/domain/trip_details.dart';
import 'bus_location_profile.dart';

class TrackedBusDetails {
  const TrackedBusDetails({
    required this.tripDetails,
    required this.location,
  });

  final TripDetails tripDetails;
  final BusLocationProfile location;

  String get routeLabel => tripDetails.routeLabel;

  String get busName => tripDetails.bus.name;

  String get statusLabel => tripDetails.trip.statusLabel;
}
