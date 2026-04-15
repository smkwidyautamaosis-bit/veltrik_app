import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;
  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _submitData() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty)
      return;

    setState(() => _isLoading = true);
    String? docId = await _firebaseService.submitRegistration(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      widget.role,
    );

    if (docId != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingDocId', docId); // Simpan ID untuk Dashboard
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'REGISTRASI ${widget.role.toUpperCase()}',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GlassTextField(
              controller: _nameController,
              hintText: 'Nama Lengkap',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _phoneController,
              hintText: 'Nomor WA',
              prefixIcon: Icons.phone_android,
            ),
            const SizedBox(height: 32),
            GlassCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/qris_payment.png',
                      height: 180,
                      width: 180,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.qr_code_2_rounded,
                        size: 180,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _btn(
                    title: 'Konfirmasi via WhatsApp',
                    icon: Icons.chat,
                    color: Colors.green,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _btn(
                    title: _isLoading
                        ? 'Memproses...'
                        : 'Saya Sudah Bayar & Daftar',
                    icon: Icons.check,
                    color: Colors.blueAccent,
                    onTap: _submitData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
