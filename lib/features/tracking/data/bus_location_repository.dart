import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';

class BusLocationRepository {
  BusLocationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> publishLocation({
    required String busId,
    required double latitude,
    required double longitude,
  }) async {
    _validateBusId(busId);

    try {
      await _firestore.collection(FirestoreCollections.busLocation).add({
        'bus_id': _busReference(busId),
        'location': GeoPoint(latitude, longitude),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  DocumentReference<Map<String, dynamic>> _busReference(String busId) {
    return _firestore.collection(FirestoreCollections.buses).doc(busId);
  }

  void _validateBusId(String busId) {
    if (busId.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Bus id is required to publish location.',
      );
    }
  }
}
