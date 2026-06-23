import 'package:cloud_firestore/cloud_firestore.dart';

import '../reservation_status.dart';

class ReservationProfile {
  const ReservationProfile({
    required this.id,
    required this.tripId,
    required this.phoneNumber,
    required this.qrData,
    required this.status,
    this.reservationTime,
    this.pickupLocation = '',
    this.pickupCoordinates,
  });

  final String id;
  final String tripId;
  final String phoneNumber;
  final String qrData;
  final String status;
  final DateTime? reservationTime;
  final String pickupLocation;
  final GeoPoint? pickupCoordinates;

  bool get isWaitingBoarding => status == ReservationStatus.waitingBoarding;

  factory ReservationProfile.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return ReservationProfile(
      id: id,
      tripId: _readReferenceId(data, 'trip_id'),
      phoneNumber: _readString(data, 'phone_number'),
      qrData: _readString(data, 'qr_data'),
      status: _readString(
        data,
        'status',
        fallback: ReservationStatus.waitingBoarding,
      ),
      reservationTime: _readTimestamp(data, 'reservation_time'),
      pickupLocation: _readString(data, 'pickup_location'),
      pickupCoordinates: _readGeoPoint(data, 'pickup_coordinates'),
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

  static GeoPoint? _readGeoPoint(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is GeoPoint ? value : null;
  }
}
