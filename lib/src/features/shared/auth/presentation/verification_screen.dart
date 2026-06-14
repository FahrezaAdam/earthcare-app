import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
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

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Logo & Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
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

                        // Glassmorphism Card
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
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

                                    // OTP Boxes
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

                                    // Resend Code
                                    const Text(
                                      'Tidak menerima kode?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _secondsRemaining == 0
                                          ? () async {
                                              final success = await ref
                                                  .read(authProvider.notifier)
                                                  .resendOtp();

                                              if (!context.mounted) return;

                                              if (success) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Kode OTP baru telah dikirim',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green.shade600,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                setState(() {
                                                  _startTimer();
                                                });
                                              } else {
                                                final error = ref
                                                    .read(authProvider)
                                                    .error;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      error ??
                                                          'Gagal mengirim ulang kode',
                                                    ),
                                                    backgroundColor: Colors
                                                        .redAccent
                                                        .shade700,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                      child: Text(
                                        _secondsRemaining > 0
                                            ? 'Kirim ulang kode (00:${_secondsRemaining.toString().padLeft(2, '0')})'
                                            : 'Kirim ulang kode sekarang',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _secondsRemaining > 0
                                              ? Colors.black38
                                              : const Color(0xFF1B4332),
                                          decoration: _secondsRemaining == 0
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Verify Button
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final authState = ref.watch(
                                          authProvider,
                                        );

                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF1B4332,
                                            ),
                                            minimumSize: const Size(
                                              double.infinity,
                                              56,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                              Icons
                                                                  .error_outline,
                                                              color:
                                                                  Colors.white,
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
                                                        behavior:
                                                            SnackBarBehavior
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
                                                      .read(
                                                        authProvider.notifier,
                                                      )
                                                      .verifyCode(code);

                                                  if (!context.mounted) return;

                                                  if (success) {
                                                    context.go('/dashboard');
                                                  } else {
                                                    final error = ref
                                                        .read(authProvider)
                                                        .error;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          error ??
                                                              'Verifikasi gagal',
                                                        ),
                                                        backgroundColor: Colors
                                                            .redAccent
                                                            .shade700,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: authState.isLoading
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Ganti Email Button
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
