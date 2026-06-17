import 'payment_profile.dart';
import 'reservation_profile.dart';

class ReservationDetails {
  const ReservationDetails({
    required this.reservation,
    required this.payment,
    required this.tripRoute,
    required this.tripFrom,
    required this.tripTo,
    required this.busName,
    required this.tripStatus,
    required this.tripPrice,
  });

  final ReservationProfile reservation;
  final PaymentProfile payment;
  final String tripRoute;
  final String tripFrom;
  final String tripTo;
  final String busName;
  final String tripStatus;
  final double tripPrice;

  String get reservationId => reservation.id;
  String get qrData => reservation.qrData;
  String get phoneNumber => reservation.phoneNumber;
  DateTime? get reservationTime => reservation.reservationTime;
  String get reservationStatus => reservation.status;
  double get paymentAmount => payment.amount;
  String get paymentStatus => payment.paymentStatus;
}
