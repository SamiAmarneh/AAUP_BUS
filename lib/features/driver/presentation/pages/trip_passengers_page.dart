import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../student/domain/models/reservation_profile.dart';
import '../../../student/domain/reservation_status.dart';
import '../../data/driver_reservation_providers.dart';

class TripPassengersPage extends ConsumerWidget {
  const TripPassengersPage({
    super.key,
    required this.tripId,
    this.routeLabel,
  });

  final String tripId;
  final String? routeLabel;

  static const Color _primaryGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(driverTripPassengersProvider(tripId));
    final appBarTitle = routeLabel?.trim().isNotEmpty == true
        ? routeLabel!.trim()
        : 'Passengers';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildMessageBanner(
          context,
          'Could not load passenger bookings.',
          isError: true,
        ),
        data: (reservations) {
          if (reservations.isEmpty) {
            return _buildMessageBanner(
              context,
              'No passengers booked yet.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(25),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _PassengerCard(reservation: reservations[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBanner(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isError ? const Color(0xFFC62828) : const Color(0xFF6D4C41),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({required this.reservation});

  final ReservationProfile reservation;

  @override
  Widget build(BuildContext context) {
    final coordinates = reservation.pickupCoordinates;
    final hasCoordinates = coordinates != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: TripPassengersPage._primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reservation.phoneNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ),
              _ReservationStatusChip(status: reservation.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF757575),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reservation.pickupLocation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _callPassenger(context, reservation.phoneNumber),
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Call'),
                style: TextButton.styleFrom(
                  foregroundColor: TripPassengersPage._primaryGreen,
                  padding: EdgeInsets.zero,
                ),
              ),
              if (hasCoordinates) ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _openPickupOnMaps(context, coordinates),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open in Maps'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _callPassenger(BuildContext context, String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (launched || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the phone dialer.')),
    );
  }

  Future<void> _openPickupOnMaps(
    BuildContext context,
    GeoPoint coordinates,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${coordinates.latitude},${coordinates.longitude}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (launched || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open maps for this pickup.')),
    );
  }
}

class _ReservationStatusChip extends StatelessWidget {
  const _ReservationStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = ReservationStatus.displayLabel(status);
    final isBoarded = status == ReservationStatus.boarded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBoarded
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isBoarded
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE65100),
        ),
      ),
    );
  }
}
