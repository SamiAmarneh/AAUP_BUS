import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../session/app_session_repository.dart';
import 'app_user.dart';
import 'auth_exceptions.dart';
import 'firestore_collections.dart';
import 'user_role.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    void Function()? onSignInStateChanged,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _onSignInStateChanged = onSignInStateChanged;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final void Function()? _onSignInStateChanged;
  bool _isSignInInProgress = false;

  bool get isSignInInProgress => _isSignInInProgress;

  void _notifySignInStateChanged() => _onSignInStateChanged?.call();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentAuthUser => _auth.currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    _isSignInInProgress = true;
    _notifySignInStateChanged();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        await _auth.signOut();
        throw unauthorizedFailure;
      }

      // Persist before profile fetch so auth-state listeners route correctly.
      await _persistSignedInRole(expectedRole);

      AppUser profile;
      try {
        final resolved = await _resolveProfileForRole(uid, expectedRole);
        if (resolved == null) {
          throw missingProfileFailure(role: expectedRole, uid: uid);
        }
        profile = resolved;
        _assertEmailMatchesProfile(credential.user!.email, profile.email);
      } on AuthFailure {
        await _clearSignedInRole();
        await _auth.signOut();
        rethrow;
      } on FirebaseException catch (exception) {
        await _clearSignedInRole();
        await _auth.signOut();
        throw mapFirestoreException(exception);
      }

      await _clearGuestStudentSession();
      return profile;
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    } finally {
      _isSignInInProgress = false;
      _notifySignInStateChanged();
    }
  }

  Future<void> signOut() async {
    await _clearSignedInRole();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    }
  }

  Future<AppUser?> fetchAdminProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    final adminSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.admin,
      uid: uid,
      fromServer: true,
    );
    if (!adminSnapshot.exists) {
      return null;
    }
    return AppUser.fromAdminDoc(uid: uid, data: adminSnapshot.data() ?? {});
  }

  Future<AppUser?> fetchCurrentProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    final signedInRole = await _readSignedInRole();
    final adminSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.admin,
      uid: uid,
      fromServer: true,
    );
    final driverSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.drivers,
      uid: uid,
      fromServer: true,
    );
    final hasAdmin = adminSnapshot.exists;
    final hasDriver = driverSnapshot.exists;

    return switch (signedInRole) {
      UserRole.admin when hasAdmin => AppUser.fromAdminDoc(
        uid: uid,
        data: adminSnapshot.data() ?? {},
      ),
      UserRole.admin => _resolveAdminSignInProfile(uid),
      UserRole.driver when hasDriver => AppUser.fromDriverDoc(
        uid: uid,
        data: driverSnapshot.data() ?? {},
      ),
      UserRole.driver => _resolveDriverSignInProfile(uid),
      null => _resolveProfileWhenRoleUnknown(
        uid: uid,
        hasAdmin: hasAdmin,
        hasDriver: hasDriver,
        adminSnapshot: adminSnapshot,
        driverSnapshot: driverSnapshot,
      ),
    };
  }

  AppUser? _resolveProfileWhenRoleUnknown({
    required String uid,
    required bool hasAdmin,
    required bool hasDriver,
    required DocumentSnapshot<Map<String, dynamic>> adminSnapshot,
    required DocumentSnapshot<Map<String, dynamic>> driverSnapshot,
  }) {
    if (hasAdmin && hasDriver) {
      return null;
    }
    if (hasAdmin) {
      return AppUser.fromAdminDoc(uid: uid, data: adminSnapshot.data() ?? {});
    }
    if (hasDriver) {
      return AppUser.fromDriverDoc(uid: uid, data: driverSnapshot.data() ?? {});
    }
    return null;
  }

  Future<AppUser?> _resolveProfileForRole(
    String uid,
    UserRole expectedRole,
  ) async {
    return switch (expectedRole) {
      UserRole.admin => _resolveAdminSignInProfile(uid),
      UserRole.driver => _resolveDriverSignInProfile(uid),
    };
  }

  Future<AppUser?> _resolveAdminSignInProfile(String uid) async {
    final adminSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.admin,
      uid: uid,
      fromServer: true,
    );
    if (adminSnapshot.exists) {
      return AppUser.fromAdminDoc(uid: uid, data: adminSnapshot.data() ?? {});
    }

    final driverSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.drivers,
      uid: uid,
    );
    if (driverSnapshot.exists) {
      throw roleMismatchFailure(UserRole.admin);
    }
    return null;
  }

  Future<AppUser?> _resolveDriverSignInProfile(String uid) async {
    final driverSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.drivers,
      uid: uid,
    );
    if (driverSnapshot.exists) {
      return AppUser.fromDriverDoc(uid: uid, data: driverSnapshot.data() ?? {});
    }

    final adminSnapshot = await _getProfileDoc(
      collection: FirestoreCollections.admin,
      uid: uid,
    );
    if (adminSnapshot.exists) {
      throw roleMismatchFailure(UserRole.driver);
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getProfileDoc({
    required String collection,
    required String uid,
    bool fromServer = false,
  }) {
    final docRef = _firestore.collection(collection).doc(uid);
    return fromServer
        ? docRef.get(const GetOptions(source: Source.server))
        : docRef.get();
  }

  Future<void> _clearGuestStudentSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SessionStorageKeys.guestStudent, false);
  }

  Future<void> _persistSignedInRole(UserRole role) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(SessionStorageKeys.signedInRole, role.name);
  }

  Future<UserRole?> _readSignedInRole() async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(SessionStorageKeys.signedInRole)) {
      'admin' => UserRole.admin,
      'driver' => UserRole.driver,
      _ => null,
    };
  }

  Future<void> _clearSignedInRole() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(SessionStorageKeys.signedInRole);
  }

  void _assertEmailMatchesProfile(String? authEmail, String profileEmail) {
    final normalizedAuthEmail = authEmail?.trim().toLowerCase();
    final normalizedProfileEmail = profileEmail.trim().toLowerCase();
    if (normalizedProfileEmail.isEmpty || normalizedAuthEmail == null) {
      return;
    }
    if (normalizedAuthEmail != normalizedProfileEmail) {
      throw unauthorizedFailure;
    }
  }
}
