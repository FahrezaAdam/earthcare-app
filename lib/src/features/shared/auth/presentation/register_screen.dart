import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isHoveringLogin = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Color
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF081C15), // Darker shade for depth
                  Color(0xFF1B4332), // Primary color
                  Color(0xFF2D6A4F), // Lighter shade
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Glassmorphism Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.eco,
                                  color: Color(0xFF0C3B2E),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'EarthCare',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C3B2E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Daftar Akun Baru',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bergabunglah dalam menjaga kelestarian lingkungan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Nama Lengkap
                            _buildLabel('Nama Lengkap'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              'John Doe',
                              Icons.person_outline,
                              _nameController,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _buildLabel('Email'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              'example@email.com',
                              Icons.email_outlined,
                              _emailController,
                            ),
                            const SizedBox(height: 16),

                            // Nomor Telepon
                            _buildLabel('Nomor Telepon'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              '081234567890',
                              Icons.phone_outlined,
                              _phoneController,
                            ),
                            const SizedBox(height: 16),

                            // Kata Sandi
                            _buildLabel('Kata Sandi'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              '........',
                              obscurePassword,
                              () {
                                setState(
                                  () => obscurePassword = !obscurePassword,
                                );
                              },
                              _passwordController,
                            ),
                            const SizedBox(height: 16),

                            // Konfirmasi Kata Sandi
                            _buildLabel('Konfirmasi Kata Sandi'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              '........',
                              obscureConfirmPassword,
                              () {
                                setState(
                                  () => obscureConfirmPassword =
                                      !obscureConfirmPassword,
                                );
                              },
                              _confirmPasswordController,
                            ),
                            const SizedBox(height: 32),

                            // Register Button
                            Consumer(
                              builder: (context, ref, child) {
                                final authState = ref.watch(authProvider);

                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B4332),
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: authState.isLoading
                                      ? null
                                      : () async {
                                          final name = _nameController.text
                                              .trim();
                                          final email = _emailController.text
                                              .trim();
                                          final phone = _phoneController.text
                                              .trim();
                                          final password =
                                              _passwordController.text;
                                          final confirmPassword =
                                              _confirmPasswordController.text;

                                          if (name.isEmpty ||
                                              email.isEmpty ||
                                              phone.isEmpty ||
                                              password.isEmpty ||
                                              confirmPassword.isEmpty) {
                                            _showErrorSnackbar(
                                              'Semua kolom harus diisi terlebih dahulu',
                                            );
                                            return;
                                          }

                                          if (password != confirmPassword) {
                                            _showErrorSnackbar(
                                              'Kata sandi tidak sama',
                                            );
                                            return;
                                          }

                                          final success = await ref
                                              .read(authProvider.notifier)
                                              .sendOtp(name, email, password, phone);

                                          if (!context.mounted) return;

                                          if (success) {
                                            context.push('/verify');
                                          } else {
                                            final error = ref
                                                .read(authProvider)
                                                .error;
                                            _showErrorSnackbar(
                                              error ?? 'Gagal mendaftar',
                                            );
                                          }
                                        },
                                  child: authState.isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Daftar Sekarang',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => isHoveringLogin = true),
                                  onExit: (_) =>
                                      setState(() => isHoveringLogin = false),
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      context.pop();
                                    },
                                    child: Text(
                                      'Masuk di sini',
                                      style: TextStyle(
                                        color: const Color(0xFF1B4332),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        decoration: isHoveringLogin
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String hint,
    bool obscure,
    VoidCallback onToggle,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.black54,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
