import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_exceptions.dart';
import '../../../trips/data/trip_providers.dart';
import '../../../trips/domain/trip_history_item.dart';
import '../../../trips/domain/trip_status.dart';

class TripHistoryPage extends ConsumerWidget {
  const TripHistoryPage({super.key});

  static const Color _primaryGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(driverTripHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trip History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error),
        data: (trips) => trips.isEmpty
            ? _buildEmptyState()
            : _buildTripList(trips),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final message = error is AuthFailure
        ? error.message
        : 'Could not load trip history. Please try again.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(driverTripHistoryProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.blueGrey),
            SizedBox(height: 16),
            Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your completed and active trips will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(List<TripHistoryItem> trips) {
    return ListView.separated(
      padding: const EdgeInsets.all(25),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _TripHistoryCard(trip: trips[index]),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip});

  final TripHistoryItem trip;

  static const Color _primaryGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(trip.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: trip.isActive
            ? Border.all(color: _primaryGreen, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.routeLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ),
              _StatusChip(label: trip.statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.directions_bus, label: 'Bus', value: trip.busName),
          if (trip.departureTime != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.play_circle_outline,
              label: 'Departed',
              value: _formatDateTime(trip.departureTime!),
            ),
          ],
          if (trip.arrivalTime != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Arrived',
              value: _formatDateTime(trip.arrivalTime!),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      TripStatus.waitingPassengers => _primaryGreen,
      TripStatus.onTheWay => const Color(0xFFFF9800),
      TripStatus.arrived => Colors.blueGrey,
      _ => Colors.blueGrey,
    };
  }

  String _formatDateTime(DateTime dateTime) {
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${monthLabels[dateTime.month - 1]} ${dateTime.day}, $hour:$minute $period';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ),
      ],
    );
  }
}
