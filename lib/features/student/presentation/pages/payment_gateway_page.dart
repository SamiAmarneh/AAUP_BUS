import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_exceptions.dart';
import '../../data/reservation_providers.dart';
import '../../data/student_reservation_providers.dart';
import '../../data/student_trip_providers.dart';
import '../../domain/models/trip_model.dart';
import 'booking_confirmation_page.dart';

class PaymentGatewayPage extends ConsumerStatefulWidget {
  final Trip trip;
  final String phoneNumber;
  final String? pickupLocation;
  final GeoPoint? pickupCoordinates;

  const PaymentGatewayPage({
    super.key,
    required this.trip,
    required this.phoneNumber,
    this.pickupLocation,
    this.pickupCoordinates,
  });

  @override
  ConsumerState<PaymentGatewayPage> createState() => _PaymentGatewayPageState();
}

class _PaymentGatewayPageState extends ConsumerState<PaymentGatewayPage> {
  bool _isProcessing = false;
  String _selectedMethod = 'card';

  Future<void> _completePayment() async {
    if (_isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(reservationRepositoryProvider);
      final localStorage = ref.read(studentBookingLocalStorageProvider);

      final details = await repository.createBooking(
        trip: widget.trip,
        phoneNumber: widget.phoneNumber,
        pickupLocation: widget.pickupLocation,
        pickupCoordinates: widget.pickupCoordinates,
      );

      await localStorage.savePhoneNumber(widget.phoneNumber);
      await localStorage.saveReservationId(details.reservationId);
      await refreshStudentBrowseData(ref);
      ref.invalidate(activeTicketsProvider);

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BookingConfirmationPage(reservationDetails: details),
        ),
      );
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Checkout',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F3A57),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your payment is processed through a secure encrypted gateway.',
              style: TextStyle(fontSize: 14, color: Color(0xFF62758A)),
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 20),
            const Text(
              'Payment method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F3A57),
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethod(
              id: 'card',
              icon: Icons.credit_card,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, and local cards',
            ),
            const SizedBox(height: 10),
            _buildPaymentMethod(
              id: 'wallet',
              icon: Icons.account_balance_wallet_outlined,
              title: 'Digital Wallet',
              subtitle: 'Fast checkout with your saved wallet',
            ),
            const Spacer(),
            Row(
              children: const [
                Icon(Icons.lock_outline, size: 16, color: Color(0xFF62758A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '256-bit SSL encryption protects your transaction.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF62758A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _completePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay Now',
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
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE3E8F1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3A57),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF62758A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF62758A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
            widget.trip.route,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F3A57),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Bus', widget.trip.company),
          _buildSummaryRow('Phone', widget.phoneNumber),
          if (widget.trip.requiresPickupInput &&
              widget.pickupLocation != null) ...[
            _buildSummaryRow('Pickup', widget.pickupLocation!),
            if (widget.pickupCoordinates != null)
              _buildSummaryRow('GPS', 'Location attached'),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Color(0xFF62758A)),
              ),
              Text(
                '₪ ${widget.trip.price}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF62758A)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F3A57),
            ),
          ),
        ],
      ),
    );
  }
}
