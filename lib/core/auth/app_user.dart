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

  String get displayName => name ?? email;

  factory AppUser.fromAdminDoc({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppUser(
      uid: uid,
      role: UserRole.admin,
      email: data['email'] as String? ?? '',
    );
  }

  factory AppUser.fromDriverDoc({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppUser(
      uid: uid,
      role: UserRole.driver,
      email: data['email'] as String? ?? '',
      name: data['name'] as String?,
    );
  }
}
