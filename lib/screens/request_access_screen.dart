import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import 'dashboard_screen.dart';
import 'verification_status_screen.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan Access Code Anda';
        _isLoading = false;
      });
      return;
    }

    final userData = await _firebaseService.verifyAccessCode(code);

    setState(() {
      _isLoading = false;
    });

    if (userData != null) {
      if (!mounted) return;
      bool isApproved = userData['isApproved'] ?? false;

      if (isApproved) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessCode', code);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificationStatusScreen(),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Access Code tidak valid atau belum terdaftar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      // Kita tambahkan tombol kembali agar user bisa balik ke Welcome Screen
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Branding yang Pop-Up
              GlassCard(
                borderRadius: 100,
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                  width: 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.vpn_key_rounded,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Otentikasi Akses',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan Access Code khusus Anda untuk melanjutkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

              // Form dalam GlassCard
              GlassCard(
                child: Column(
                  children: [
                    GlassTextField(
                      controller: _codeController,
                      hintText: 'Access Code',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Button Login Premium
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: _isLoading ? null : _verifyCode,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent,
                                Colors.blueAccent.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Verifikasi Akses',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }
}
