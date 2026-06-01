import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_exceptions.dart';
import '../../data/driver_providers.dart';
import '../../data/driver_repository.dart';
import '../../domain/driver_profile.dart';

class ManageDriversPage extends ConsumerStatefulWidget {
  const ManageDriversPage({super.key});

  @override
  ConsumerState<ManageDriversPage> createState() => _ManageDriversPageState();
}

class _ManageDriversPageState extends ConsumerState<ManageDriversPage> {
  void _confirmDelete(DriverProfile driver) {
    var isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Account'),
            ],
          ),
          content: Text(
            'Are you sure you want to deactivate the account for ${driver.name}?',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        await ref
                            .read(driverRepositoryProvider)
                            .deactivateDriver(driver.uid);
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.pop(dialogContext);
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Driver account deactivated'),
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
                            content: Text('Could not deactivate driver. Try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDriverSheet() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isCreating = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> handleCreate() async {
            final email = emailController.text.trim();
            final name = nameController.text.trim();
            final phone = phoneController.text.trim();
            final password = passwordController.text;
            final confirmPassword = confirmPasswordController.text;

            if (email.isEmpty ||
                name.isEmpty ||
                phone.isEmpty ||
                password.isEmpty ||
                confirmPassword.isEmpty) {
              setSheetState(() => errorMessage = 'All fields are required.');
              return;
            }

            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
              setSheetState(
                () => errorMessage = 'Enter a valid email address.',
              );
              return;
            }

            if (password.length < minDriverPasswordLength) {
              setSheetState(
                () => errorMessage =
                    'Password must be at least $minDriverPasswordLength characters.',
              );
              return;
            }

            if (password != confirmPassword) {
              setSheetState(() => errorMessage = 'Passwords do not match.');
              return;
            }

            setSheetState(() {
              isCreating = true;
              errorMessage = null;
            });

            try {
              await ref.read(driverRepositoryProvider).createDriver(
                    email: email,
                    name: name,
                    phoneNumber: phone,
                    password: password,
                  );
              if (!sheetContext.mounted) {
                return;
              }
              Navigator.pop(sheetContext);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver account created successfully'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            } on AuthFailure catch (failure) {
              setSheetState(() {
                isCreating = false;
                errorMessage = failure.message;
              });
            } catch (_) {
              setSheetState(() {
                isCreating = false;
                errorMessage = 'Could not create driver. Try again.';
              });
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                  const Text(
                    'Create Driver Account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  _buildInputLabel('Email'),
                  _buildSimpleTextField(
                    emailController,
                    'driver@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Full Name'),
                  _buildSimpleTextField(nameController, 'Enter full name'),
                  const SizedBox(height: 20),
                  _buildInputLabel('Phone Number'),
                  _buildSimpleTextField(
                    phoneController,
                    '059XXXXXXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Password'),
                  _buildSimpleTextField(
                    passwordController,
                    '........',
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Confirm Password'),
                  _buildSimpleTextField(
                    confirmPasswordController,
                    '........',
                    isPassword: true,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isCreating ? null : handleCreate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF247BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isCreating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
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
        },
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      );

  Widget _buildSimpleTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF247BFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Drivers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: driversAsync.when(
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
                      : 'Could not load drivers. Try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(activeDriversProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (drivers) {
          if (drivers.isEmpty) {
            return const Center(
              child: Text(
                'No active drivers yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: drivers.length,
            itemBuilder: (context, index) => _buildDriverCard(drivers[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDriverSheet,
        backgroundColor: const Color(0xFF247BFF),
        shape: const CircleBorder(),
        child: const Icon(Icons.person_add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDriverCard(DriverProfile driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Color(0xFF247BFF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${driver.email} • ${driver.phoneNumber}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(driver),
          ),
        ],
      ),
    );
  }
}
