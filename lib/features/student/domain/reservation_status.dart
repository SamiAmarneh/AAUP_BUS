abstract final class ReservationStatus {
  static const String waitingBoarding = 'waiting-boarding';
  static const String boarded = 'Boarded';

  static String displayLabel(String status) {
    return switch (status) {
      waitingBoarding => 'Waiting for Boarding',
      boarded => 'Boarded',
      _ => status,
    };
  }
}
