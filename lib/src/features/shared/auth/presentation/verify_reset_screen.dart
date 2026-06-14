import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_provider.dart';

class VerifyResetScreen extends ConsumerStatefulWidget {
  const VerifyResetScreen({super.key});

  @override
  ConsumerState<VerifyResetScreen> createState() => _VerifyResetScreenState();
}

class _VerifyResetScreenState extends ConsumerState<VerifyResetScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  Timer? _timer;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus first field
    Future.microtask(() {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF081C15),
                  Color(0xFF1B4332),
                  Color(0xFF2D6A4F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: const Icon(
                                Icons.eco_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'EarthCare',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Verifikasi Kode',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0C3B2E),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Masukkan 6-digit kode verifikasi yang telah\nkami kirimkan ke email Anda.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(6, (index) {
                                        return SizedBox(
                                          width: 40,
                                          height: 50,
                                          child: TextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: "",
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withValues(alpha: 0.5),
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Colors.black12,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              if (value.isNotEmpty &&
                                                  index < 5) {
                                                _focusNodes[index + 1]
                                                    .requestFocus();
                                              } else if (value.isEmpty &&
                                                  index > 0) {
                                                _focusNodes[index - 1]
                                                    .requestFocus();
                                              }
                                            },
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      'Tidak menerima kode?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _countdown > 0
                                        ? Text(
                                            'Kirim ulang kode (00:${_countdown.toString().padLeft(2, '0')})',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors
                                                  .black38, // Dim color while waiting
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () async {
                                              final email =
                                                  authState.resetEmail;
                                              if (email != null) {
                                                await ref
                                                    .read(authProvider.notifier)
                                                    .forgotPassword(email);
                                              }
                                              _startTimer();
                                            },
                                            child: const Text(
                                              'Kirim ulang kode',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(
                                                  0xFF1B4332,
                                                ), // Active color
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(height: 32),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1B4332,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: authState.isLoading
                                          ? null
                                          : () async {
                                              final code = _controllers
                                                  .map((c) => c.text)
                                                  .join();
                                              if (code.length < 6) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: const [
                                                        Icon(
                                                          Icons.error_outline,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            'Silakan masukkan 6 digit kode terlebih dahulu',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors
                                                        .redAccent
                                                        .shade700,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    elevation: 4,
                                                  ),
                                                );
                                                return;
                                              }

                                              final success = await ref
                                                  .read(authProvider.notifier)
                                                  .verifyForgotPassword(code);
                                              if (!context.mounted) return;
                                              if (success) {
                                                context.push(
                                                  '/new-password',
                                                ); // Goes to new password
                                              } else {
                                                final error =
                                                    ref
                                                        .read(authProvider)
                                                        .error ??
                                                    'Terjadi kesalahan';
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(error),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                      child: authState.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Verifikasi',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.5),
                                      ),
                                      onPressed: () {
                                        context.pop();
                                      },
                                      child: const Text(
                                        'Ganti Email',
                                        style: TextStyle(
                                          color: Color(0xFF1B4332),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
