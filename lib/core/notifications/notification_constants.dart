abstract final class NotificationConstants {
  static const String driverBookingChannelId = 'driver_booking_channel';
  static const String driverBookingChannelName = 'Driver Bookings';
  static const String driverBookingChannelDescription =
      'Alerts when a student books a trip';

  static const String payloadTypeNewBooking = 'new_booking';
  static const String payloadKeyType = 'type';
  static const String payloadKeyTripId = 'tripId';
  static const String payloadKeyReservationId = 'reservationId';
  static const String payloadKeyTotalPassengers = 'totalPassengers';
  static const String payloadKeyPickupLocation = 'pickupLocation';
  static const String payloadKeyPickupLat = 'pickupLat';
  static const String payloadKeyPickupLng = 'pickupLng';
}
