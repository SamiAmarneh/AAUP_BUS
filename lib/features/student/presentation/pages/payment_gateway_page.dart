import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro2/features/student/domain/models/trip_model.dart';

class PaymentGatewayPage extends StatelessWidget {
  final Trip trip;

  const PaymentGatewayPage({super.key, required this.trip});

  Future<void> _launchSecureUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the secure payment gateway.'),
        ),
      );
    }
  }

  String get _paypalCheckoutUrl {
    final itemName = Uri.encodeComponent(trip.route);
    final amount = trip.price.toString();
    return 'https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=merchant%40example.com&currency_code=ILS&amount=$amount&item_name=$itemName';
  }

  List<PaymentItem> get _paymentItems => [
    PaymentItem(
      label: trip.route,
      amount: '${trip.price}.00',
      status: PaymentItemStatus.final_price,
    ),
  ];

  void _onApplePayResult(BuildContext context, Map<String, dynamic> result) {
    final token = result['paymentMethodData']?['tokenizationData']?['token'];
    if (token != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Pay payment completed successfully.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Pay payment failed or was cancelled.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment Gateway'),
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
              'Your payment will be processed through a secure gateway using HTTPS encryption.',
              style: TextStyle(fontSize: 14, color: Color(0xFF62758A)),
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildPaymentOption(
              context,
              icon: Icons.payment,
              title: 'Pay with PayPal',
              subtitle: 'Secure online payment with PayPal',
              onTap: () => _launchSecureUrl(_paypalCheckoutUrl, context),
            ),
            const SizedBox(height: 14),
            _buildPaymentOption(
              context,
              icon: Icons.lock,
              title: 'Secure bank card checkout',
              subtitle: 'Redirect to an encrypted secure payment page',
              onTap: () {
                _launchSecureUrl(
                  'https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=merchant%40example.com&currency_code=ILS&amount=${trip.price}&item_name=${Uri.encodeComponent(trip.route)}',
                  context,
                );
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3E8F1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.phone_iphone,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Pay with Apple Pay',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F3A57),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fast secure payment using Apple Pay',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF62758A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ApplePayButton(
                    paymentConfigurationAsset: 'assets/apple_pay_profile.json',
                    paymentItems: _paymentItems,
                    style: ApplePayButtonStyle.black,
                    type: ApplePayButtonType.buy,
                    margin: const EdgeInsets.only(top: 8),
                    onPaymentResult: (result) =>
                        _onApplePayResult(context, result),
                    loadingIndicator: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'Note: Replace merchant@example.com with your actual payment merchant account email or merchant ID in the code for a live deployment.',
              style: TextStyle(fontSize: 12, color: Color(0xFF62758A)),
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
            trip.route,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F3A57),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company',
                    style: TextStyle(fontSize: 12, color: Color(0xFF62758A)),
                  ),
                  Text(
                    trip.company,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3A57),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: Color(0xFF62758A)),
                  ),
                  Text(
                    '₪ ${trip.price}',
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
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E8F1)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3A57),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF62758A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF62758A),
            ),
          ],
        ),
      ),
    );
  }
}
