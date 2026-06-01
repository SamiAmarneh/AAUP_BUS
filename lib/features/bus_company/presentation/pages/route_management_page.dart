import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_exceptions.dart';
import '../../data/route_providers.dart';
import '../../domain/route_profile.dart';
import '../../domain/route_status.dart';

const Color _routePrimaryColor = Color(0xFFFF9800);

class RouteManagementPage extends ConsumerStatefulWidget {
  const RouteManagementPage({super.key});

  @override
  ConsumerState<RouteManagementPage> createState() =>
      _RouteManagementPageState();
}

class _RouteManagementPageState extends ConsumerState<RouteManagementPage> {
  void _showRouteSheet({RouteProfile? existingRoute}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RouteFormSheet(existingRoute: existingRoute),
    );
  }

  void _confirmDelete(RouteProfile route) {
    var isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Route'),
          content: Text(
            'Are you sure you want to deactivate route ${route.routeName}?',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        await ref
                            .read(routeRepositoryProvider)
                            .deactivateRoute(route.id);
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.pop(dialogContext);
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Route deactivated'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } on AuthFailure catch (failure) {
                        setDialogState(() => isDeleting = false);
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(failure.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (_) {
                        setDialogState(() => isDeleting = false);
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not deactivate route. Try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(activeRoutesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: _routePrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Route Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  error is AuthFailure
                      ? error.message
                      : 'Could not load routes. Try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(activeRoutesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Text(
                'No active routes yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: routes.length,
            itemBuilder: (context, index) => _buildRouteCard(routes[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRouteSheet(),
        backgroundColor: _routePrimaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildRouteCard(RouteProfile route) {
    final isActive = route.status == RouteStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route, color: _routePrimaryColor),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${route.startLocation} → ${route.endLocation}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? _routePrimaryColor : Colors.blueGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRouteSheet(existingRoute: route),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3E0),
                    foregroundColor: _routePrimaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _confirmDelete(route),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteFormSheet extends ConsumerStatefulWidget {
  const _RouteFormSheet({this.existingRoute});

  final RouteProfile? existingRoute;

  @override
  ConsumerState<_RouteFormSheet> createState() => _RouteFormSheetState();
}

class _RouteFormSheetState extends ConsumerState<_RouteFormSheet> {
  late final TextEditingController _routeNameController;
  late final TextEditingController _startLocationController;
  late final TextEditingController _endLocationController;
  var _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingRoute != null;

  @override
  void initState() {
    super.initState();
    _routeNameController = TextEditingController(
      text: widget.existingRoute?.routeName ?? '',
    );
    _startLocationController = TextEditingController(
      text: widget.existingRoute?.startLocation ?? '',
    );
    _endLocationController = TextEditingController(
      text: widget.existingRoute?.endLocation ?? '',
    );
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final routeName = _routeNameController.text.trim();
    final startLocation = _startLocationController.text.trim();
    final endLocation = _endLocationController.text.trim();

    if (routeName.isEmpty ||
        startLocation.isEmpty ||
        endLocation.isEmpty) {
      setState(
        () => _errorMessage = 'Route name, start location, and end location are required.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(routeRepositoryProvider);
      if (_isEditing) {
        await repository.updateRoute(
          id: widget.existingRoute!.id,
          routeName: routeName,
          startLocation: startLocation,
          endLocation: endLocation,
        );
      } else {
        await repository.createRoute(
          routeName: routeName,
          startLocation: startLocation,
          endLocation: endLocation,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Route updated successfully'
                : 'Route added successfully',
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } on AuthFailure catch (failure) {
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = _isEditing
            ? 'Could not update route. Try again.'
            : 'Could not add route. Try again.';
      });
    }
  }

  Widget _buildInputLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
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
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      child: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 25),
            Text(
              _isEditing ? 'Edit Route' : 'Add New Route',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildInputLabel('Route Name'),
            _buildTextField(_routeNameController, 'e.g., Morning Route'),
            const SizedBox(height: 20),
            _buildInputLabel('Start Location'),
            _buildTextField(_startLocationController, 'e.g., jenin'),
            const SizedBox(height: 20),
            _buildInputLabel('End Location'),
            _buildTextField(_endLocationController, 'e.g., university'),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _routePrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Route',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
