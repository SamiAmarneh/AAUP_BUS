import 'package:cloud_firestore/cloud_firestore.dart';

import '../payment_status.dart';

class PaymentProfile {
  const PaymentProfile({
    required this.id,
    required this.reservationId,
    required this.amount,
    required this.paymentStatus,
    this.paymentTime,
  });

  final String id;
  final String reservationId;
  final double amount;
  final String paymentStatus;
  final DateTime? paymentTime;

  bool get isCompleted => paymentStatus == PaymentStatus.completed;

  factory PaymentProfile.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return PaymentProfile(
      id: id,
      reservationId: _readReferenceId(data, 'reservation_id'),
      amount: _readAmount(data),
      paymentStatus: _readString(
        data,
        'payment_status',
        fallback: PaymentStatus.pending,
      ),
      paymentTime: _readTimestamp(data, 'payment_time'),
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

  static double _readAmount(Map<String, dynamic> data) {
    final value = data['amount'];
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static DateTime? _readTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is Timestamp ? value.toDate() : null;
  }
}
