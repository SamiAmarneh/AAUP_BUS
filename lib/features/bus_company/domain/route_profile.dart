import 'route_status.dart';

class RouteProfile {
  const RouteProfile({
    required this.id,
    required this.routeName,
    required this.startLocation,
    required this.endLocation,
    required this.status,
  });

  final String id;
  final String routeName;
  final String startLocation;
  final String endLocation;
  final String status;

  factory RouteProfile.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return RouteProfile(
      id: id,
      routeName: _readString(data, 'route_name'),
      startLocation: _readString(data, 'start_location'),
      endLocation: _readString(data, 'end_location'),
      status: _readString(data, 'status', fallback: RouteStatus.active),
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
