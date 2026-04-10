import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              const Text(
                'Selamat Datang di Veltrik',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              _buildBigButton(
                context,
                title: 'Saya Sudah Punya Akses',
                icon: Icons.login,
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
              const SizedBox(height: 16),
              _buildBigButton(
                context,
                title: 'Saya Belum Punya Akses',
                icon: Icons.app_registration,
                isSecondary: true,
                onPressed: () {
                  Navigator.pushNamed(context, '/role_selection');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onPressed, bool isSecondary = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? const Color(0xFF1E1E1E) : Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isSecondary ? 0 : 4,
        side: isSecondary ? const BorderSide(color: Colors.white24, width: 1) : BorderSide.none,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
