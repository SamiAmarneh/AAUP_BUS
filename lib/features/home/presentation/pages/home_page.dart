import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_route_guard.dart';
import '../../../bus_company/presentation/pages/login_page.dart';
import '../../../driver/presentation/pages/login_page.dart';
import '../../../student/presentation/pages/login_page.dart';
import '../../../../core/session/session_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF247BFF),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'GoAAUP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tracking & Reservation',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 60),
              _buildHomeButton(
                context,
                title: 'Bus Company Login',
                color: const Color(0xFF247BFF),
                textColor: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthLoginRouteGuard(
                        child: BusCompanyLoginPage(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildHomeButton(
                context,
                title: 'Driver Login',
                color: const Color(0xFF00C853),
                textColor: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthLoginRouteGuard(
                        child: DriverLoginPage(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildHomeButton(
                context,
                title: 'Continue as Student',
                color: Colors.white,
                textColor: const Color(0xFF1A1C1E),
                onTap: () => _openStudentHome(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStudentHome(BuildContext context, WidgetRef ref) async {
    await activateGuestStudentSession(ref);
    if (!context.mounted) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentLoginPage()),
    );
  }

  Widget _buildHomeButton(
    BuildContext context, {
    required String title,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
