import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_exceptions.dart';
import '../../../core/auth/auth_providers.dart';
import '../../bus_company/data/bus_providers.dart';
import '../../bus_company/data/route_providers.dart';
import '../../bus_company/domain/route_profile.dart';
import '../domain/trip_history_constants.dart';
import '../domain/trip_history_item.dart';
import '../domain/trip_profile.dart';
import 'trip_repository.dart';

class DriverTripHistoryState {
  const DriverTripHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.lastDocument,
  });

  final List<TripHistoryItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  DriverTripHistoryState copyWith({
    List<TripHistoryItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool clearError = false,
    bool clearLastDocument = false,
  }) {
    return DriverTripHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
    );
  }
}

class DriverTripHistoryNotifier extends Notifier<DriverTripHistoryState> {
  @override
  DriverTripHistoryState build() {
    return const DriverTripHistoryState();
  }

  Future<void> loadInitial() => _loadPage(reset: true);

  Future<void> refresh() => loadInitial();

  Future<void> loadMore() async {
    final currentState = state;
    if (!currentState.hasMore ||
        currentState.isLoadingMore ||
        currentState.isLoading) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true, clearError: true);
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) {
      state = const DriverTripHistoryState(
        items: [],
        isLoading: false,
        hasMore: false,
      );
      return;
    }

    if (reset) {
      state = const DriverTripHistoryState(isLoading: true);
    }

    try {
      final tripRepository = TripRepository(
        busRepository: ref.read(busRepositoryProvider),
      );
      final pageResult = await tripRepository.fetchTripHistoryPage(
        driverUid: profile.uid,
        limit: TripHistoryConstants.pageSize,
        startAfter: reset ? null : state.lastDocument,
      );

      var trips = pageResult.trips;
      if (reset) {
        trips = await _mergeActiveTripOnFirstPage(
          tripRepository: tripRepository,
          driverUid: profile.uid,
          pageTrips: trips,
        );
      }

      final newItems = await _resolveHistoryItems(
        trips: trips,
        driverUid: profile.uid,
      );

      final mergedItems = reset
          ? newItems
          : _dedupeAndAppend(state.items, newItems);

      state = DriverTripHistoryState(
        items: mergedItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: pageResult.hasMore,
        lastDocument: pageResult.lastDocument,
      );
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: 'Could not load trip history. Please try again.',
      );
    }
  }

  Future<List<TripProfile>> _mergeActiveTripOnFirstPage({
    required TripRepository tripRepository,
    required String driverUid,
    required List<TripProfile> pageTrips,
  }) async {
    final activeTrip = await tripRepository.fetchActiveTripForDriver(driverUid);
    if (activeTrip == null) {
      return pageTrips;
    }

    final activeTripInPage = pageTrips.any((trip) => trip.id == activeTrip.id);
    if (activeTripInPage) {
      return pageTrips;
    }

    return [activeTrip, ...pageTrips];
  }

  Future<List<TripHistoryItem>> _resolveHistoryItems({
    required List<TripProfile> trips,
    required String driverUid,
  }) async {
    if (trips.isEmpty) {
      return [];
    }

    final busRepository = ref.read(busRepositoryProvider);
    final routeRepository = ref.read(routeRepositoryProvider);
    final bus = await busRepository.fetchBusForDriver(driverUid);
    final busName = bus?.name ?? '—';
    final routeCache = <String, RouteProfile>{};

    final historyItems = <TripHistoryItem>[];
    for (final trip in trips) {
      final cachedRoute = routeCache[trip.routeId];
      final route =
          cachedRoute ?? await routeRepository.fetchRouteById(trip.routeId);
      if (route != null) {
        routeCache[trip.routeId] = route;
      }

      historyItems.add(
        TripHistoryItem(
          tripId: trip.id,
          status: trip.status,
          statusLabel: trip.statusLabel,
          isActive: trip.isActive,
          routeLabel: route == null
              ? 'Unknown route'
              : '${route.startLocation} → ${route.endLocation}',
          busName: busName,
          departureTime: trip.departureTime,
          arrivalTime: trip.arrivalTime,
        ),
      );
    }

    return historyItems;
  }

  List<TripHistoryItem> _dedupeAndAppend(
    List<TripHistoryItem> existing,
    List<TripHistoryItem> incoming,
  ) {
    final existingIds = existing.map((item) => item.tripId).toSet();
    final uniqueIncoming = incoming
        .where((item) => !existingIds.contains(item.tripId))
        .toList();
    return [...existing, ...uniqueIncoming];
  }
}

final driverTripHistoryNotifierProvider =
    NotifierProvider<DriverTripHistoryNotifier, DriverTripHistoryState>(
  DriverTripHistoryNotifier.new,
);
