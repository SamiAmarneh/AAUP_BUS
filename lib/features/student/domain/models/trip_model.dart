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
    required this.departure,
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
  final String departure;
  final int availableSeats;
  final int totalSeats;

  factory Trip.fromTripDetails(TripDetails details) {
    final departureTime = details.trip.departureTime ?? details.trip.createdAt;
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
      departure: departureTime != null ? _formatTime(departureTime) : '--:--',
      availableSeats: details.bus.capacity,
      totalSeats: details.bus.capacity,
    );
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
