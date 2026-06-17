abstract final class PaymentStatus {
  static const String completed = 'completed';
  static const String pending = 'pending';
  static const String failed = 'failed';

  static String displayLabel(String status) {
    return switch (status) {
      completed => 'Completed',
      pending => 'Pending',
      failed => 'Failed',
      _ => status,
    };
  }
}
