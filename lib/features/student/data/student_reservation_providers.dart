import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_refresh_constants.dart';
import '../domain/models/reservation_details.dart';
import 'reservation_providers.dart';
import 'reservation_repository.dart';
import 'student_booking_local_storage.dart';

final activeTicketsProvider = StreamProvider<List<ReservationDetails>>((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  final localStorage = ref.watch(studentBookingLocalStorageProvider);

  return _activeTicketsStream(
    repository: repository,
    localStorage: localStorage,
  );
});

Stream<List<ReservationDetails>> _activeTicketsStream({
  required ReservationRepository repository,
  required StudentBookingLocalStorage localStorage,
}) async* {
  while (true) {
    try {
      final reservationIds = await localStorage.getSavedReservationIds();
      final tickets = await repository.fetchActiveReservationsByIds(
        reservationIds,
      );
      yield tickets;
    } catch (_) {
      yield [];
    }

    await Future<void>.delayed(
      const Duration(seconds: FirestoreRefreshConstants.listIntervalSeconds),
    );
  }
}

Future<void> refreshActiveTickets(WidgetRef ref) async {
  ref.invalidate(activeTicketsProvider);
  await ref.read(activeTicketsProvider.future);
}
