import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.email,
    this.name,
  });

  final String uid;
  final UserRole role;
  final String email;
  final String? name;

  String get displayName {
    final resolvedName = name?.trim();
    return resolvedName != null && resolvedName.isNotEmpty
        ? resolvedName
        : email;
  }

  factory AppUser.fromAdminDoc({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppUser(
      uid: uid,
      role: UserRole.admin,
      email: _readEmail(data),
      name: _readName(data),
    );
  }

  factory AppUser.fromDriverDoc({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppUser(
      uid: uid,
      role: UserRole.driver,
      email: _readEmail(data),
      name: _readName(data),
    );
  }

  static String _readEmail(Map<String, dynamic> data) {
    final email = data['email'];
    return email is String ? email.trim() : '';
  }

  static String? _readName(Map<String, dynamic> data) {
    final value = data['name'];
    if (value == null) {
      return null;
    }
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
