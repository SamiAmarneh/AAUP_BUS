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

  Future<RouteProfile> createRoute({
    required String routeName,
    required String startLocation,
    required String endLocation,
  }) async {
    _validateRouteInput(
      routeName: routeName,
      startLocation: startLocation,
      endLocation: endLocation,
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
      });

      return RouteProfile(
        id: docRef.id,
        routeName: trimmedRouteName,
        startLocation: trimmedStartLocation,
        endLocation: trimmedEndLocation,
        status: RouteStatus.active,
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
  }) async {
    _validateRouteInput(
      routeName: routeName,
      startLocation: startLocation,
      endLocation: endLocation,
    );

    try {
      await _firestore.collection(FirestoreCollections.routes).doc(id).update({
        'route_name': routeName.trim(),
        'start_location': startLocation.trim(),
        'end_location': endLocation.trim(),
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
  }
}
