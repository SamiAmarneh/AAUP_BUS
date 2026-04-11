import 'package:flutter/material.dart';

class Bus {
  final String id;
  final String busNumber;
  final int capacity;
  String status; // Active, Inactive, Maintenance

  Bus({
    required this.id,
    required this.busNumber,
    required this.capacity,
    required this.status,
  });
}

class BusManagementPage extends StatefulWidget {
  const BusManagementPage({super.key});

  @override
  State<BusManagementPage> createState() => _BusManagementPageState();
}

class _BusManagementPageState extends State<BusManagementPage> {
  final List<Bus> buses = [
    Bus(id: '1', busNumber: 'BUS-001', capacity: 45, status: 'Active'),
    Bus(id: '2', busNumber: 'BUS-002', capacity: 45, status: 'Active'),
    Bus(id: '3', busNumber: 'BUS-003', capacity: 50, status: 'Active'),
    Bus(id: '4', busNumber: 'BUS-004', capacity: 40, status: 'Inactive'),
    Bus(id: '5', busNumber: 'BUS-005', capacity: 45, status: 'Active'),
    Bus(id: '6', busNumber: 'BUS-006', capacity: 50, status: 'Maintenance'),
  ];

  void _showAddBusSheet() {
    final idController = TextEditingController();
    final capacityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            const Text('Add New Bus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Bus ID', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: idController, decoration: const InputDecoration(hintText: 'e.g., BUS-007')),
            const SizedBox(height: 20),
            const Text('Capacity (Seats)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: capacityController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g., 45')),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (idController.text.isNotEmpty) {
                    setState(() {
                      buses.add(Bus(
                        id: DateTime.now().toString(),
                        busNumber: idController.text,
                        capacity: int.tryParse(capacityController.text) ?? 45,
                        status: 'Active',
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Add Bus', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Bus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Are you sure you want to remove ${bus.busNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => buses.removeWhere((b) => b.id == bus.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bus Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];
          return _buildBusCard(bus);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBusSheet,
        backgroundColor: const Color(0xFF00C853),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;
    Color statusIconColor;

    switch (bus.status) {
      case 'Active':
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_outline;
        statusIconColor = const Color(0xFF4CAF50);
        break;
      case 'Inactive':
        statusBgColor = const Color(0xFFF5F5F5);
        statusTextColor = Colors.blueGrey;
        statusIcon = Icons.cancel_outlined;
        statusIconColor = Colors.blueGrey;
        break;
      case 'Maintenance':
        statusBgColor = const Color(0xFFFFF3E0);
        statusTextColor = Colors.orange;
        statusIcon = Icons.error_outline;
        statusIconColor = Colors.orange;
        break;
      default:
        statusBgColor = Colors.grey[200]!;
        statusTextColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusIconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sync_alt, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bus.busNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text('Capacity: ${bus.capacity} seats', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(15)),
                child: Text(bus.status, style: TextStyle(color: statusTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF4CAF50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _confirmDelete(bus),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                  child: Icon(statusIcon, color: statusIconColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
