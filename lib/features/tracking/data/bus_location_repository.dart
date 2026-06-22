import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';
import '../domain/bus_location_profile.dart';

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

  Future<BusLocationProfile?> fetchLatestLocationForBus(String busId) async {
    _validateBusId(busId);
    final busRef = _busReference(busId);

    try {
      return await _fetchLatestLocationIndexed(busRef: busRef);
    } on FirebaseException catch (exception) {
      final isMissingIndex =
          exception.code == 'failed-precondition' &&
          (exception.message?.contains('index') ?? false);
      if (isMissingIndex) {
        return _fetchLatestLocationClientSide(busRef: busRef);
      }

      throw mapFirestoreException(exception);
    }
  }

  Future<BusLocationProfile?> _fetchLatestLocationIndexed({
    required DocumentReference<Map<String, dynamic>> busRef,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.busLocation)
        .where('bus_id', isEqualTo: busRef)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return BusLocationProfile.fromFirestore(
      data: snapshot.docs.first.data(),
    );
  }

  Future<BusLocationProfile?> _fetchLatestLocationClientSide({
    required DocumentReference<Map<String, dynamic>> busRef,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.busLocation)
          .where('bus_id', isEqualTo: busRef)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      BusLocationProfile? latest;
      for (final doc in snapshot.docs) {
        final profile = BusLocationProfile.fromFirestore(data: doc.data());
        if (latest == null ||
            profile.timestamp.isAfter(latest.timestamp)) {
          latest = profile;
        }
      }

      return latest;
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<Map<String, BusLocationProfile>> fetchLatestLocationsForBuses(
    List<String> busIds,
  ) async {
    final uniqueBusIds = busIds
        .map((busId) => busId.trim())
        .where((busId) => busId.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueBusIds.isEmpty) {
      return {};
    }

    final results = await Future.wait(
      uniqueBusIds.map((busId) async {
        try {
          final location = await fetchLatestLocationForBus(busId);
          return MapEntry(busId, location);
        } catch (_) {
          return MapEntry<String, BusLocationProfile?>(busId, null);
        }
      }),
    );

    return Map.fromEntries(
      results
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value!)),
    );
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
