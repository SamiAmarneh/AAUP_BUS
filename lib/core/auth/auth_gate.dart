import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bus_company/presentation/pages/dashboard_page.dart';
import '../../features/driver/presentation/pages/dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/student/presentation/pages/login_page.dart';
import '../../features/tracking/data/bus_location_providers.dart';
import '../session/session_providers.dart';
import 'auth_providers.dart';
import 'user_role.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const _UnauthenticatedHome();
        }
        return const _AuthenticatedHome();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _UnauthenticatedHome(),
    );
  }
}

class _UnauthenticatedHome extends ConsumerWidget {
  const _UnauthenticatedHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestSession = ref.watch(guestStudentSessionProvider);

    return guestSession.when(
      data: (isGuestStudent) {
        if (isGuestStudent) {
          return const StudentLoginPage(isSessionRoot: true);
        }
        return const HomePage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const HomePage(),
    );
  }
}

class _AuthenticatedHome extends ConsumerWidget {
  const _AuthenticatedHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return switch (profile.role) {
          UserRole.admin => const AdminDashboardPage(),
          UserRole.driver => () {
              ref.watch(busLocationTrackingProvider);
              return const DriverDashboardPage();
            }(),
        };
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const HomePage(),
    );
  }
}
