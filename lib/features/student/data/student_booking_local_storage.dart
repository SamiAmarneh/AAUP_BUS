import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class StudentBookingStorageKeys {
  static const String phoneNumbers = 'student_booking_phone_numbers';
  static const String reservationIds = 'student_booking_reservation_ids';
}

class StudentBookingLocalStorage {
  Future<List<String>> getSavedPhoneNumbers() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(StudentBookingStorageKeys.phoneNumbers);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<String>()
          .map((phone) => phone.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePhoneNumber(String phoneNumber) async {
    final normalized = phoneNumber.trim();
    if (normalized.isEmpty) {
      return;
    }

    final existing = await getSavedPhoneNumbers();
    if (existing.contains(normalized)) {
      return;
    }

    final updated = [normalized, ...existing];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      StudentBookingStorageKeys.phoneNumbers,
      jsonEncode(updated),
    );
  }

  Future<List<String>> getSavedReservationIds() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(StudentBookingStorageKeys.reservationIds);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<String>()
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReservationId(String reservationId) async {
    final normalized = reservationId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final existing = await getSavedReservationIds();
    if (existing.contains(normalized)) {
      return;
    }

    final updated = [normalized, ...existing];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      StudentBookingStorageKeys.reservationIds,
      jsonEncode(updated),
    );
  }
}
