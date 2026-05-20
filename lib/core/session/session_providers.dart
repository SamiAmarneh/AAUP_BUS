import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_session_repository.dart';

final appSessionRepositoryProvider = Provider<AppSessionRepository>((ref) {
  return AppSessionRepository();
});

final guestStudentSessionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(appSessionRepositoryProvider).isGuestStudent();
});

Future<void> activateGuestStudentSession(WidgetRef ref) async {
  await ref.read(appSessionRepositoryProvider).setGuestStudent(isActive: true);
  ref.invalidate(guestStudentSessionProvider);
}

Future<void> clearGuestStudentSession(WidgetRef ref) async {
  await ref.read(appSessionRepositoryProvider).clearGuestStudent();
  ref.invalidate(guestStudentSessionProvider);
}
