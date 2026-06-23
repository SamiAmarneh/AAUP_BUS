import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_role.dart';

enum AuthFailureType {
  invalidCredentials,
  unauthorized,
  roleMismatch,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.type, this.message);

  final AuthFailureType type;
  final String message;

  @override
  String toString() => message;
}

AuthFailure mapFirebaseAuthException(FirebaseAuthException exception) {
  const invalidCredentialCodes = {
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
  };

  return switch (exception.code) {
    _ when invalidCredentialCodes.contains(exception.code) => const AuthFailure(
      AuthFailureType.invalidCredentials,
      'Invalid email or password.',
    ),
    'user-disabled' => const AuthFailure(
      AuthFailureType.unauthorized,
      'This account has been disabled.',
    ),
    'too-many-requests' => const AuthFailure(
      AuthFailureType.network,
      'Too many attempts. Please try again later.',
    ),
    'network-request-failed' => const AuthFailure(
      AuthFailureType.network,
      'Network error. Check your connection and try again.',
    ),
    _ => AuthFailure(
      AuthFailureType.unknown,
      exception.message ?? 'Authentication failed. Please try again.',
    ),
  };
}

const AuthFailure unauthorizedFailure = AuthFailure(
  AuthFailureType.unauthorized,
  'Account not authorized. Contact your administrator.',
);

const String loginFailedMessage = 'Login failed. Please try again.';

AuthFailure roleMismatchFailure(UserRole expectedRole) {
  return switch (expectedRole) {
    UserRole.admin => const AuthFailure(
      AuthFailureType.roleMismatch,
      'This account is set up as a driver only. Use Driver Login, or create '
      'an admins/{your Firebase UID} document in Firestore.',
    ),
    UserRole.driver => const AuthFailure(
      AuthFailureType.roleMismatch,
      'This account is set up as an admin only. Use Bus Company Login.',
    ),
  };
}

const AuthFailure inactiveDriverFailure = AuthFailure(
  AuthFailureType.unauthorized,
  'This driver account is inactive.',
);

AuthFailure mapFirestoreException(FirebaseException exception) {
  return switch (exception.code) {
    'permission-denied' => const AuthFailure(
      AuthFailureType.unauthorized,
      'Firestore permission denied. Deploy the latest firestore.rules '
      '(firebase deploy --only firestore:rules). If you recently added a '
      'new collection such as routes or buses, the deployed rules must be '
      'updated before admin CRUD will work.',
    ),
    'unavailable' => const AuthFailure(
      AuthFailureType.network,
      'Firestore is unavailable. Check your connection and try again.',
    ),
    _ => AuthFailure(
      AuthFailureType.unknown,
      exception.message ?? 'Could not load account profile. Please try again.',
    ),
  };
}

AuthFailure missingProfileFailure({
  required UserRole role,
  required String uid,
}) {
  final collection = role == UserRole.admin ? 'admins' : 'drivers';
  return AuthFailure(
    AuthFailureType.unauthorized,
    'No $collection profile found. In Firestore create document '
    '$collection/$uid with field email matching your login (see README).',
  );
}
