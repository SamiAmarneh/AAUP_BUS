import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trips/data/trip_providers.dart';
import '../../../trips/domain/trip_history_constants.dart';
import '../../../trips/domain/trip_history_item.dart';
import '../../../trips/domain/trip_status.dart';

class TripHistoryPage extends ConsumerStatefulWidget {
  const TripHistoryPage({super.key});

  @override
  ConsumerState<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends ConsumerState<TripHistoryPage> {
  static const Color _primaryGreen = Color(0xFF4CAF50);

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverTripHistoryNotifierProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final threshold = TripHistoryConstants.scrollLoadThreshold;
    final isNearBottom = position.pixels >= position.maxScrollExtent - threshold;

    if (!isNearBottom) {
      return;
    }

    ref.read(driverTripHistoryNotifierProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(driverTripHistoryNotifierProvider);

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
      body: _buildBody(historyState),
    );
  }

  Widget _buildBody(DriverTripHistoryState historyState) {
    if (historyState.isLoading && historyState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyState.errorMessage != null && historyState.items.isEmpty) {
      return _buildErrorState(historyState.errorMessage!);
    }

    if (historyState.items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(driverTripHistoryNotifierProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(25),
        itemCount: _listItemCount(historyState),
        separatorBuilder: (context, index) {
          if (index >= historyState.items.length) {
            return const SizedBox.shrink();
          }
          return const SizedBox(height: 16);
        },
        itemBuilder: (context, index) {
          if (index < historyState.items.length) {
            return _TripHistoryCard(trip: historyState.items[index]);
          }

          if (historyState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No more trips',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),
            ),
          );
        },
      ),
    );
  }

  int _listItemCount(DriverTripHistoryState historyState) {
    final tripCount = historyState.items.length;
    if (historyState.isLoadingMore || !historyState.hasMore) {
      return tripCount + 1;
    }
    return tripCount;
  }

  Widget _buildErrorState(String message) {
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
              onPressed: () => ref
                  .read(driverTripHistoryNotifierProvider.notifier)
                  .loadInitial(),
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
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(driverTripHistoryNotifierProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.history, size: 64, color: Colors.blueGrey),
          SizedBox(height: 16),
          Text(
            'No trips yet',
            textAlign: TextAlign.center,
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
          if (trip.createdAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Created',
              value: _formatDateTime(trip.createdAt!),
            ),
          ],
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
          if (trip.durationLabel != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: trip.durationLabel!,
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
