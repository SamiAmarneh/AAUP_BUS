import 'package:flutter/material.dart';
import 'qr_code_display_page.dart';

class TripItem {
  final String id;
  final String from;
  final String to;
  final String company;
  final String busId;
  final String time;
  final String seats;

  TripItem({
    required this.id,
    required this.from,
    required this.to,
    required this.company,
    required this.busId,
    required this.time,
    required this.seats,
  });
}

class QRCodeGenerationPage extends StatefulWidget {
  const QRCodeGenerationPage({super.key});

  @override
  State<QRCodeGenerationPage> createState() => _QRCodeGenerationPageState();
}

class _QRCodeGenerationPageState extends State<QRCodeGenerationPage> {
  String selectedCity = 'All Cities';
  String? selectedTripId;
  TripItem? selectedTrip;

  final List<TripItem> trips = [
    TripItem(id: '1', from: 'Jenin', to: 'AAUP', company: 'Taneen Bus Company', busId: 'BUS-001', time: '07:00', seats: '8/45'),
    TripItem(id: '2', from: 'Jenin', to: 'AAUP', company: 'Al-Quds Transport', busId: 'BUS-003', time: '08:30', seats: '12/45'),
    TripItem(id: '3', from: 'Tulkarm', to: 'AAUP', company: 'Jenin Express', busId: 'BUS-005', time: '07:30', seats: '5/40'),
    TripItem(id: '4', from: 'Nablus', to: 'AAUP', company: 'Palestine Transport', busId: 'BUS-002', time: '06:45', seats: '3/45'),
    TripItem(id: '5', from: 'Ramallah', to: 'AAUP', company: 'Jenin Express', busId: 'BUS-004', time: '07:15', seats: '10/40'),
    TripItem(id: '6', from: 'Bethlehem', to: 'AAUP', company: 'Palestine Transport', busId: 'BUS-006', time: '06:30', seats: '20/50'),
    TripItem(id: '7', from: 'Hebron', to: 'AAUP', company: 'Taneen Bus Company', busId: 'BUS-007', time: '06:00', seats: '14/45'),
  ];

  @override
  Widget build(BuildContext context) {
    List<TripItem> filteredTrips = trips.where((t) => selectedCity == 'All Cities' || t.from == selectedCity).toList();
    
    Map<String, List<TripItem>> groupedTrips = {};
    for (var trip in filteredTrips) {
      groupedTrips.putIfAbsent(trip.from, () => []).add(trip);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      const Text('QR Code Generation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: ['All Cities', 'Jenin', 'Tulkarm', 'Nablus', 'Ramallah', 'Bethlehem', 'Hebron']
                        .map((city) => _buildCityChip(city))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Select Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF546E7A))),
                const SizedBox(height: 15),
                ...groupedTrips.entries.map((entry) => Column(
                  children: [
                    _buildCityHeader(entry.key, '${entry.value.length} trips'),
                    ...entry.value.map((trip) => _buildTripCard(trip)),
                  ],
                )).toList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: selectedTrip == null ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRCodeDisplayPage(
                    tripName: '${selectedTrip!.from} to ${selectedTrip!.to}',
                    busId: selectedTrip!.busId,
                    time: selectedTrip!.time,
                    fromLocation: selectedTrip!.from,
                    toLocation: selectedTrip!.to,
                    seats: selectedTrip!.seats,
                    company: selectedTrip!.company,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text('Generate QR Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
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
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFFF6D00) : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildCityHeader(String city, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.location_on, color: Color(0xFFFF6D00), size: 18)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(count, style: const TextStyle(color: Colors.blueGrey, fontSize: 12))]),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripItem trip) {
    bool isSelected = selectedTripId == trip.id;
    return GestureDetector(
      onTap: () => setState(() {
        selectedTripId = trip.id;
        selectedTrip = trip;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0).withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFF6D00) : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${trip.from} → ${trip.to}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1C1E))),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.business, size: 16, color: Colors.blueGrey), const SizedBox(width: 6), Text(trip.company, style: const TextStyle(color: Colors.blueGrey, fontSize: 14))]),
                Text(trip.busId, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const Icon(Icons.access_time, size: 18, color: Colors.blueGrey), const SizedBox(width: 5), Text(trip.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                    Row(children: [const Icon(Icons.people_outline, size: 18, color: Colors.blueGrey), const SizedBox(width: 5), Text('${trip.seats} seats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                  ],
                ),
              ],
            ),
            if (isSelected) const Positioned(top: 0, right: 0, child: Icon(Icons.check_circle, color: Color(0xFFFF6D00), size: 28)),
          ],
        ),
      ),
    );
  }
}
