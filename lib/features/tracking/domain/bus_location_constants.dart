abstract final class BusLocationConstants {
  static const int publishIntervalSeconds = 5;
  // Allow several missed polls + network latency before hiding a bus.
  static const int staleLocationThresholdSeconds = 120;
}
