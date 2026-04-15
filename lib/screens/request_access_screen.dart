import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan Kode Akses Anda')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userData = await _firebaseService.verifyAccessCode(code);

    if (userData != null) {
      bool isApproved = userData['isApproved'] ?? false;

      if (isApproved) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        // Simpan sesuai format DashboardScreen agar berjalan lancar
        await prefs.setString('accessCode', code); 
        // Simpan sesuai request kamu
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', userData['role'] ?? 'Guest');

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Anda belum disetujui Admin')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode Akses tidak valid atau belum terdaftar')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
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
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              GlassCard(
                child: Column(
                  children: [
                    GlassTextField(
                      controller: _codeController,
                      hintText: 'Format: VTK-XXXX',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
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
                                Colors.blueAccent.withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.3),
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
                                  'MASUK KE VELTRIK',
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
