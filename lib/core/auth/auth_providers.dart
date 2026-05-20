import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_user.dart';
import 'auth_repository.dart';

/// Bumped when sign-in starts/ends so [currentUserProfileProvider] can refetch.
final signInSessionTickProvider = StateProvider<int>((ref) => 0);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    onSignInStateChanged: () {
      ref.read(signInSessionTickProvider.notifier).state++;
    },
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  ref.watch(signInSessionTickProvider);
  final repository = ref.read(authRepositoryProvider);
  if (repository.isSignInInProgress) {
    return null;
  }
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    return null;
  }
  return ref.read(authRepositoryProvider).fetchCurrentProfile();
});

/// Loads profile from `admins/{uid}` only (same source as driver uses `drivers/{uid}`).
final adminProfileProvider = FutureProvider<AppUser?>((ref) async {
  ref.watch(signInSessionTickProvider);
  final repository = ref.read(authRepositoryProvider);
  if (repository.isSignInInProgress) {
    return null;
  }
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    return null;
  }
  return repository.fetchAdminProfile();
});
