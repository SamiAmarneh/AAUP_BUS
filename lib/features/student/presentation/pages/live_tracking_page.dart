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
import 'live_tracking_expanded_map_page.dart';
import 'trip_details_page.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  static const LatLng _defaultMapCenter = LatLng(31.9495, 35.9329);
  static const double _busFocusZoom = 14;
  static const double _userFocusZoom = 15;
  static const double _mapBoundsPadding = 48;
  static const double _minimumBoundsSpanDegrees = 0.01;
  static const double _maxUserBusFitDistanceMeters =
      GeoDistanceFormatter.maxReliableDistanceMeters;
  static const int _secondsPerMinute = 60;
  static const int _minutesPerHour = 60;
  static const int _hoursPerDay = 24;

  GoogleMapController? _mapController;
  final ScrollController _listScrollController = ScrollController();
  final Map<String, GlobalKey> _busCardKeys = {};

  LatLng? _userPosition;
  bool _locationPermissionGranted = false;
  bool _hasInitialCameraFit = false;
  bool _hasCenteredMapOnUser = false;
  CameraPosition? _inlineMapInitialCamera;
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
    });

    if (position != null && !_hasCenteredMapOnUser) {
      _hasCenteredMapOnUser = true;
      _centerMapOnPosition(position, animate: false);
    }
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

  Future<void> _openExpandedMap(List<TrackedBusDetails> trackedBuses) async {
    if (trackedBuses.isEmpty) {
      return;
    }

    final selectedBusId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingExpandedMapPage(
          trackedBuses: trackedBuses,
          userPosition: _userPosition,
          locationPermissionGranted: _locationPermissionGranted,
          initialSelectedBusId:
              _selectedBusId ?? trackedBuses.first.tripDetails.bus.id,
        ),
      ),
    );

    if (!mounted || selectedBusId == null) {
      return;
    }

    setState(() => _selectedBusId = selectedBusId);

    TrackedBusDetails? selectedBus;
    for (final trackedBus in trackedBuses) {
      if (trackedBus.tripDetails.bus.id == selectedBusId) {
        selectedBus = trackedBus;
        break;
      }
    }

    if (selectedBus != null) {
      _focusMapOnBus(selectedBus);
      _scrollToBusCard(selectedBusId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackedBusesAsync = ref.watch(studentTrackedBusesProvider);

    ref.listen<AsyncValue<List<TrackedBusDetails>>>(
      studentTrackedBusesProvider,
      (previous, next) {
        next.whenData((trackedBuses) {
          if (_hasInitialCameraFit ||
              trackedBuses.isEmpty ||
              _userPosition != null) {
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
                data: (trackedBuses) =>
                    _buildContent(_sortedBuses(trackedBuses)),
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
    final polylines = _buildRoutePolylines(trackedBuses);
    final initialTarget = _userPosition ??
        (trackedBuses.isNotEmpty
            ? LatLng(
                trackedBuses.first.location.latitude,
                trackedBuses.first.location.longitude,
              )
            : _defaultMapCenter);
    final initialZoom = _userPosition != null
        ? _userFocusZoom
        : (trackedBuses.isNotEmpty ? _busFocusZoom : 10.0);
    _inlineMapInitialCamera ??= CameraPosition(
      target: initialTarget,
      zoom: initialZoom,
    );

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _LiveTrackingInlineMapPanel(
              key: const ValueKey('live_tracking_map_section'),
              initialCamera: _inlineMapInitialCamera!,
              markers: markers,
              polylines: polylines,
              locationPermissionGranted: _locationPermissionGranted,
              onMapCreated: _onInlineMapCreated,
              onExpand: () => _openExpandedMap(trackedBuses),
              onCenterUser: _centerMapOnUser,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              controller: _listScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              children: [
                if (!_locationPermissionGranted) _buildLocationBanner(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Buses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${trackedBuses.length} active',
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                      ),
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
            ),
          ),
        ),
      ],
    );
  }

  void _onInlineMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_userPosition != null) {
      _hasCenteredMapOnUser = true;
      _centerMapOnPosition(_userPosition!, animate: false);
      return;
    }

    final trackedBuses = ref.read(studentTrackedBusesProvider).value;
    if (trackedBuses == null || trackedBuses.isEmpty) {
      return;
    }

    _hasInitialCameraFit = true;
    _fitMapToMarkers(_sortedBuses(trackedBuses));
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
    final busMarkers = trackedBuses
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

    if (_userPosition == null) {
      return busMarkers;
    }

    return {
      Marker(
        markerId: const MarkerId('current_location'),
        position: _userPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
      ...busMarkers,
    };
  }

  Set<Polyline> _buildRoutePolylines(List<TrackedBusDetails> trackedBuses) {
    if (_userPosition == null) {
      return {};
    }

    return trackedBuses.map((trackedBus) {
      final busId = trackedBus.tripDetails.bus.id;
      return Polyline(
        polylineId: PolylineId('route_to_$busId'),
        points: [
          _userPosition!,
          LatLng(trackedBus.location.latitude, trackedBus.location.longitude),
        ],
        color: const Color(0xFF00C853),
        width: 4,
      );
    }).toSet();
  }

  void _selectBusOnMap(TrackedBusDetails trackedBus) {
    final busId = trackedBus.tripDetails.bus.id;
    setState(() => _selectedBusId = busId);
    _focusMapOnBus(trackedBus);
    _scrollToBusCard(busId);
  }

  void _focusMapOnBus(
    TrackedBusDetails trackedBus, {
    bool animate = true,
  }) {
    final cameraUpdate = CameraUpdate.newLatLngZoom(
      LatLng(trackedBus.location.latitude, trackedBus.location.longitude),
      _busFocusZoom,
    );
    if (animate) {
      _mapController?.animateCamera(cameraUpdate);
      return;
    }
    _mapController?.moveCamera(cameraUpdate);
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
    if (_userPosition == null) {
      return;
    }

    _centerMapOnPosition(_userPosition!);
  }

  void _centerMapOnPosition(
    LatLng position, {
    bool animate = true,
  }) {
    final cameraUpdate = CameraUpdate.newLatLngZoom(position, _userFocusZoom);
    if (animate) {
      _mapController?.animateCamera(cameraUpdate);
      return;
    }
    _mapController?.moveCamera(cameraUpdate);
  }

  void _fitMapToMarkers(List<TrackedBusDetails> trackedBuses) {
    if (trackedBuses.isEmpty || _mapController == null) {
      return;
    }

    if (trackedBuses.length == 1) {
      _focusMapOnBus(trackedBuses.first, animate: false);
      return;
    }

    final bounds = _calculateBounds(trackedBuses);
    if (_isDegenerateBounds(bounds)) {
      _focusMapOnBus(trackedBuses.first, animate: false);
      return;
    }

    _mapController?.moveCamera(
      CameraUpdate.newLatLngBounds(bounds, _mapBoundsPadding),
    );
  }

  bool _shouldIncludeUserInBounds(List<TrackedBusDetails> trackedBuses) {
    if (_userPosition == null) {
      return false;
    }

    for (final trackedBus in trackedBuses) {
      final distanceMeters = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        trackedBus.location.latitude,
        trackedBus.location.longitude,
      );
      if (distanceMeters <= _maxUserBusFitDistanceMeters) {
        return true;
      }
    }

    return false;
  }

  bool _isDegenerateBounds(LatLngBounds bounds) {
    const epsilon = 0.0001;
    final latSpan =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    final lngSpan =
        (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    return latSpan < epsilon && lngSpan < epsilon;
  }

  LatLngBounds _expandBoundsIfNeeded(LatLngBounds bounds) {
    if (!_isDegenerateBounds(bounds)) {
      return bounds;
    }

    final centerLat =
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLng =
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
    final halfSpan = _minimumBoundsSpanDegrees / 2;

    return LatLngBounds(
      southwest: LatLng(centerLat - halfSpan, centerLng - halfSpan),
      northeast: LatLng(centerLat + halfSpan, centerLng + halfSpan),
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

    if (_shouldIncludeUserInBounds(trackedBuses)) {
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

    return _expandBoundsIfNeeded(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
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

    return GeoDistanceFormatter.formatAwayLabelFromUser(
      userPosition: _userPosition!,
      trackedBus: trackedBus,
    );
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

class _LiveTrackingInlineMapPanel extends StatefulWidget {
  const _LiveTrackingInlineMapPanel({
    super.key,
    required this.initialCamera,
    required this.markers,
    required this.polylines,
    required this.locationPermissionGranted,
    required this.onMapCreated,
    required this.onExpand,
    required this.onCenterUser,
  });

  final CameraPosition initialCamera;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool locationPermissionGranted;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onExpand;
  final VoidCallback onCenterUser;

  @override
  State<_LiveTrackingInlineMapPanel> createState() =>
      _LiveTrackingInlineMapPanelState();
}

class _LiveTrackingInlineMapPanelState extends State<_LiveTrackingInlineMapPanel> {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: widget.initialCamera,
            mapType: MapType.normal,
            markers: widget.markers,
            polylines: widget.polylines,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            onMapCreated: widget.onMapCreated,
          ),
          Positioned(
            top: 18,
            right: 18,
            child: GestureDetector(
              onTap: widget.onExpand,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Color(0xFF456CFF),
                  size: 22,
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: GestureDetector(
              onTap: widget.onCenterUser,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.navigation,
                  color: widget.locationPermissionGranted
                      ? const Color(0xFF00C853)
                      : const Color(0xFF8E8E93),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
