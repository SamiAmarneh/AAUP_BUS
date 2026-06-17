import '../../../trips/domain/trip_details.dart';

class Trip {
  const Trip({
    this.id,
    this.status,
    required this.city,
    required this.route,
    required this.company,
    required this.price,
    required this.from,
    required this.to,
    required this.availableSeats,
    required this.totalSeats,
  });

  final String? id;
  final String? status;
  final String city;
  final String route;
  final String company;
  final int price;
  final String from;
  final String to;
  final int availableSeats;
  final int totalSeats;

  factory Trip.fromTripDetails(TripDetails details) {
    final routeGroupLabel = details.route.routeName.isNotEmpty
        ? details.route.routeName
        : details.route.startLocation;

    return Trip(
      id: details.trip.id,
      status: details.trip.status,
      city: routeGroupLabel,
      route: details.routeLabel,
      company: details.bus.name,
      price: details.trip.price.round(),
      from: details.route.startLocation,
      to: details.route.endLocation,
      availableSeats: details.bus.capacity,
      totalSeats: details.bus.capacity,
    );
  }
}
