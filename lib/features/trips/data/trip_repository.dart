import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';
import '../../bus_company/data/bus_repository.dart';
import '../domain/trip_profile.dart';
import '../domain/trip_status.dart';

class TripRepository {
  TripRepository({
    FirebaseFirestore? firestore,
    BusRepository? busRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _busRepository = busRepository ?? BusRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final BusRepository _busRepository;

  Stream<TripProfile?> watchActiveTripForDriver(String driverUid) {
    final driverRef = _driverReference(driverUid);

    return _firestore
        .collection(FirestoreCollections.trips)
        .where('driver_id', isEqualTo: driverRef)
        .where('status', whereIn: TripStatus.activeStatuses)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          final doc = snapshot.docs.first;
          return TripProfile.fromFirestore(id: doc.id, data: doc.data());
        });
  }

  Stream<List<TripProfile>> watchTripHistoryForDriver(String driverUid) {
    final driverRef = _driverReference(driverUid);

    return _firestore
        .collection(FirestoreCollections.trips)
        .where('driver_id', isEqualTo: driverRef)
        .snapshots()
        .map((snapshot) {
          final trips = snapshot.docs
              .map(
                (doc) => TripProfile.fromFirestore(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .toList();
          return _sortTripHistory(trips);
        });
  }

  List<TripProfile> _sortTripHistory(List<TripProfile> trips) {
    final sortedTrips = List<TripProfile>.from(trips);
    sortedTrips.sort((first, second) {
      final firstActive = first.isActive;
      final secondActive = second.isActive;
      if (firstActive != secondActive) {
        return firstActive ? -1 : 1;
      }

      final firstSortKey = first.arrivalTime ?? first.departureTime;
      final secondSortKey = second.arrivalTime ?? second.departureTime;

      if (firstSortKey == null && secondSortKey == null) {
        return 0;
      }
      if (firstSortKey == null) {
        return 1;
      }
      if (secondSortKey == null) {
        return -1;
      }

      return secondSortKey.compareTo(firstSortKey);
    });
    return sortedTrips;
  }

  Future<TripProfile> createTrip({
    required String driverUid,
    required String routeId,
  }) async {
    _validateDriverUid(driverUid);
    _validateRouteId(routeId);

    final activeTrip = await _fetchActiveTrip(driverUid);
    if (activeTrip != null) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'You already have an active trip.',
      );
    }

    final assignedBus = await _busRepository.fetchBusForDriver(driverUid);
    if (assignedBus == null) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'No bus assigned. Contact your administrator.',
      );
    }

    try {
      final docRef = await _firestore.collection(FirestoreCollections.trips).add({
        'driver_id': _driverReference(driverUid),
        'bus_id': _busReference(assignedBus.id),
        'route_id': _routeReference(routeId),
        'status': TripStatus.waitingPassengers,
      });

      return TripProfile(
        id: docRef.id,
        driverUid: driverUid,
        busId: assignedBus.id,
        routeId: routeId,
        status: TripStatus.waitingPassengers,
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<void> startTrip(String tripId) async {
    _validateTripId(tripId);

    final trip = await _fetchTrip(tripId);
    if (trip.status != TripStatus.waitingPassengers) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Only trips waiting for passengers can be started.',
      );
    }

    try {
      await _firestore.collection(FirestoreCollections.trips).doc(tripId).update({
        'status': TripStatus.onTheWay,
        'departure_time': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<void> completeTrip(String tripId) async {
    _validateTripId(tripId);

    final trip = await _fetchTrip(tripId);
    if (trip.status != TripStatus.onTheWay) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Only trips on the way can be marked as arrived.',
      );
    }

    try {
      await _firestore.collection(FirestoreCollections.trips).doc(tripId).update({
        'status': TripStatus.arrived,
        'arrival_time': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<TripProfile?> _fetchActiveTrip(String driverUid) async {
    final driverRef = _driverReference(driverUid);

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.trips)
          .where('driver_id', isEqualTo: driverRef)
          .where('status', whereIn: TripStatus.activeStatuses)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return TripProfile.fromFirestore(id: doc.id, data: doc.data());
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<TripProfile> _fetchTrip(String tripId) async {
    try {
      final snapshot =
          await _firestore.collection(FirestoreCollections.trips).doc(tripId).get();

      if (!snapshot.exists) {
        throw const AuthFailure(
          AuthFailureType.unknown,
          'Trip not found.',
        );
      }

      return TripProfile.fromFirestore(
        id: snapshot.id,
        data: snapshot.data() ?? {},
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  DocumentReference<Map<String, dynamic>> _driverReference(String driverUid) {
    return _firestore.collection(FirestoreCollections.drivers).doc(driverUid);
  }

  DocumentReference<Map<String, dynamic>> _busReference(String busId) {
    return _firestore.collection(FirestoreCollections.buses).doc(busId);
  }

  DocumentReference<Map<String, dynamic>> _routeReference(String routeId) {
    return _firestore.collection(FirestoreCollections.routes).doc(routeId);
  }

  void _validateDriverUid(String driverUid) {
    if (driverUid.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Driver is required.',
      );
    }
  }

  void _validateRouteId(String routeId) {
    if (routeId.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Route is required.',
      );
    }
  }

  void _validateTripId(String tripId) {
    if (tripId.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Trip is required.',
      );
    }
  }
}
