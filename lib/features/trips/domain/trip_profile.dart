import 'package:cloud_firestore/cloud_firestore.dart';

import 'trip_status.dart';

class TripProfile {
  const TripProfile({
    required this.id,
    required this.driverUid,
    required this.busId,
    required this.routeId,
    required this.status,
    this.departureTime,
    this.arrivalTime,
  });

  final String id;
  final String driverUid;
  final String busId;
  final String routeId;
  final String status;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  bool get isActive => TripStatus.activeStatuses.contains(status);

  String get statusLabel => TripStatus.displayLabel(status);

  factory TripProfile.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return TripProfile(
      id: id,
      driverUid: _readReferenceId(data, 'driver_id'),
      busId: _readReferenceId(data, 'bus_id'),
      routeId: _readReferenceId(data, 'route_id'),
      status: _readString(data, 'status'),
      departureTime: _readTimestamp(data, 'departure_time'),
      arrivalTime: _readTimestamp(data, 'arrival_time'),
    );
  }

  static String _readString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    return value is String ? value.trim() : fallback;
  }

  static String _readReferenceId(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is DocumentReference) {
      return value.id;
    }
    if (value is String) {
      final segments = value.split('/');
      return segments.isNotEmpty ? segments.last : '';
    }
    return '';
  }

  static DateTime? _readTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is Timestamp ? value.toDate() : null;
  }
}
