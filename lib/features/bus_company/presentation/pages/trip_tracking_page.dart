import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActiveTrip {
  final String from;
  final String to;
  final String company;
  final String busId;
  final double progress;
  final String currentLocation;
  final String departureTime;
  final String passengers;
  final String speed; // خانة السرعة الجديدة
  final Color themeColor;
  final LatLng position;

  ActiveTrip({
    required this.from,
    required this.to,
    required this.company,
    required this.busId,
    required this.progress,
    required this.currentLocation,
    required this.departureTime,
    required this.passengers,
    required this.speed,
    required this.themeColor,
    required this.position,
  });
}

class TripTrackingPage extends StatefulWidget {
  const TripTrackingPage({super.key});

  @override
  State<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends State<TripTrackingPage> {
  String selectedCity = 'All Cities';
  static const LatLng _center = LatLng(32.4106, 35.3396);

  final List<ActiveTrip> activeTrips = [
    ActiveTrip(
      from: 'Jenin',
      to: 'AAUP',
      company: 'Taneen Bus Company',
      busId: 'BUS-001',
      progress: 0.65,
      currentLocation: 'Near Arraba',
      departureTime: '07:00',
      passengers: '37/45',
      speed: '65 km/h',
      themeColor: Colors.blue,
      position: const LatLng(32.4050, 35.2500),
    ),
    ActiveTrip(
      from: 'Nablus',
      to: 'AAUP',
      company: 'Al-Quds Transport',
      busId: 'BUS-008',
      progress: 0.85,
      currentLocation: 'Near AAUP Main Gate',
      departureTime: '06:45',
      passengers: '42/45',
      speed: '40 km/h',
      themeColor: Colors.green,
      position: const LatLng(32.4080, 35.3300),
    ),
    ActiveTrip(
      from: 'Bethlehem',
      to: 'AAUP',
      company: 'Palestine Transport',
      busId: 'BUS-006',
      progress: 0.20,
      currentLocation: 'Near Ramallah',
      departureTime: '06:30',
      passengers: '30/50',
      speed: '85 km/h',
      themeColor: Colors.purple,
      position: const LatLng(31.9000, 35.2000),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<ActiveTrip> filteredTrips = activeTrips.where((t) => selectedCity == 'All Cities' || t.from == selectedCity).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trip Tracking', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Monitor active trips in real-time', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: ['All Cities', 'Jenin', 'Tulkarm', 'Nablus', 'Ramallah', 'Bethlehem']
                        .map((c) => _buildCityChip(c))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Map Section
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(target: _center, zoom: 10),
                  markers: filteredTrips.map((t) => Marker(
                    markerId: MarkerId(t.busId),
                    position: t.position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      t.themeColor == Colors.green ? BitmapDescriptor.hueGreen : 
                      t.themeColor == Colors.purple ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueBlue
                    ),
                  )).toSet(),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
                Positioned(
                  top: 15, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: const Row(children: [
                      Icon(Icons.gps_fixed, color: Color(0xFF9C27B0), size: 16),
                      SizedBox(width: 8),
                      Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C27B0), fontSize: 12)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Active Trips List
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${filteredTrips.length} buses on route', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 15),
                ...filteredTrips.map((trip) => _buildTripCard(trip)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(String label) {
    bool isSelected = selectedCity == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCity = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF9C27B0) : Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTripCard(ActiveTrip trip) {
    int percentage = (trip.progress * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${trip.from} → ${trip.to}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(trip.company, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ]),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: trip.themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('$percentage%', style: TextStyle(color: trip.themeColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: trip.progress, backgroundColor: Colors.grey[200], color: trip.themeColor, minHeight: 6),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.location_on, color: Color(0xFF9C27B0), size: 20),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current Location', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                Text(trip.currentLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripInfo(Icons.access_time, 'Departed', trip.departureTime, Colors.blue),
              _buildTripInfo(Icons.speed, 'Speed', trip.speed, Colors.orange), // خانة السرعة الجديدة
              _buildTripInfo(Icons.people_outline, 'Passengers', trip.passengers, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    ]);
  }
}
