import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/permissions/location_permission_service.dart';
import '../../../tracking/domain/bus_location_constants.dart';
import '../../../tracking/domain/tracked_bus_details.dart';
import '../../../trips/domain/trip_status.dart';
import '../../data/student_live_tracking_providers.dart';
import '../../domain/models/trip_model.dart';
import '../utils/geo_distance_formatter.dart';
import 'trip_details_page.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  static const LatLng _defaultMapCenter = LatLng(31.9495, 35.9329);
  static const double _busFocusZoom = 14;
  static const double _mapBoundsPadding = 48;
  static const int _secondsPerMinute = 60;
  static const int _minutesPerHour = 60;
  static const int _hoursPerDay = 24;

  GoogleMapController? _mapController;
  final ScrollController _listScrollController = ScrollController();
  final Map<String, GlobalKey> _busCardKeys = {};

  LatLng? _userPosition;
  bool _locationPermissionGranted = false;
  bool _hasInitialCameraFit = false;
  String? _selectedBusId;

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosition() async {
    final permissionStatus = await LocationPermissionService().ensureGranted();
    final isGranted = permissionStatus == LocationPermissionStatus.granted;

    LatLng? position;
    if (isGranted) {
      try {
        final isLocationServiceEnabled =
            await Geolocator.isLocationServiceEnabled();
        if (isLocationServiceEnabled) {
          final currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          position = LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          );
        }
      } catch (_) {
        position = null;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _locationPermissionGranted = isGranted && position != null;
      _userPosition = position;
      _hasInitialCameraFit = false;
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      refreshStudentLiveTracking(ref),
      _loadUserPosition(),
    ]);
  }

  List<TrackedBusDetails> _sortedBuses(List<TrackedBusDetails> trackedBuses) {
    if (_userPosition == null) {
      return trackedBuses;
    }

    return GeoDistanceFormatter.sortByNearest(
      userPosition: _userPosition!,
      trackedBuses: trackedBuses,
    );
  }

  GlobalKey _cardKeyForBus(String busId) {
    return _busCardKeys.putIfAbsent(busId, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    final trackedBusesAsync = ref.watch(studentTrackedBusesProvider);

    ref.listen<AsyncValue<List<TrackedBusDetails>>>(
      studentTrackedBusesProvider,
      (previous, next) {
        next.whenData((trackedBuses) {
          if (_hasInitialCameraFit || trackedBuses.isEmpty) {
            return;
          }
          _hasInitialCameraFit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _fitMapToMarkers(_sortedBuses(trackedBuses));
            }
          });
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: trackedBusesAsync.when(
                data: (trackedBuses) => RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: _buildContent(_sortedBuses(trackedBuses)),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unable to load bus locations. Please try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _handleRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF00C853),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Live Bus Tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleRefresh,
            child: const Icon(
              Icons.sync,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<TrackedBusDetails> trackedBuses) {
    final markers = _buildMarkers(trackedBuses);

    return ListView(
      controller: _listScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        if (!_locationPermissionGranted) _buildLocationBanner(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userPosition ?? _defaultMapCenter,
                      zoom: 10,
                    ),
                    mapType: MapType.normal,
                    markers: markers,
                    zoomControlsEnabled: false,
                    myLocationEnabled: _locationPermissionGranted,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitMapToMarkers(trackedBuses);
                    },
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    child: GestureDetector(
                      onTap: _centerMapOnUser,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: _locationPermissionGranted
                              ? const Color(0xFF00C853)
                              : const Color(0xFF8E8E93),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Buses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '${trackedBuses.length} active',
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (trackedBuses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No buses are currently broadcasting location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6C7A93), fontSize: 14),
            ),
          )
        else
          ...trackedBuses.map(_buildBusCard),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF007AFF),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tracking updates every ${BusLocationConstants.publishIntervalSeconds} seconds. '
                  'Tap a bus to book. Full buses are hidden.',
                  style: const TextStyle(
                    color: Color(0xFF6C7A93),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enable location to sort buses by distance from you.',
              style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadUserPosition,
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<TrackedBusDetails> trackedBuses) {
    return trackedBuses
        .map(
          (trackedBus) {
            final busId = trackedBus.tripDetails.bus.id;
            final isSelected = _selectedBusId == busId;

            return Marker(
              markerId: MarkerId(busId),
              position: LatLng(
                trackedBus.location.latitude,
                trackedBus.location.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isSelected
                    ? BitmapDescriptor.hueOrange
                    : _markerHueForStatus(trackedBus.tripDetails.trip.status),
              ),
              infoWindow: InfoWindow(
                title: trackedBus.routeLabel,
                snippet: trackedBus.busName,
              ),
              onTap: () => _selectBusOnMap(trackedBus),
            );
          },
        )
        .toSet();
  }

  void _selectBusOnMap(TrackedBusDetails trackedBus) {
    final busId = trackedBus.tripDetails.bus.id;
    setState(() => _selectedBusId = busId);
    _focusMapOnBus(trackedBus);
    _scrollToBusCard(busId);
  }

  void _focusMapOnBus(TrackedBusDetails trackedBus) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(trackedBus.location.latitude, trackedBus.location.longitude),
        _busFocusZoom,
      ),
    );
  }

  void _scrollToBusCard(String busId) {
    final cardKey = _busCardKeys[busId];
    final cardContext = cardKey?.currentContext;
    if (cardContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      cardContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  void _centerMapOnUser() {
    if (_userPosition == null || _mapController == null) {
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_userPosition!, _busFocusZoom),
    );
  }

  void _fitMapToMarkers(List<TrackedBusDetails> trackedBuses) {
    if (trackedBuses.isEmpty || _mapController == null) {
      return;
    }

    if (trackedBuses.length == 1 && _userPosition == null) {
      _focusMapOnBus(trackedBuses.first);
      return;
    }

    final bounds = _calculateBounds(trackedBuses);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, _mapBoundsPadding),
    );
  }

  LatLngBounds _calculateBounds(List<TrackedBusDetails> trackedBuses) {
    final points = trackedBuses
        .map(
          (trackedBus) => LatLng(
            trackedBus.location.latitude,
            trackedBus.location.longitude,
          ),
        )
        .toList();

    if (_userPosition != null) {
      points.add(_userPosition!);
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  double _markerHueForStatus(String status) {
    return switch (status) {
      TripStatus.onTheWay => BitmapDescriptor.hueGreen,
      TripStatus.waitingPassengers => BitmapDescriptor.hueAzure,
      _ => BitmapDescriptor.hueViolet,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      TripStatus.onTheWay => const Color(0xFF34C759),
      TripStatus.waitingPassengers => const Color(0xFF5AC8FA),
      _ => const Color(0xFF8E8E93),
    };
  }

  String _formatDistanceFromMe(TrackedBusDetails trackedBus) {
    if (_userPosition == null) {
      return 'Distance unavailable';
    }

    final distanceMeters = GeoDistanceFormatter.distanceMetersFromUser(
      userPosition: _userPosition!,
      trackedBus: trackedBus,
    );
    return GeoDistanceFormatter.formatAwayLabel(distanceMeters);
  }

  String _formatUpdatedAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inSeconds < _secondsPerMinute) {
      return 'Updated just now';
    }
    if (difference.inMinutes < _minutesPerHour) {
      return 'Updated ${difference.inMinutes} min ago';
    }
    if (difference.inHours < _hoursPerDay) {
      return 'Updated ${difference.inHours} hr ago';
    }
    return 'Updated ${difference.inDays} day ago';
  }

  void _openTripDetails(TrackedBusDetails trackedBus) {
    final trip = Trip.fromTripDetails(trackedBus.tripDetails);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(trip: trip),
      ),
    );
  }

  Widget _buildBusCard(TrackedBusDetails trackedBus) {
    final busId = trackedBus.tripDetails.bus.id;
    final statusColor = _statusColor(trackedBus.tripDetails.trip.status);
    final isSelected = _selectedBusId == busId;

    return InkWell(
      key: _cardKeyForBus(busId),
      onTap: () => _openTripDetails(trackedBus),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: const Color(0xFF00C853), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trackedBus.routeLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    trackedBus.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8E8E93),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trackedBus.busName,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFF8E8E93),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatUpdatedAgo(trackedBus.location.timestamp),
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.place, size: 16, color: Color(0xFF8E8E93)),
                const SizedBox(width: 6),
                Text(
                  _formatDistanceFromMe(trackedBus),
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
