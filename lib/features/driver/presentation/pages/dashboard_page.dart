import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_actions.dart';
import '../../../../core/permissions/location_permission_service.dart';
import '../../../../core/auth/auth_exceptions.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/user_role.dart';
import '../../../bus_company/data/bus_providers.dart';
import '../../../bus_company/data/route_providers.dart';
import '../../../bus_company/domain/route_profile.dart';
import '../../data/driver_reservation_providers.dart';
import '../../../student/domain/models/reservation_profile.dart';
import '../../../student/domain/reservation_status.dart';
import '../../../trips/data/trip_providers.dart';
import '../../../trips/domain/trip_details.dart';
import '../../../trips/domain/trip_status.dart';
import 'scanner_page.dart';
import 'trip_history_page.dart';

class DriverDashboardPage extends ConsumerWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (profile) {
        if (profileAsync.isRefreshing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile.role != UserRole.driver) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref.read(authRepositoryProvider).signOut();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _DriverDashboardBody(
          driverName: profile.displayName,
          driverUid: profile.uid,
          onLogout: () => confirmLogout(context, ref),
        );
      },
    );
  }
}

class _DriverDashboardBody extends ConsumerStatefulWidget {
  const _DriverDashboardBody({
    required this.driverName,
    required this.driverUid,
    required this.onLogout,
  });

  final String driverName;
  final String driverUid;
  final VoidCallback onLogout;

  @override
  ConsumerState<_DriverDashboardBody> createState() =>
      _DriverDashboardBodyState();
}

class _DriverDashboardBodyState extends ConsumerState<_DriverDashboardBody> {
  bool _isActionInProgress = false;

