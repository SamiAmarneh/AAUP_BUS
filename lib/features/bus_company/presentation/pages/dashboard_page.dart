import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_actions.dart';
import '../../../../core/auth/auth_providers.dart';
import 'trips_management_page.dart';
import 'bus_management_page.dart';
import 'trip_tracking_page.dart';
import 'qr_code_generation_page.dart';
import 'manage_drivers_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfileAsync = ref.watch(adminProfileProvider);

    return adminProfileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      data: (profile) {
        if (adminProfileAsync.isRefreshing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 40),
                decoration: const BoxDecoration(color: Color(0xFF247BFF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            Text(
                              profile.name ?? profile.email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (profile.name != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                profile.email,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                          onPressed: () => confirmLogout(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _buildStatCard('Active Trips', '5'),
                        const SizedBox(width: 15),
                        _buildStatCard('Active Buses', '8'),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildStatCard('Bookings Today', '42'),
                        const SizedBox(width: 15),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  children: [
                    _buildActionItem(context, 'Manage Trips', 'View and edit trip schedules', Icons.assignment_outlined, const Color(0xFFE8F0FF), const Color(0xFF247BFF), const TripsManagementPage()),
                    _buildActionItem(context, 'Manage Buses', 'View and edit bus fleet', Icons.sync_alt, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), const BusManagementPage()),
                    _buildActionItem(context, 'Manage Drivers', 'Create and manage driver accounts', Icons.person_add_outlined, const Color(0xFFE3F2FD), const Color(0xFF2196F3), const ManageDriversPage()),
                    _buildActionItem(context, 'Track Trips', 'Live location tracking', Icons.map_outlined, const Color(0xFFF3E5F5), const Color(0xFF9C27B0), const TripTrackingPage()),
                    _buildActionItem(context, 'Generate QR Code', 'Student check-in codes', Icons.qr_code_scanner, const Color(0xFFFFF3E0), const Color(0xFFFF9800), const QRCodeGenerationPage()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconBgColor,
    Color iconColor,
    Widget destination,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A1C1E))),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey, size: 20),
      ),
    );
  }
}
