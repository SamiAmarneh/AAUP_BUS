import 'driver_status.dart';

class DriverProfile {
  const DriverProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.status,
  });

  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String status;

  factory DriverProfile.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return DriverProfile(
      uid: uid,
      email: _readString(data, 'email'),
      name: _readString(data, 'name'),
      phoneNumber: _readString(data, 'phone_number'),
      status: _readString(data, 'status', fallback: DriverStatus.active),
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
}
