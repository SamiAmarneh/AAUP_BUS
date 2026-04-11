import 'package:flutter/material.dart';

class Trip {
  final String id; // أضفت ID لسهولة الحذف
  final String from;
  final String to;
  final String status;
  final Color statusColor;
  final String company;
  final String busId;
  final String price;
  final String fromLoc;
  final String toLoc;
  final String time;
  final String seats;

  Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
    required this.statusColor,
    required this.company,
    required this.busId,
    required this.price,
    required this.fromLoc,
    required this.toLoc,
    required this.time,
    required this.seats,
  });
}

class TripsManagementPage extends StatefulWidget {
  const TripsManagementPage({super.key});

  @override
  State<TripsManagementPage> createState() => _TripsManagementPageState();
}

class _TripsManagementPageState extends State<TripsManagementPage> {
  String selectedCity = 'All Cities';
  String selectedStatus = 'All';

  final List<Trip> allTrips = [
    Trip(
      id: '1',
      from: 'Jenin',
      to: 'AAUP',
      status: 'On the Way',
      statusColor: const Color(0xFF4CAF50),
      company: 'Taneen Bus Company',
      busId: 'BUS-001',
      price: '15',
      fromLoc: 'Jenin Bus Terminal',
      toLoc: 'Arab American University',
      time: '07:00',
      seats: '8/45',
    ),
    Trip(
      id: '2',
      from: 'Jenin',
      to: 'AAUP',
      status: 'Scheduled',
      statusColor: const Color(0xFF247BFF),
      company: 'Al-Quds Transport',
      busId: 'BUS-003',
      price: '15',
      fromLoc: 'Jenin City Center',
      toLoc: 'Arab American University',
      time: '08:30',
      seats: '12/45',
    ),
    Trip(
      id: '3',
      from: 'Tulkarm',
      to: 'AAUP',
      status: 'On the Way',
      statusColor: const Color(0xFF4CAF50),
      company: 'Jenin Express',
      busId: 'BUS-005',
      price: '12',
      fromLoc: 'Tulkarm Central Station',
      toLoc: 'Arab American University',
      time: '07:30',
      seats: '5/40',
    ),
  ];

  void _confirmDelete(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Confirm Delete'),
          ],
        ),
        content: Text('Are you sure you want to delete the trip from ${trip.from} to ${trip.to}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                allTrips.removeWhere((t) => t.id == trip.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Trip deleted successfully'), backgroundColor: Colors.red[400]),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTripSheet() {
    final fromController = TextEditingController();
    final companyController = TextEditingController();
    final priceController = TextEditingController();
    final fromLocController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              const Text('Add New Trip', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
              const SizedBox(height: 30),
              _buildInputLabel('From (City)'),
              _buildSimpleTextField(fromController, 'e.g., Hebron'),
              const SizedBox(height: 20),
              _buildInputLabel('Bus Company'),
              _buildSimpleTextField(companyController, 'e.g., Al-Quds Transport'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Price (₪)'), _buildSimpleTextField(priceController, '15')])),
                  const SizedBox(width: 15),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Departure Time'), _buildSimpleTextField(timeController, '08:00')])),
                ],
              ),
              const SizedBox(height: 20),
              _buildInputLabel('Exact Starting Location'),
              _buildSimpleTextField(fromLocController, 'e.g., Main Station'),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (fromController.text.isNotEmpty) {
                      setState(() {
                        allTrips.add(Trip(
                          id: DateTime.now().toString(),
                          from: fromController.text,
                          to: 'AAUP',
                          status: 'Scheduled',
                          statusColor: const Color(0xFF247BFF),
                          company: companyController.text.isEmpty ? 'Generic Company' : companyController.text,
                          busId: 'BUS-${allTrips.length + 100}',
                          price: priceController.text.isEmpty ? '15' : priceController.text,
                          fromLoc: fromLocController.text.isEmpty ? 'Main Terminal' : fromLocController.text,
                          toLoc: 'Arab American University',
                          time: timeController.text.isEmpty ? '09:00' : timeController.text,
                          seats: '0/45',
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF247BFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('Add Trip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)));

  Widget _buildSimpleTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Trip> filteredTrips = allTrips.where((trip) {
      bool cityMatch = selectedCity == 'All Cities' || trip.from == selectedCity;
      bool statusMatch = selectedStatus == 'All' || trip.status == selectedStatus;
      return cityMatch && statusMatch;
    }).toList();

    Map<String, List<Trip>> groupedTrips = {};
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
            decoration: const BoxDecoration(color: Color(0xFF247BFF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 5),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Trips Management', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Manage all trips to AAUP', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: ['All Cities', 'Jenin', 'Tulkarm', 'Nablus', 'Ramallah', 'Hebron', 'Bethlehem'].map((c) => _buildCityChip(c)).toList()),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: ['All', 'Scheduled', 'On the Way', 'Completed'].map((s) => _buildStatusTab(s)).toList()),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTrips.isEmpty
                ? const Center(child: Text('No trips found for these filters.', style: TextStyle(color: Colors.grey)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    children: groupedTrips.entries.map((entry) => Column(children: [_buildCitySectionHeader(entry.key, '${entry.value.length} trips'), ...entry.value.map((trip) => _buildTripCard(trip))])).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripSheet,
        backgroundColor: const Color(0xFF247BFF),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildCityChip(String label) {
    bool isSelected = selectedCity == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCity = label),
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25)),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF247BFF) : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildStatusTab(String label) {
    bool isSelected = selectedStatus == label;
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.3))),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildCitySectionHeader(String city, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.location_on, color: Color(0xFF247BFF), size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1C1E))), Text(count, style: const TextStyle(color: Colors.blueGrey, fontSize: 13))]),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text('${trip.from} → ${trip.to}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: trip.statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(trip.status, style: TextStyle(color: trip.statusColor, fontSize: 12, fontWeight: FontWeight.bold)))]),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.business, size: 16, color: Colors.blueGrey), const SizedBox(width: 6), Text(trip.company, style: const TextStyle(color: Colors.blueGrey, fontSize: 14))]),
                  Text('Bus: ${trip.busId}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('₪${trip.price}', style: const TextStyle(color: Color(0xFF247BFF), fontSize: 24, fontWeight: FontWeight.bold)), const Text('per seat', style: TextStyle(color: Colors.blueGrey, fontSize: 11))]),
            ],
          ),
          const SizedBox(height: 15),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(15)), child: Column(children: [_buildRouteItem(trip.fromLoc, isStart: true), const SizedBox(height: 8), _buildRouteItem(trip.toLoc, isStart: false)])),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildIconInfo(Icons.access_time, 'Departure', trip.time, const Color(0xFF247BFF)), _buildIconInfo(Icons.people_outline, 'Seats', trip.seats, const Color(0xFF4CAF50))]),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE3F2FD), foregroundColor: const Color(0xFF247BFF), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Edit Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') _confirmDelete(trip);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Trip', style: TextStyle(color: Colors.red))]),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteItem(String loc, {required bool isStart}) {
    return Row(
      children: [
        Column(children: [Icon(Icons.circle, size: 8, color: isStart ? const Color(0xFF247BFF) : const Color(0xFF4CAF50)), if (isStart) Container(width: 2, height: 15, color: Colors.grey[300])]),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isStart ? 'From' : 'To', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)), Text(loc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]),
      ],
    );
  }

  Widget _buildIconInfo(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color == const Color(0xFF4CAF50) ? color : Colors.black87))]),
      ],
    );
  }
}
