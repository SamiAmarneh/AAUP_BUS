class TripHistoryItem {
  const TripHistoryItem({
    required this.tripId,
    required this.status,
    required this.statusLabel,
    required this.isActive,
    required this.routeLabel,
    required this.busName,
    this.departureTime,
    this.arrivalTime,
  });

  final String tripId;
  final String status;
  final String statusLabel;
  final bool isActive;
  final String routeLabel;
  final String busName;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  DateTime? get sortKey => arrivalTime ?? departureTime;
}
