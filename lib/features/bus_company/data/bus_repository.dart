import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';
import '../domain/bus_profile.dart';
import '../domain/bus_status.dart';

class BusRepository {
  BusRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<BusProfile>> watchActiveBuses() {
    return _firestore
        .collection(FirestoreCollections.buses)
        .where('status', isEqualTo: BusStatus.active)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BusProfile.fromFirestore(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<BusProfile> createBus({
    required String name,
    required int capacity,
    required String driverUid,
  }) async {
    _validateBusInput(
      name: name,
      capacity: capacity,
      driverUid: driverUid,
    );

    final trimmedName = name.trim();
    final driverRef = _driverReference(driverUid);

    try {
      final docRef = await _firestore.collection(FirestoreCollections.buses).add({
        'name': trimmedName,
        'capacity': capacity,
        'driver_id': driverRef,
        'status': BusStatus.active,
      });

      return BusProfile(
        id: docRef.id,
        name: trimmedName,
        capacity: capacity,
        driverUid: driverUid,
        status: BusStatus.active,
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<void> updateBus({
    required String id,
    required String name,
    required int capacity,
    required String driverUid,
  }) async {
    _validateBusInput(
      name: name,
      capacity: capacity,
      driverUid: driverUid,
    );

    try {
      await _firestore.collection(FirestoreCollections.buses).doc(id).update({
        'name': name.trim(),
        'capacity': capacity,
        'driver_id': _driverReference(driverUid),
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<void> deactivateBus(String id) async {
    try {
      await _firestore.collection(FirestoreCollections.buses).doc(id).update({
        'status': BusStatus.inactive,
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  DocumentReference<Map<String, dynamic>> _driverReference(String driverUid) {
    return _firestore.collection(FirestoreCollections.drivers).doc(driverUid);
  }

  void _validateBusInput({
    required String name,
    required int capacity,
    required String driverUid,
  }) {
    if (name.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Bus name is required.',
      );
    }

    if (capacity <= 0) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Capacity must be greater than zero.',
      );
    }

    if (driverUid.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Assigned driver is required.',
      );
    }
  }
}
