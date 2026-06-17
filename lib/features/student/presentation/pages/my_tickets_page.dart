import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/student_reservation_providers.dart';
import '../../domain/models/reservation_details.dart';
import '../../domain/reservation_status.dart';
import 'ticket_details_page.dart';

class MyTicketsPage extends ConsumerStatefulWidget {
  const MyTicketsPage({super.key});

  @override
  ConsumerState<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends ConsumerState<MyTicketsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshActiveTickets(ref);
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(activeTicketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ticketsAsync.when(
                data: (tickets) => _buildContent(context, ref, tickets),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildErrorState(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ReservationDetails> tickets,
  ) {
    if (tickets.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => refreshActiveTickets(ref),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _buildTicketCard(context, ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, ReservationDetails ticket) {
    final statusColor = ticket.reservationStatus ==
            ReservationStatus.boarded
        ? const Color(0xFF00A86F)
        : const Color(0xFFFFB84D);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailsPage(
              reservationDetails: ticket,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
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
              children: [
                Expanded(
                  child: Text(
                    ticket.tripRoute,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3A57),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ReservationStatus.displayLabel(ticket.reservationStatus),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ticket.busName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF62758A)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Color(0xFF62758A),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(ticket.reservationTime),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Color(0xFF62758A),
            ),
            SizedBox(height: 16),
            Text(
              'No active tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F3A57),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Book a trip to see your tickets here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF62758A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Could not load tickets.',
            style: TextStyle(color: Color(0xFF62758A)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => refreshActiveTickets(ref),
            child: const Text('Retry'),
          ),
        ],
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
      child: Row(
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
          const SizedBox(width: 16),
          const Text(
            'My Tickets',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
