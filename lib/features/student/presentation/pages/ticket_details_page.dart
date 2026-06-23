import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/models/reservation_details.dart';
import '../../domain/payment_status.dart';
import '../../domain/reservation_status.dart';

class TicketDetailsPage extends StatelessWidget {
  final ReservationDetails reservationDetails;

  const TicketDetailsPage({
    super.key,
    required this.reservationDetails,
  });

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: reservationDetails.qrData,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Boarding QR Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F3A57),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                ],
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
            'Ticket Details',
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservationDetails.tripRoute,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F3A57),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('From', reservationDetails.tripFrom),
          _buildDetailRow('To', reservationDetails.tripTo),
          _buildDetailRow('Bus', reservationDetails.busName),
          _buildDetailRow('Phone', reservationDetails.phoneNumber),
          if (reservationDetails.pickupLocation.isNotEmpty)
            _buildDetailRow('Pickup', reservationDetails.pickupLocation),
          if (reservationDetails.hasPickupCoordinates)
            _buildDetailRow('GPS', 'Location attached'),
          _buildDetailRow(
            'Reserved at',
            _formatDateTime(reservationDetails.reservationTime),
          ),
          _buildDetailRow(
            'Status',
            ReservationStatus.displayLabel(
              reservationDetails.reservationStatus,
            ),
          ),
          _buildDetailRow(
            'Payment',
            '${PaymentStatus.displayLabel(reservationDetails.paymentStatus)} — ₪ ${reservationDetails.paymentAmount.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF62758A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F3A57),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
