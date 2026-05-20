import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_providers.dart';
import 'auth_providers.dart';

Future<void> performLogout(BuildContext context, WidgetRef ref) async {
  await ref.read(authRepositoryProvider).signOut();
  await clearGuestStudentSession(ref);
  ref.invalidate(currentUserProfileProvider);
  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
