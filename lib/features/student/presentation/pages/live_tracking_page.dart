import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveBus {
  final String from;
  final String to;
  final String busId;
  final String company;
  final String status;
  final String eta;
  final String distance;
  final String routeName;
  final Color themeColor;
  final LatLng position;

  LiveBus({
    required this.from,
    required this.to,
    required this.busId,
    required this.company,
    required this.status,
    required this.eta,
    required this.distance,
    required this.routeName,
    required this.themeColor,
    required this.position,
  });
}

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  static const LatLng _center = LatLng(31.9495, 35.9329);

  final List<LiveBus> _nearbyBuses = [
    LiveBus(
      from: 'Ramallah',
      to: 'AAUP',
      busId: 'BUS-001',
      company: 'Jenin Express',
      status: 'Approaching',
      eta: '5 min',
      distance: '2.3 km away',
      routeName: 'Ramallah → AAUP',
      themeColor: const Color(0xFF34C759),
      position: const LatLng(31.9074, 35.2036),
    ),
    LiveBus(
      from: 'Jenin',
      to: 'AAUP',
      busId: 'BUS-003',
      company: 'Taneen Bus Company',
      status: 'En Route',
      eta: '15 min',
      distance: '8.5 km away',
      routeName: 'Jenin → AAUP',
      themeColor: const Color(0xFF007AFF),
      position: const LatLng(32.4590, 35.3000),
    ),
    LiveBus(
      from: 'Bethlehem',
      to: 'AAUP',
      busId: 'BUS-005',
      company: 'Palestine Transport',
      status: 'Far Away',
      eta: '45 min',
      distance: '25 km away',
      routeName: 'Bethlehem → AAUP',
      themeColor: const Color(0xFF8E8E93),
      position: const LatLng(31.7054, 35.2007),
    ),
    LiveBus(
      from: 'Tulkarm',
      to: 'AAUP',
      busId: 'BUS-007',
      company: 'Al-Quds Transport',
      status: 'En Route',
      eta: '10 min',
      distance: '4.8 km away',
      routeName: 'Tulkarm → AAUP',
      themeColor: const Color(0xFF5AC8FA),
      position: const LatLng(32.3100, 35.0000),
    ),
  ];

  late final Set<Marker> _markers;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _markers = _nearbyBuses
        .map(
          (bus) => Marker(
            markerId: MarkerId(bus.busId),
            position: bus.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              bus.themeColor == const Color(0xFF34C759)
                  ? BitmapDescriptor.hueGreen
                  : bus.themeColor == const Color(0xFF007AFF)
                  ? BitmapDescriptor.hueBlue
                  : bus.themeColor == const Color(0xFF5AC8FA)
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueViolet,
            ),
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF00C853),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Live Bus Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 260,
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: _center,
                                zoom: 10,
                              ),
                              mapType: MapType.normal,
                              markers: _markers,
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: true,
                              rotateGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                // Animate to the first marker position
                                if (_markers.isNotEmpty) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLng(
                                      _markers.first.position,
                                    ),
                                  );
                                }
                                print('Google Map created successfully');
                              },
                              onCameraMove: (position) {
                                print('Camera moved to: ${position.target}');
                              },
                            ),
                            Positioned(
                              top: 18,
                              left: 18,
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Color(0xFF00C853),
                                  size: 30,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 30,
                              right: 18,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync,
                                  color: Color(0xFF456CFF),
                                  size: 22,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 18,
                              right: 18,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_searching,
                                  color: Color(0xFF7A7A7A),
                                  size: 22,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 18,
                              left: 18,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.map,
                                  color: Color(0xFF00C853),
                                  size: 22,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 26,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: const [
                                  Text(
                                    'Real-Time GPS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Track your bus live',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nearby Buses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  ..._nearbyBuses.map(_buildBusCard),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF007AFF),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tracking updates every 30 seconds. Make sure location services are enabled.',
                            style: TextStyle(
                              color: Color(0xFF6C7A93),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusCard(LiveBus bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
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
                child: Text(
                  bus.routeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bus.themeColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  bus.status,
                  style: TextStyle(
                    color: bus.themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bus.busId,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            bus.company,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF8E8E93)),
              const SizedBox(width: 6),
              Text(
                'ETA: ${bus.eta}',
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.place, size: 16, color: Color(0xFF8E8E93)),
              const SizedBox(width: 6),
              Text(
                bus.distance,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
