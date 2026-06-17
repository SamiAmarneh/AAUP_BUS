import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/validation/phone_number_validator.dart';
import '../../data/reservation_providers.dart';
import '../../domain/models/trip_model.dart';
import 'payment_gateway_page.dart';

class PhoneEntryPage extends ConsumerStatefulWidget {
  final Trip trip;

  const PhoneEntryPage({super.key, required this.trip});

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final TextEditingController _phoneController = TextEditingController();
  List<String> _savedPhones = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedPhones();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPhones() async {
    final storage = ref.read(studentBookingLocalStorageProvider);
    final phones = await storage.getSavedPhoneNumbers();
    if (!mounted) {
      return;
    }
    setState(() => _savedPhones = phones);
  }

  void _selectSavedPhone(String phone) {
    setState(() {
      _phoneController.text = phone;
      _errorMessage = null;
    });
  }

  void _continueToPayment() {
    final phone = _phoneController.text.trim();
    if (!PhoneNumberValidator.validatePhoneNumber(phone)) {
      setState(() {
        _errorMessage = 'Please enter a valid Palestinian phone number.';
      });
      return;
    }

    final normalizedPhone = PhoneNumberValidator.normalizePhoneNumber(phone);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayPage(
          trip: widget.trip,
          phoneNumber: normalizedPhone,
        ),
      ),
    );
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
                  const Text(
                    'Enter Phone Number',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3A57),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We need your Palestinian phone number to confirm your booking.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF62758A)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      hintText: '0599123456',
                      errorText: _errorMessage,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE3E8F1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE3E8F1)),
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  if (_savedPhones.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Previously used numbers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F3A57),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _savedPhones
                          .map(
                            (phone) => ActionChip(
                              label: Text(phone),
                              onPressed: () => _selectSavedPhone(phone),
                              backgroundColor: const Color(0xFFE8F5FF),
                              labelStyle: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _continueToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
            'Phone Number',
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
