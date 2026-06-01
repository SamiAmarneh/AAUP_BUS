import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_exceptions.dart';
import '../../data/bus_providers.dart';
import '../../data/driver_providers.dart';
import '../../domain/bus_profile.dart';
import '../../domain/bus_status.dart';
import '../../domain/driver_profile.dart';

class BusManagementPage extends ConsumerStatefulWidget {
  const BusManagementPage({super.key});

  @override
  ConsumerState<BusManagementPage> createState() => _BusManagementPageState();
}

class _BusManagementPageState extends ConsumerState<BusManagementPage> {
  String _resolveDriverName(
    String driverUid,
    List<DriverProfile> drivers,
  ) {
    for (final driver in drivers) {
      if (driver.uid == driverUid) {
        return driver.name;
      }
    }
    return 'Driver unavailable';
  }

  void _showBusSheet({
    BusProfile? existingBus,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BusFormSheet(existingBus: existingBus),
    );
  }

  void _confirmDelete(BusProfile bus) {
    var isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Bus'),
          content: Text(
            'Are you sure you want to deactivate bus ${bus.name}?',
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
                            .read(busRepositoryProvider)
                            .deactivateBus(bus.id);
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.pop(dialogContext);
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bus deactivated'),
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
                            content: Text('Could not deactivate bus. Try again.'),
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
    final busesAsync = ref.watch(activeBusesProvider);
    final driversAsync = ref.watch(activeDriversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bus Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: busesAsync.when(
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
                      : 'Could not load buses. Try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(activeBusesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (buses) {
          if (buses.isEmpty) {
            return const Center(
              child: Text(
                'No active buses yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            );
          }

          final drivers = driversAsync.valueOrNull ?? const <DriverProfile>[];

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: buses.length,
            itemBuilder: (context, index) => _buildBusCard(
              buses[index],
              _resolveDriverName(buses[index].driverUid, drivers),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBusSheet(),
        backgroundColor: const Color(0xFF00C853),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildBusCard(BusProfile bus, String driverName) {
    final isActive = bus.status == BusStatus.active;
    final statusBgColor = isActive
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFF5F5F5);
    final statusTextColor =
        isActive ? const Color(0xFF4CAF50) : Colors.blueGrey;
    final statusLabel = isActive ? 'Active' : 'Inactive';

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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sync_alt, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Capacity: ${bus.capacity} seats',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Driver: $driverName',
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
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
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
                  onPressed: () => _showBusSheet(existingBus: bus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF4CAF50),
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
                onTap: () => _confirmDelete(bus),
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

class _BusFormSheet extends ConsumerStatefulWidget {
  const _BusFormSheet({this.existingBus});

  final BusProfile? existingBus;

  @override
  ConsumerState<_BusFormSheet> createState() => _BusFormSheetState();
}

class _BusFormSheetState extends ConsumerState<_BusFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late String _selectedDriverUid;
  var _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingBus != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingBus?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.existingBus?.capacity.toString() ?? '',
    );
    _selectedDriverUid = widget.existingBus?.driverUid ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    final drivers = ref.read(activeDriversProvider).valueOrNull ?? const <DriverProfile>[];
    final driverUid = drivers.any((driver) => driver.uid == _selectedDriverUid)
        ? _selectedDriverUid
        : drivers.firstOrNull?.uid ?? '';

    if (name.isEmpty || _capacityController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Bus name and capacity are required.');
      return;
    }

    if (capacity <= 0) {
      setState(() => _errorMessage = 'Capacity must be greater than zero.');
      return;
    }

    if (driverUid.isEmpty) {
      setState(() => _errorMessage = 'Assigned driver is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(busRepositoryProvider);
      if (_isEditing) {
        await repository.updateBus(
          id: widget.existingBus!.id,
          name: name,
          capacity: capacity,
          driverUid: driverUid,
        );
      } else {
        await repository.createBus(
          name: name,
          capacity: capacity,
          driverUid: driverUid,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Bus updated successfully' : 'Bus added successfully',
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
            ? 'Could not update bus. Try again.'
            : 'Could not add bus. Try again.';
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
    final driversAsync = ref.watch(activeDriversProvider);

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
              _isEditing ? 'Edit Bus' : 'Add New Bus',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildInputLabel('Bus Name'),
            _buildTextField(_nameController, 'e.g., 004'),
            const SizedBox(height: 20),
            _buildInputLabel('Capacity (Seats)'),
            _buildTextField(
              _capacityController,
              'e.g., 50',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _buildInputLabel('Assigned Driver'),
            driversAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text(
                'Could not load drivers.',
                style: TextStyle(color: Colors.red),
              ),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return const Text(
                    'No active drivers available. Add a driver first.',
                    style: TextStyle(color: Colors.orange),
                  );
                }

                final resolvedDriverUid = drivers.any(
                  (driver) => driver.uid == _selectedDriverUid,
                )
                    ? _selectedDriverUid
                    : drivers.first.uid;

                if (_selectedDriverUid.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _selectedDriverUid.isNotEmpty) {
                      return;
                    }
                    setState(() => _selectedDriverUid = resolvedDriverUid);
                  });
                }

                return DropdownButtonFormField<String>(
                  value: resolvedDriverUid,
                  decoration: InputDecoration(
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
                  items: drivers
                      .map(
                        (driver) => DropdownMenuItem<String>(
                          value: driver.uid,
                          child: Text('${driver.name} (${driver.email})'),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _selectedDriverUid = value);
                        },
                );
              },
            ),
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
                  backgroundColor: const Color(0xFF00C853),
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
                        _isEditing ? 'Save Changes' : 'Add Bus',
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
