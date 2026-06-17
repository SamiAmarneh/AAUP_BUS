import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';
import '../domain/route_profile.dart';
import '../domain/route_status.dart';

class RouteRepository {
  RouteRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RouteProfile>> watchActiveRoutes() {
    return _firestore
        .collection(FirestoreCollections.routes)
        .where('status', isEqualTo: RouteStatus.active)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RouteProfile.fromFirestore(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<List<RouteProfile>> fetchActiveRoutes() async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.routes)
          .where('status', isEqualTo: RouteStatus.active)
          .get();

      return snapshot.docs
          .map(
            (doc) => RouteProfile.fromFirestore(
              id: doc.id,
              data: doc.data(),
            ),
          )
          .toList();
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<RouteProfile?> fetchRouteById(String routeId) async {
    if (routeId.trim().isEmpty) {
      return null;
    }

    try {
      final snapshot =
          await _firestore.collection(FirestoreCollections.routes).doc(routeId).get();

      if (!snapshot.exists) {
        return null;
      }

      return RouteProfile.fromFirestore(
        id: snapshot.id,
        data: snapshot.data() ?? {},
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<RouteProfile> createRoute({
    required String routeName,
    required String startLocation,
    required String endLocation,
    required double price,
  }) async {
    _validateRouteInput(
      routeName: routeName,
      startLocation: startLocation,
      endLocation: endLocation,
      price: price,
    );

    final trimmedRouteName = routeName.trim();
    final trimmedStartLocation = startLocation.trim();
    final trimmedEndLocation = endLocation.trim();

    try {
      final docRef =
          await _firestore.collection(FirestoreCollections.routes).add({
        'route_name': trimmedRouteName,
        'start_location': trimmedStartLocation,
        'end_location': trimmedEndLocation,
        'status': RouteStatus.active,
        'price': price,
      });

      return RouteProfile(
        id: docRef.id,
        routeName: trimmedRouteName,
        startLocation: trimmedStartLocation,
        endLocation: trimmedEndLocation,
        status: RouteStatus.active,
        price: price,
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<void> updateRoute({
    required String id,
    required String routeName,
    required String startLocation,
    required String endLocation,
    required double price,
  }) async {
    _validateRouteInput(
      routeName: routeName,
      startLocation: startLocation,
      endLocation: endLocation,
      price: price,
    );

    try {
      await _firestore.collection(FirestoreCollections.routes).doc(id).update({
        'route_name': routeName.trim(),
        'start_location': startLocation.trim(),
        'end_location': endLocation.trim(),
        'price': price,
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<void> deactivateRoute(String id) async {
    try {
      await _firestore.collection(FirestoreCollections.routes).doc(id).update({
        'status': RouteStatus.inactive,
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  void _validateRouteInput({
    required String routeName,
    required String startLocation,
    required String endLocation,
    required double price,
  }) {
    if (routeName.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Route name is required.',
      );
    }

    if (startLocation.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Start location is required.',
      );
    }

    if (endLocation.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'End location is required.',
      );
    }

    if (price <= 0) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Price must be greater than zero.',
      );
    }
  }
}
