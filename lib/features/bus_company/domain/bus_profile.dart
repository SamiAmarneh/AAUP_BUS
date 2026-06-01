import 'package:cloud_firestore/cloud_firestore.dart';

import 'bus_status.dart';

class BusProfile {
  const BusProfile({
    required this.id,
    required this.name,
    required this.capacity,
    required this.driverUid,
    required this.status,
  });

  final String id;
  final String name;
  final int capacity;
  final String driverUid;
  final String status;

  factory BusProfile.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return BusProfile(
      id: id,
      name: _readString(data, 'name'),
      capacity: _readCapacity(data),
      driverUid: _readDriverUid(data),
      status: _readString(data, 'status', fallback: BusStatus.active),
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

  static int _readCapacity(Map<String, dynamic> data) {
    final value = data['capacity'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static String _readDriverUid(Map<String, dynamic> data) {
    final value = data['driver_id'];
    if (value is DocumentReference) {
      return value.id;
    }
    if (value is String) {
      final segments = value.split('/');
      return segments.isNotEmpty ? segments.last : '';
    }
    return '';
  }
}
