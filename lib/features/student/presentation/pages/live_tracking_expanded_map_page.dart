import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../tracking/domain/tracked_bus_details.dart';
import '../../../trips/domain/trip_status.dart';
import '../utils/geo_distance_formatter.dart';

class LiveTrackingExpandedMapPage extends StatefulWidget {
  const LiveTrackingExpandedMapPage({
    super.key,
    required this.trackedBuses,
    required this.userPosition,
    required this.locationPermissionGranted,
    this.initialSelectedBusId,
  });

  final List<TrackedBusDetails> trackedBuses;
  final LatLng? userPosition;
  final bool locationPermissionGranted;
  final String? initialSelectedBusId;

  @override
  State<LiveTrackingExpandedMapPage> createState() =>
      _LiveTrackingExpandedMapPageState();
}

class _LiveTrackingExpandedMapPageState
    extends State<LiveTrackingExpandedMapPage> {
  static const double _busFocusZoom = 15;
  static const double _userFocusZoom = 15;
  static const double _mapBoundsPadding = 64;
  static const double _minimumBoundsSpanDegrees = 0.01;
  static const double _maxUserBusFitDistanceMeters =
      GeoDistanceFormatter.maxReliableDistanceMeters;

  GoogleMapController? _mapController;
  String? _selectedBusId;

  @override
  void initState() {
    super.initState();
    _selectedBusId = widget.initialSelectedBusId ??
        (widget.trackedBuses.isNotEmpty
            ? widget.trackedBuses.first.tripDetails.bus.id
            : null);
  }

  TrackedBusDetails? get _selectedBus {
    if (_selectedBusId == null) {
      return null;
    }

    for (final trackedBus in widget.trackedBuses) {
      if (trackedBus.tripDetails.bus.id == _selectedBusId) {
        return trackedBus;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedBus = _selectedBus;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraTarget(),
              zoom:
                  widget.userPosition != null ? _userFocusZoom : _busFocusZoom,
            ),
            markers: _buildMarkers(),
            polylines: _buildRoutePolylines(),
            myLocationEnabled: widget.locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitInitialCamera();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context, _selectedBusId),
                  ),
                  const Spacer(),
                  _buildCircleButton(
                    icon: Icons.my_location,
                    onTap: _centerOnUser,
                    iconColor: widget.locationPermissionGranted
                        ? const Color(0xFF00C853)
                        : const Color(0xFF8E8E93),
                  ),
                ],
              ),
            ),
          ),
          if (selectedBus != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: _buildSelectedBusInfo(selectedBus),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBusSelector(),
          ),
        ],
      ),
    );
  }

  LatLng _initialCameraTarget() {
    if (widget.userPosition != null) {
      return widget.userPosition!;
    }

    return widget.trackedBuses.isNotEmpty
        ? LatLng(
            widget.trackedBuses.first.location.latitude,
            widget.trackedBuses.first.location.longitude,
          )
        : const LatLng(31.9495, 35.9329);
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1F2937),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildSelectedBusInfo(TrackedBusDetails trackedBus) {
    final distanceLabel = widget.userPosition == null
        ? 'Distance unavailable'
        : GeoDistanceFormatter.formatAwayLabelFromUser(
            userPosition: widget.userPosition!,
            trackedBus: trackedBus,
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trackedBus.routeLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trackedBus.busName,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, size: 16, color: Color(0xFF00C853)),
              const SizedBox(width: 6),
              Text(
                distanceLabel,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select a bus',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.trackedBuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final trackedBus = widget.trackedBuses[index];
                final busId = trackedBus.tripDetails.bus.id;
                final isSelected = _selectedBusId == busId;

                return ChoiceChip(
                  label: Text(trackedBus.busName),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00C853).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF00C853)
                        : const Color(0xFF374151),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => _selectBus(trackedBus),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final busMarkers = widget.trackedBuses.map((trackedBus) {
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
        onTap: () => _selectBus(trackedBus),
      );
    }).toSet();

    if (widget.userPosition == null) {
      return busMarkers;
    }

    return {
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.userPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
      ...busMarkers,
    };
  }

  Set<Polyline> _buildRoutePolylines() {
    if (widget.userPosition == null) {
      return {};
    }

    return widget.trackedBuses.map((trackedBus) {
      final busId = trackedBus.tripDetails.bus.id;
      return Polyline(
        polylineId: PolylineId('route_to_$busId'),
        points: [
          widget.userPosition!,
          LatLng(trackedBus.location.latitude, trackedBus.location.longitude),
        ],
        color: const Color(0xFF00C853),
        width: 4,
      );
    }).toSet();
  }

  void _selectBus(TrackedBusDetails trackedBus) {
    setState(() => _selectedBusId = trackedBus.tripDetails.bus.id);
    _focusOnBus(trackedBus);
  }

  void _focusOnBus(TrackedBusDetails trackedBus) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(trackedBus.location.latitude, trackedBus.location.longitude),
        _busFocusZoom,
      ),
    );
  }

  void _centerOnUser() {
    if (widget.userPosition == null || _mapController == null) {
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(widget.userPosition!, _busFocusZoom),
    );
  }

  void _fitInitialCamera() {
    if (_mapController == null) {
      return;
    }

    if (widget.userPosition != null) {
      _centerOnUser();
      return;
    }

    if (widget.trackedBuses.isEmpty) {
      return;
    }

    if (widget.trackedBuses.length == 1) {
      _focusOnBus(widget.trackedBuses.first);
      return;
    }

    final bounds = _calculateBounds();
    if (_isDegenerateBounds(bounds)) {
      _focusOnBus(widget.trackedBuses.first);
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, _mapBoundsPadding),
    );
  }

  bool _shouldIncludeUserInBounds() {
    if (widget.userPosition == null) {
      return false;
    }

    for (final trackedBus in widget.trackedBuses) {
      final distanceMeters = Geolocator.distanceBetween(
        widget.userPosition!.latitude,
        widget.userPosition!.longitude,
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

  LatLngBounds _calculateBounds() {
    final points = widget.trackedBuses
        .map(
          (trackedBus) => LatLng(
            trackedBus.location.latitude,
            trackedBus.location.longitude,
          ),
        )
        .toList();

    if (_shouldIncludeUserInBounds()) {
      points.add(widget.userPosition!);
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
}
