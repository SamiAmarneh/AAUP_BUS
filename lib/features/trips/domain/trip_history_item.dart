import 'trip_status.dart';

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

  static const int _minutesPerHour = 60;

  final String tripId;
  final String status;
  final String statusLabel;
  final bool isActive;
  final String routeLabel;
  final String busName;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  DateTime? get sortKey => arrivalTime ?? departureTime;

  String? get durationLabel {
    if (status != TripStatus.arrived) {
      return null;
    }
    if (departureTime == null || arrivalTime == null) {
      return null;
    }

    final totalMinutes = arrivalTime!.difference(departureTime!).inMinutes;
    if (totalMinutes < 0) {
      return null;
    }

    final hours = totalMinutes ~/ _minutesPerHour;
    final minutes = totalMinutes % _minutesPerHour;

    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
}
