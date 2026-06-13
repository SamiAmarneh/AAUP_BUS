abstract final class TripStatus {
  static const String waitingPassengers = 'Waiting-Passengers';
  static const String onTheWay = 'On-the-way';
  static const String arrived = 'Arrived';

  static const List<String> activeStatuses = [
    waitingPassengers,
    onTheWay,
  ];

  static String displayLabel(String status) {
    return switch (status) {
      waitingPassengers => 'Waiting for Passengers',
      onTheWay => 'On the Way',
      arrived => 'Arrived',
      _ => status,
    };
  }
}
