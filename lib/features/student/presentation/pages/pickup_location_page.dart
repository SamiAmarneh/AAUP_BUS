import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/permissions/location_permission_service.dart';
import '../../domain/models/trip_model.dart';
import 'payment_gateway_page.dart';

class PickupLocationPage extends StatefulWidget {
  final Trip trip;
  final String phoneNumber;

  const PickupLocationPage({
    super.key,
    required this.trip,
    required this.phoneNumber,
  });

  @override
  State<PickupLocationPage> createState() => _PickupLocationPageState();
}

class _PickupLocationPageState extends State<PickupLocationPage> {
  final TextEditingController _locationController = TextEditingController();
  GeoPoint? _pickupCoordinates;
  bool _isCapturingLocation = false;
  String? _locationCaptureMessage;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  bool get _canContinue => _locationController.text.trim().isNotEmpty;

  Future<void> _captureCurrentLocation() async {
    if (_isCapturingLocation) {
      return;
    }

    setState(() {
      _isCapturingLocation = true;
      _locationCaptureMessage = null;
    });

    final permissionStatus = await LocationPermissionService().ensureGranted();
    if (permissionStatus != LocationPermissionStatus.granted) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCapturingLocation = false;
        _locationCaptureMessage =
            'Location permission denied. You can still continue with text only.';
      });
      return;
    }

    try {
      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isCapturingLocation = false;
          _locationCaptureMessage =
              'Location services are disabled. You can still continue with text only.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pickupCoordinates = GeoPoint(position.latitude, position.longitude);
        _isCapturingLocation = false;
        _locationCaptureMessage =
            'Location captured (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCapturingLocation = false;
        _locationCaptureMessage =
            'Could not capture location. You can still continue with text only.';
      });
    }
  }

  void _continueToPayment() {
    if (!_canContinue) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayPage(
          trip: widget.trip,
          phoneNumber: widget.phoneNumber,
          pickupLocation: _locationController.text.trim(),
          pickupCoordinates: _pickupCoordinates,
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
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3A57),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The bus is already on the way. Tell us where you want to be picked up.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF62758A)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _locationController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Where should the bus pick you up?',
                      hintText: 'e.g. Main gate, Building 3, street name...',
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
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isCapturingLocation ? null : _captureCurrentLocation,
                      icon: _isCapturingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isCapturingLocation
                            ? 'Capturing location...'
                            : 'Use my current location',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (_locationCaptureMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _locationCaptureMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _pickupCoordinates != null
                            ? const Color(0xFF00A86F)
                            : const Color(0xFF62758A),
                      ),
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
                  onPressed: _canContinue ? _continueToPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFE3E8F1),
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
            'Pickup Location',
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
