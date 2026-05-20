import 'package:shared_preferences/shared_preferences.dart';

abstract final class SessionStorageKeys {
  static const String guestStudent = 'guest_student_session';
  static const String signedInRole = 'signed_in_role';
}

class AppSessionRepository {
  Future<bool> isGuestStudent() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(SessionStorageKeys.guestStudent) ?? false;
  }

  Future<void> setGuestStudent({required bool isActive}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SessionStorageKeys.guestStudent, isActive);
  }

  Future<void> clearGuestStudent() => setGuestStudent(isActive: false);
}