  Future<void> _runTripAction(Future<void> Function() action) async {
    if (_isActionInProgress) {
      return;
    }

    setState(() => _isActionInProgress = true);
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final permissionStatus =
        await LocationPermissionService().ensureGranted();
    if (!mounted) {
      return false;
    }

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        return true;
      case LocationPermissionStatus.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to create a trip.'),
          ),
        );
        return false;
      case LocationPermissionStatus.permanentlyDenied:
        await _showLocationPermissionDialog();
        return false;
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location access is required to create a trip. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final opened = await openAppSettings();
              if (!opened && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open settings.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTripSheet() async {
    final hasLocationPermission = await _ensureLocationPermission();
    if (!hasLocationPermission) {
      return;
    }

    final assignedBus = ref.read(assignedBusForDriverProvider).valueOrNull;
    if (assignedBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bus assigned. Contact your administrator.'),
        ),
      );
      return;
    }

    List<RouteProfile> routes;
    try {
      routes = await ref.read(routeRepositoryProvider).fetchActiveRoutes();
      ref.invalidate(activeRoutesProvider);
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load routes. Please try again.'),
        ),
      );
      return;
    }

    if (routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active routes available.')),
      );
      return;
    }

    final selectedRouteId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateTripSheet(routes: routes),
    );

    if (selectedRouteId == null || !mounted) {
      return;
    }

    await _runTripAction(() async {
      await ref.read(tripRepositoryProvider).createTrip(
            driverUid: widget.driverUid,
            routeId: selectedRouteId,
          );
      ref.invalidate(activeTripForDriverProvider);
      ref.invalidate(driverActiveTripDetailsStreamProvider);
    });
  }

  Future<void> _startTrip(String tripId) async {
    await _runTripAction(
      () => ref.read(tripRepositoryProvider).startTrip(tripId),
    );
  }

  Future<void> _completeTrip(String tripId) async {
    await _runTripAction(
      () => ref.read(tripRepositoryProvider).completeTrip(tripId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripDetailsAsync = ref.watch(driverActiveTripDetailsStreamProvider);
    final assignedBusAsync = ref.watch(assignedBusForDriverProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: tripDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildDashboardContent(
          tripDetails: null,
          assignedBusName: assignedBusAsync.valueOrNull?.name,
          hasAssignedBus: assignedBusAsync.valueOrNull != null,
          errorMessage: error is AuthFailure
              ? error.message
              : 'Could not load trip details.',
        ),
        data: (tripDetails) => _buildDashboardContent(
          tripDetails: tripDetails,
          assignedBusName: assignedBusAsync.valueOrNull?.name,
          hasAssignedBus: assignedBusAsync.valueOrNull != null,
        ),
      ),
    );
  }

  Widget _buildDashboardContent({
    required TripDetails? tripDetails,
    required String? assignedBusName,
    required bool hasAssignedBus,
    String? errorMessage,
  }) {
    final trip = tripDetails?.trip;
    final routeLabel = tripDetails?.routeLabel ?? 'No active trip';
    final busLabel = tripDetails?.bus.name ?? assignedBusName ?? '—';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 60,
            left: 25,
            right: 25,
            bottom: 30,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
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
                        widget.driverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: widget.onLogout,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip == null ? 'Current Trip' : 'Active Trip',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            routeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Bus',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          busLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(25),
            children: [
              if (errorMessage != null) ...[
                _buildInfoBanner(errorMessage, isError: true),
                const SizedBox(height: 16),
              ],
              if (!hasAssignedBus) ...[
                _buildInfoBanner(
                  'No bus assigned. Contact your administrator.',
                ),
                const SizedBox(height: 16),
              ],
              _buildTripActionCard(tripDetails),
              if (tripDetails != null) ...[
                const SizedBox(height: 20),
                _buildPassengersSection(tripDetails),
              ],
              const SizedBox(height: 20),
              const Text(
                'Main Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 20),
              _buildLargeActionCard(
                context,
                'Scan Student QR',
                'Verify student check-in for this trip',
                Icons.qr_code_scanner,
                const Color(0xFFE8F5E9),
                const Color(0xFF4CAF50),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverScannerPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildLargeActionCard(
                context,
                'Trip History',
                'View all your past and current trips',
                Icons.history,
                const Color(0xFFE3F2FD),
                const Color(0xFF1976D2),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TripHistoryPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripActionCard(TripDetails? tripDetails) {
    final trip = tripDetails?.trip;
    final hasAssignedBus =
        ref.watch(assignedBusForDriverProvider).valueOrNull != null;

    if (trip == null) {
      return _buildActionButton(
        label: 'Create Trip',
        icon: Icons.add_road,
        color: const Color(0xFF4CAF50),
        onPressed: hasAssignedBus && !_isActionInProgress
            ? _showCreateTripSheet
            : null,
      );
    }

    final isWaiting = trip.status == TripStatus.waitingPassengers;
    final actionLabel = isWaiting ? 'Start Trip' : 'Mark as Arrived';
    final actionIcon = isWaiting
        ? Icons.play_arrow_rounded
        : Icons.flag_rounded;
    final action = isWaiting
        ? () => _startTrip(trip.id)
        : () => _completeTrip(trip.id);

    return _buildActionButton(
      label: actionLabel,
      icon: actionIcon,
      color: isWaiting ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
      onPressed: _isActionInProgress ? null : action,
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isActionInProgress
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          _isActionInProgress ? 'Please wait...' : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFC62828) : const Color(0xFF6D4C41),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPassengersSection(TripDetails tripDetails) {
    final tripId = tripDetails.trip.id;
    final reservationsAsync = ref.watch(driverTripPassengersProvider(tripId));
    final bookedCount = tripDetails.trip.totalPassengers;
    final seatCapacity = tripDetails.bus.capacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Passengers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E),
              ),
            ),
            Text(
              '$bookedCount booked / $seatCapacity seats',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reservationsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => _buildInfoBanner(
            'Could not load passenger bookings.',
            isError: true,
          ),
          data: (reservations) {
            if (reservations.isEmpty) {
              return _buildInfoBanner('No passengers booked yet.');
            }

            return Column(
              children: reservations
                  .map(_buildPassengerCard)
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPassengerCard(ReservationProfile reservation) {
    final coordinates = reservation.pickupCoordinates;
    final hasCoordinates = coordinates != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reservation.phoneNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ),
              _buildReservationStatusChip(reservation.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF757575),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reservation.pickupLocation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (hasCoordinates) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _openPickupOnMaps(coordinates),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Open in Maps'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReservationStatusChip(String status) {
    final label = ReservationStatus.displayLabel(status);
    final isBoarded = status == ReservationStatus.boarded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBoarded
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isBoarded
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE65100),
        ),
      ),
    );
  }

  Future<void> _openPickupOnMaps(GeoPoint coordinates) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${coordinates.latitude},${coordinates.longitude}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (launched || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open maps for this pickup.')),
    );
  }

  Widget _buildLargeActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: iconColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: iconColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CreateTripSheet extends StatefulWidget {
  const _CreateTripSheet({required this.routes});

  final List<RouteProfile> routes;

  @override
  State<_CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<_CreateTripSheet> {
  String? _selectedRouteId;

  static const double _maxListHeight = 280;

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.routes.first.id;
  }

  String _routeLabel(RouteProfile route) {
    final routeName = route.routeName.trim();
    final pathLabel = '${route.startLocation} → ${route.endLocation}';
    return routeName.isEmpty ? pathLabel : '$routeName ($pathLabel)';
  }

  @override
  Widget build(BuildContext context) {
    final listHeight = widget.routes.length * 72.0;
    final resolvedListHeight = listHeight > _maxListHeight
        ? _maxListHeight
        : listHeight;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.only(
        left: 25,
        right: 25,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Create Trip',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a route for your new trip.',
            style: TextStyle(fontSize: 15, color: Colors.blueGrey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: resolvedListHeight,
            child: ListView.separated(
              itemCount: widget.routes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final route = widget.routes[index];
                final isSelected = _selectedRouteId == route.id;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _routeLabel(route),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '₪ ${route.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF247BFF),
                      fontSize: 14,
                    ),
                  ),
                  leading: Radio<String>(
                    value: route.id,
                    groupValue: _selectedRouteId,
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (value) =>
                        setState(() => _selectedRouteId = value),
                  ),
                  onTap: () => setState(() => _selectedRouteId = route.id),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedRouteId == null
                  ? null
                  : () => Navigator.pop(context, _selectedRouteId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Create Trip',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
