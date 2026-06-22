import 'package:cloud_firestore/cloud_firestore.dart';

class BusLocationProfile {
  const BusLocationProfile({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final String busId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  factory BusLocationProfile.fromFirestore({
    required Map<String, dynamic> data,
  }) {
    return BusLocationProfile(
      busId: _readReferenceId(data, 'bus_id'),
      latitude: _readLatitude(data),
      longitude: _readLongitude(data),
      timestamp: _readTimestamp(data),
    );
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

  static double _readLatitude(Map<String, dynamic> data) {
    final value = data['location'];
    return value is GeoPoint ? value.latitude : 0;
  }

  static double _readLongitude(Map<String, dynamic> data) {
    final value = data['location'];
    return value is GeoPoint ? value.longitude : 0;
  }

  static DateTime _readTimestamp(Map<String, dynamic> data) {
    final value = data['timestamp'];
    return value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
