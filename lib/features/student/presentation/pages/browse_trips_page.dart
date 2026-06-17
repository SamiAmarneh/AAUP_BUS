import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro2/features/bus_company/domain/route_profile.dart';
import 'package:pro2/features/student/data/student_route_providers.dart';
import 'package:pro2/features/student/data/student_trip_providers.dart';
import 'package:pro2/features/student/domain/models/trip_model.dart';
import 'package:pro2/features/trips/domain/trip_details.dart';
import 'package:pro2/features/trips/domain/trip_status.dart';

import 'trip_details_page.dart';

class BrowseTripsPage extends ConsumerWidget {
  const BrowseTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRouteId = ref.watch(selectedRouteFilterProvider);
    final routesAsync = ref.watch(studentActiveRoutesProvider);
    final tripsAsync = ref.watch(studentAvailableTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            routesAsync.when(
              data: (routes) => _buildRouteFilters(
                ref: ref,
                routes: routes,
                selectedRouteId: selectedRouteId,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: tripsAsync.when(
                data: (tripDetails) => _buildTripsList(context, tripDetails),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load trips. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Available Trips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Filter by route',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFilters({
    required WidgetRef ref,
    required List<RouteProfile> routes,
    required String? selectedRouteId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildRouteChip(
              ref: ref,
              label: 'All Routes',
              routeId: null,
              isSelected: selectedRouteId == null,
            ),
            ...routes.map(
              (route) => _buildRouteChip(
                ref: ref,
                label: route.routeName.isNotEmpty
                    ? route.routeName
                    : '${route.startLocation} → ${route.endLocation}',
                routeId: route.id,
                isSelected: selectedRouteId == route.id,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteChip({
    required WidgetRef ref,
    required String label,
    required String? routeId,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(selectedRouteFilterProvider.notifier).state = routeId;
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF62758A),
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, List<TripDetails> tripDetails) {
    if (tripDetails.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No trips available right now.',
            style: TextStyle(fontSize: 16, color: Color(0xFF62758A)),
          ),
        ),
      );
    }

    final groupedTrips = <String, List<Trip>>{};
    for (final details in tripDetails) {
      final trip = Trip.fromTripDetails(details);
      groupedTrips.putIfAbsent(trip.city, () => []).add(trip);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ...groupedTrips.entries.map(
          (entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F3A57),
                          ),
                        ),
                        Text(
                          '${entry.value.length} trips available',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF62758A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ...entry.value.map(
                (trip) => _buildTripCard(context: context, trip: trip),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTripCard({
    required BuildContext context,
    required Trip trip,
  }) {
    final statusLabel = trip.status != null
        ? TripStatus.displayLabel(trip.status!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: Color(0xFF62758A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            trip.company,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF62758A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₪ ${trip.price}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'per seat',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A86F).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00A86F),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 8, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(fontSize: 11, color: Color(0xFF62758A)),
                    ),
                    Text(
                      trip.from,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(color: Colors.grey[300], thickness: 1.5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A86F),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 8, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(fontSize: 11, color: Color(0xFF62758A)),
                    ),
                    Text(
                      trip.to,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.event_seat,
                size: 18,
                color: Color(0xFF00A86F),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capacity',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF62758A),
                    ),
                  ),
                  Text(
                    '${trip.availableSeats}/${trip.totalSeats}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A86F),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripDetailsPage(trip: trip),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Book Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
