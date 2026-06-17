import 'package:cloud_firestore/cloud_firestore.dart';

import 'trip_status.dart';

class TripProfile {
  static const int defaultTotalPassengers = 0;

  const TripProfile({
    required this.id,
    required this.driverUid,
    required this.busId,
    required this.routeId,
    required this.status,
    required this.price,
    this.totalPassengers = defaultTotalPassengers,
    this.departureTime,
    this.arrivalTime,
    this.createdAt,
  });

  final String id;
  final String driverUid;
  final String busId;
  final String routeId;
  final String status;
  final double price;
  final int totalPassengers;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final DateTime? createdAt;

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
      price: _readPrice(data),
      totalPassengers: _readInt(data, 'total_passengers'),
      departureTime: _readTimestamp(data, 'departure_time'),
      arrivalTime: _readTimestamp(data, 'arrival_time'),
      createdAt: _readTimestamp(data, 'created_at'),
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

  static double _readPrice(Map<String, dynamic> data) {
    final value = data['price'];
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static int _readInt(
    Map<String, dynamic> data,
    String key, {
    int fallback = defaultTotalPassengers,
  }) {
    final value = data[key];
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }
}
