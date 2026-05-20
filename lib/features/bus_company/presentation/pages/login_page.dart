import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_exceptions.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/user_role.dart';

class BusCompanyLoginPage extends ConsumerStatefulWidget {
  const BusCompanyLoginPage({super.key});

  @override
  ConsumerState<BusCompanyLoginPage> createState() => _BusCompanyLoginPageState();
}

class _BusCompanyLoginPageState extends ConsumerState<BusCompanyLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
            expectedRole: UserRole.admin,
          );
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _errorMessage = failure.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Login failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email to reset your password.');
      return;
    }

    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on AuthFailure catch (failure) {
      setState(() => _errorMessage = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5E6E7C), size: 16),
          label: const Text('Back', style: TextStyle(color: Color(0xFF5E6E7C), fontSize: 16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF247BFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.person_outline, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Bus Company Login',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your credentials to continue',
              style: TextStyle(color: Color(0xFF5E6E7C), fontSize: 15),
            ),
            const SizedBox(height: 45),
            _buildTextField(
              label: 'Email',
              hint: 'admin@aaup.edu',
              controller: _emailController,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Password',
              hint: '........',
              controller: _passwordController,
              isPassword: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF247BFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E), fontSize: 15)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
