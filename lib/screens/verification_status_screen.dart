import 'package:flutter/material.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      // Kita tidak pakai title di AppBar agar kesan "Menunggu" lebih fokus
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ilustrasi Jam Pasir / Loading dengan Glow
              GlassCard(
                borderRadius: 100,
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: const Icon(
                        Icons.hourglass_empty_rounded,
                        size: 80,
                        color: Colors.blueAccent,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),

              // Status Header
              const Text(
                'Menunggu Verifikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Status Detail dalam GlassCard
              GlassCard(
                child: Column(
                  children: [
                    Text(
                      'Permintaan akses Anda sedang ditinjau oleh tim Admin Veltrik.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Biasanya proses ini memakan waktu kurang dari 24 jam. Kami akan segera mengaktifkan akun Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Button Logout / Kembali ke Welcome
              SizedBox(
                width: 200,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/welcome'),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
