import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';
import '../../../firebase_options.dart';
import '../domain/driver_profile.dart';
import '../domain/driver_status.dart';

const int minDriverPasswordLength = 6;
const String secondaryFirebaseAppName = 'DriverCreationApp';

class DriverRepository {
  DriverRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  FirebaseAuth? _secondaryAuth;

  Stream<List<DriverProfile>> watchActiveDrivers() {
    return _firestore
        .collection(FirestoreCollections.drivers)
        .where('status', isEqualTo: DriverStatus.active)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DriverProfile.fromFirestore(
                  uid: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<DriverProfile> createDriver({
    required String email,
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    _validateCreateInput(
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      password: password,
    );

    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final trimmedPhone = phoneNumber.trim();
    final secondaryAuth = await _getSecondaryAuth();

    UserCredential credential;
    try {
      credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    }

    final uid = credential.user?.uid;
    if (uid == null) {
      await secondaryAuth.signOut();
      throw unauthorizedFailure;
    }

    final profile = DriverProfile(
      uid: uid,
      email: trimmedEmail,
      name: trimmedName,
      phoneNumber: trimmedPhone,
      status: DriverStatus.active,
    );

    try {
      await _firestore
          .collection(FirestoreCollections.drivers)
          .doc(uid)
          .set(_toFirestoreMap(profile));
    } on FirebaseException catch (exception) {
      await _deleteCreatedAuthUser(credential.user);
      await secondaryAuth.signOut();
      throw mapFirestoreException(exception);
    }

    await secondaryAuth.signOut();

    return profile;
  }

  Future<void> deactivateDriver(String uid) async {
    try {
      await _firestore
          .collection(FirestoreCollections.drivers)
          .doc(uid)
          .update({'status': DriverStatus.inactive});
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    if (_secondaryAuth != null) {
      return _secondaryAuth!;
    }

    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app(secondaryFirebaseAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: secondaryFirebaseAppName,
        options: DefaultFirebaseOptions.android,
      );
    }

    _secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    return _secondaryAuth!;
  }

  Future<void> _deleteCreatedAuthUser(User? user) async {
    if (user == null) {
      return;
    }
    try {
      await user.delete();
    } catch (_) {
      // Best-effort cleanup; orphaned Auth user may require manual removal.
    }
  }

  void _validateCreateInput({
    required String email,
    required String name,
    required String phoneNumber,
    required String password,
  }) {
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final trimmedPhone = phoneNumber.trim();

    if (trimmedEmail.isEmpty ||
        trimmedName.isEmpty ||
        trimmedPhone.isEmpty ||
        password.isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'All fields are required.',
      );
    }

    if (!_isValidEmail(trimmedEmail)) {
      throw const AuthFailure(
        AuthFailureType.invalidCredentials,
        'Enter a valid email address.',
      );
    }

    if (password.length < minDriverPasswordLength) {
      throw AuthFailure(
        AuthFailureType.invalidCredentials,
        'Password must be at least $minDriverPasswordLength characters.',
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  Map<String, dynamic> _toFirestoreMap(DriverProfile profile) {
    return {
      'email': profile.email,
      'name': profile.name,
      'phone_number': profile.phoneNumber,
      'status': profile.status,
    };
  }
}
