import 'package:flutter/material.dart';

class Driver {
  final String id;
  final String name;
  final String driverId;
  final String phone;
  final String status; // Active, On Leave

  Driver({
    required this.id,
    required this.name,
    required this.driverId,
    required this.phone,
    required this.status,
  });
}

class ManageDriversPage extends StatefulWidget {
  const ManageDriversPage({super.key});

  @override
  State<ManageDriversPage> createState() => _ManageDriversPageState();
}

class _ManageDriversPageState extends State<ManageDriversPage> {
  final List<Driver> drivers = [
    Driver(id: '1', name: 'Ahmed Mohammed', driverId: 'DRV-001', phone: '0599000001', status: 'Active'),
    Driver(id: '2', name: 'Sami Ali', driverId: 'DRV-002', phone: '0599000002', status: 'Active'),
    Driver(id: '3', name: 'Mahmoud Hassan', driverId: 'DRV-003', phone: '0599000003', status: 'On Leave'),
  ];

  // دالة لتوليد ID تلقائي
  String _generateNextDriverId() {
    int maxId = 0;
    for (var driver in drivers) {
      final parts = driver.driverId.split('-');
      if (parts.length > 1) {
        final num = int.tryParse(parts[1]) ?? 0;
        if (num > maxId) maxId = num;
      }
    }
    final nextNum = maxId + 1;
    return 'DRV-${nextNum.toString().padLeft(3, '0')}';
  }

  void _confirmDelete(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Account'),
          ],
        ),
        content: Text('Are you sure you want to delete account for ${driver.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => drivers.removeWhere((d) => d.id == driver.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver account deleted'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDriverSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final nextId = _generateNextDriverId();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
              const Text('Create Driver Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              _buildInputLabel('Driver ID (Auto-generated)'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: Text(nextId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ),
              
              const SizedBox(height: 20),
              _buildInputLabel('Full Name'),
              _buildSimpleTextField(nameController, 'Enter full name'),
              
              const SizedBox(height: 20),
              _buildInputLabel('Phone Number'),
              _buildSimpleTextField(phoneController, '059XXXXXXXX'),
              
              const SizedBox(height: 20),
              _buildInputLabel('Password'),
              _buildSimpleTextField(passwordController, '........', isPassword: true),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        drivers.add(Driver(
                          id: DateTime.now().toString(),
                          name: nameController.text,
                          driverId: nextId,
                          phone: phoneController.text,
                          status: 'Active',
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF247BFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)));

  Widget _buildSimpleTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BFF),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Manage Drivers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: drivers.length,
        itemBuilder: (context, index) => _buildDriverCard(drivers[index]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDriverSheet,
        backgroundColor: const Color(0xFF247BFF),
        shape: const CircleBorder(),
        child: const Icon(Icons.person_add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDriverCard(Driver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person, color: Color(0xFF247BFF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${driver.driverId} • ${driver.phone}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(driver),
          ),
        ],
      ),
    );
  }
}
