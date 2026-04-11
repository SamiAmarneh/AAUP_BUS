import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class DriverLoginPage extends StatelessWidget {
  const DriverLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5E6E7C), size: 16),
          label: const Text('Back', style: TextStyle(color: Color(0xFF5E6E7C), fontSize: 16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.directions_bus_outlined, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 25),
            const Text('Driver Login', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
            const SizedBox(height: 8),
            const Text('Access your driving schedule', style: TextStyle(color: Color(0xFF5E6E7C), fontSize: 15)),
            const SizedBox(height: 45),
            _buildTextField(label: 'Driver ID', hint: 'DRV-12345'),
            const SizedBox(height: 20),
            _buildTextField(label: 'Password', hint: '........', isPassword: true),
            const SizedBox(height: 45),
            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverDashboardPage()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Login as Driver', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E), fontSize: 15)),
        const SizedBox(height: 10),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5)),
          ),
        ),
      ],
    );
  }
}
