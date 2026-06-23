import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/firestore_collections.dart';
import '../../../core/reservation/reservation_qr_data_codec.dart';
import '../../../core/validation/phone_number_validator.dart';
import '../../bus_company/data/bus_repository.dart';
import '../../bus_company/data/route_repository.dart';
import '../../trips/domain/trip_profile.dart';
import '../../trips/domain/trip_status.dart';
import '../domain/models/payment_profile.dart';
import '../domain/models/reservation_details.dart';
import '../domain/models/reservation_profile.dart';
import '../domain/models/trip_model.dart';
import '../domain/payment_status.dart';
import '../domain/reservation_status.dart';

class ReservationRepository {
  ReservationRepository({
    FirebaseFirestore? firestore,
    BusRepository? busRepository,
    RouteRepository? routeRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _busRepository = busRepository ?? BusRepository(firestore: firestore),
       _routeRepository =
           RouteRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final BusRepository _busRepository;
  final RouteRepository _routeRepository;

  static const int _whereInBatchSize = 10;

  Future<ReservationDetails> createBooking({
    required Trip trip,
    required String phoneNumber,
    String? pickupLocation,
    GeoPoint? pickupCoordinates,
  }) async {
    final tripId = trip.id;
    if (tripId == null || tripId.isEmpty) {
      throw const AuthFailure(AuthFailureType.unknown, 'Trip is required.');
    }

    final normalizedPhone = PhoneNumberValidator.normalizePhoneNumber(
      phoneNumber,
    );
    if (!PhoneNumberValidator.validatePhoneNumber(normalizedPhone)) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Please enter a valid Palestinian phone number.',
      );
    }

    final tripRef = _tripReference(tripId);
    final reservationRef = _firestore
        .collection(FirestoreCollections.reservation)
        .doc();
    final paymentRef = _firestore.collection(FirestoreCollections.payment).doc();

    final qrData = ReservationQrDataCodec.encodeReservationQrData(
      id: reservationRef.id,
      trip: trip.route,
      bus: trip.company,
    );

    try {
      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) {
          throw const AuthFailure(AuthFailureType.unknown, 'Trip not found.');
        }

        final tripData = tripSnapshot.data() ?? {};
        final tripProfile = TripProfile.fromFirestore(
          id: tripSnapshot.id,
          data: tripData,
        );

        if (!TripStatus.activeStatuses.contains(tripProfile.status)) {
          throw const AuthFailure(
            AuthFailureType.unknown,
            'This trip is no longer available for booking.',
          );
        }

        if (tripProfile.totalPassengers >= trip.totalSeats) {
          throw const AuthFailure(
            AuthFailureType.unknown,
            'This trip is fully booked.',
          );
        }

        final resolvedPickup = _resolvePickupForBooking(
          tripStatus: tripProfile.status,
          routeStartLocation: trip.from,
          pickupLocation: pickupLocation,
          pickupCoordinates: pickupCoordinates,
        );

        final reservationData = <String, dynamic>{
          'trip_id': tripRef,
          'reservation_time': FieldValue.serverTimestamp(),
          'phone_number': normalizedPhone,
          'qr_data': qrData,
          'status': ReservationStatus.waitingBoarding,
          'pickup_location': resolvedPickup.location,
        };

        if (resolvedPickup.coordinates != null) {
          reservationData['pickup_coordinates'] = resolvedPickup.coordinates;
        }

        transaction.set(reservationRef, reservationData);

        transaction.set(paymentRef, {
          'reservation_id': reservationRef,
          'amount': trip.price.toDouble(),
          'payment_status': PaymentStatus.completed,
          'payment_time': FieldValue.serverTimestamp(),
        });

        transaction.update(tripRef, {
          'total_passengers': tripProfile.totalPassengers + 1,
        });
      });
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }

    final reservation = await _fetchReservationProfile(reservationRef.id);
    final payment = await _fetchPaymentForReservation(reservationRef.id);

    return ReservationDetails(
      reservation: reservation,
      payment: payment,
      tripRoute: trip.route,
      tripFrom: trip.from,
      tripTo: trip.to,
      busName: trip.company,
      tripStatus: trip.status ?? TripStatus.waitingPassengers,
      tripPrice: trip.price.toDouble(),
    );
  }

  Future<List<ReservationDetails>> fetchReservationsByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return [];
    }

    final uniqueIds = ids.toSet().toList();
    final results = <ReservationDetails>[];

    for (var index = 0; index < uniqueIds.length; index += _whereInBatchSize) {
      final batch = uniqueIds.skip(index).take(_whereInBatchSize).toList();
      final batchResults = await _fetchReservationBatch(batch);
      results.addAll(batchResults);
    }

    results.sort((left, right) {
      final leftTime = left.reservationTime;
      final rightTime = right.reservationTime;
      if (leftTime == null && rightTime == null) {
        return 0;
      }
      if (leftTime == null) {
        return 1;
      }
      if (rightTime == null) {
        return -1;
      }
      return rightTime.compareTo(leftTime);
    });

    return results;
  }

  Future<ReservationDetails?> fetchReservationById(String id) async {
    if (id.trim().isEmpty) {
      return null;
    }

    final results = await fetchReservationsByIds([id]);
    return results.isEmpty ? null : results.first;
  }

  Future<List<ReservationDetails>> fetchActiveReservationsByIds(
    List<String> ids,
  ) async {
    final reservations = await fetchReservationsByIds(ids);
    return reservations
        .where(
          (details) => TripStatus.activeStatuses.contains(details.tripStatus),
        )
        .toList();
  }

  Future<int> countBookingsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.reservation)
          .where('reservation_time', isGreaterThanOrEqualTo: startOfDay)
          .where('reservation_time', isLessThan: startOfNextDay)
          .get();

      return snapshot.docs.length;
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<List<ReservationDetails>> _fetchReservationBatch(
    List<String> ids,
  ) async {
    final details = <ReservationDetails>[];

    for (final id in ids) {
      try {
        final snapshot = await _firestore
            .collection(FirestoreCollections.reservation)
            .doc(id)
            .get();

        if (!snapshot.exists) {
          continue;
        }

        final joined = await _joinReservationData(
          ReservationProfile.fromFirestore(
            id: snapshot.id,
            data: snapshot.data()!,
          ),
        );
        if (joined != null) {
          details.add(joined);
        }
      } on FirebaseException catch (exception) {
        throw mapFirestoreException(exception);
      }
    }

    return details;
  }

  Future<ReservationProfile> _fetchReservationProfile(String id) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.reservation)
          .doc(id)
          .get();

      if (!snapshot.exists) {
        throw const AuthFailure(
          AuthFailureType.unknown,
          'Reservation not found.',
        );
      }

      return ReservationProfile.fromFirestore(
        id: snapshot.id,
        data: snapshot.data() ?? {},
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<PaymentProfile> _fetchPaymentForReservation(
    String reservationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.payment)
          .where('reservation_id', isEqualTo: _reservationReference(reservationId))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw const AuthFailure(AuthFailureType.unknown, 'Payment not found.');
      }

      final doc = snapshot.docs.first;
      return PaymentProfile.fromFirestore(id: doc.id, data: doc.data());
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  Future<ReservationDetails?> _joinReservationData(
    ReservationProfile reservation,
  ) async {
    final tripId = reservation.tripId;
    if (tripId.isEmpty) {
      return null;
    }

    try {
      final tripSnapshot = await _firestore
          .collection(FirestoreCollections.trips)
          .doc(tripId)
          .get();

      if (!tripSnapshot.exists) {
        return null;
      }

      final tripProfile = TripProfile.fromFirestore(
        id: tripSnapshot.id,
        data: tripSnapshot.data() ?? {},
      );

      final bus = await _busRepository.fetchBusById(tripProfile.busId);
      final route = await _routeRepository.fetchRouteById(tripProfile.routeId);

      PaymentProfile payment;
      try {
        payment = await _fetchPaymentForReservation(reservation.id);
      } catch (_) {
        payment = PaymentProfile(
          id: '',
          reservationId: reservation.id,
          amount: tripProfile.price,
          paymentStatus: PaymentStatus.completed,
        );
      }

      if (bus == null || route == null) {
        return null;
      }

      return ReservationDetails(
        reservation: reservation,
        payment: payment,
        tripRoute: '${route.startLocation} → ${route.endLocation}',
        tripFrom: route.startLocation,
        tripTo: route.endLocation,
        busName: bus.name,
        tripStatus: tripProfile.status,
        tripPrice: tripProfile.price,
      );
    } on FirebaseException catch (exception) {
      throw mapFirestoreException(exception);
    }
  }

  DocumentReference<Map<String, dynamic>> _tripReference(String tripId) {
    return _firestore.collection(FirestoreCollections.trips).doc(tripId);
  }

  DocumentReference<Map<String, dynamic>> _reservationReference(
    String reservationId,
  ) {
    return _firestore
        .collection(FirestoreCollections.reservation)
        .doc(reservationId);
  }

  _ResolvedPickup _resolvePickupForBooking({
    required String tripStatus,
    required String routeStartLocation,
    String? pickupLocation,
    GeoPoint? pickupCoordinates,
  }) {
    if (tripStatus == TripStatus.waitingPassengers) {
      final startLocation = routeStartLocation.trim();
      if (startLocation.isEmpty) {
        throw const AuthFailure(
          AuthFailureType.unknown,
          'Route start location is missing for this trip.',
        );
      }
      return _ResolvedPickup(location: startLocation);
    }

    if (tripStatus == TripStatus.onTheWay) {
      final trimmedLocation = pickupLocation?.trim() ?? '';
      if (trimmedLocation.isEmpty) {
        throw const AuthFailure(
          AuthFailureType.unknown,
          'Please specify your pickup location.',
        );
      }
      return _ResolvedPickup(
        location: trimmedLocation,
        coordinates: pickupCoordinates,
      );
    }

    throw const AuthFailure(
      AuthFailureType.unknown,
      'This trip is no longer available for booking.',
    );
  }
}

class _ResolvedPickup {
  const _ResolvedPickup({
    required this.location,
    this.coordinates,
  });

  final String location;
  final GeoPoint? coordinates;
}
