import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _showPayment = false;
  int _uniqueCode = 0;
  String _referenceId = '';

  void _proceedToPayment() {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Nomor WA harus diisi')),
      );
      return;
    }

    setState(() {
      _uniqueCode = Random().nextInt(900) + 100;
      _referenceId = 'VTK-${Random().nextInt(9000) + 1000}';
      _showPayment = true;
    });
  }

  Future<void> _submitData() async {
    setState(() {
      _isLoading = true;
    });
    
    String? docId = await _firebaseService.submitRegistrationWithSecurity(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      widget.role,
      _uniqueCode,
      _referenceId,
    );

    if (docId != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingDocId', docId); // Simpan ID untuk Dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan, silakan coba lagi')),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'REGISTRASI ${widget.role.toUpperCase()}',
      leading: _showPayment 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showPayment = false;
                });
              },
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _showPayment ? _buildPaymentStep() : _buildDataStep(),
      ),
    );
  }

  Widget _buildDataStep() {
    return Column(
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
        _btn(
          title: 'Lanjut',
          icon: Icons.arrow_forward,
          color: Colors.blueAccent,
          onTap: _proceedToPayment,
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final int nominal = 50000 + _uniqueCode;
    
    return GlassCard(
      child: Column(
        children: [
          const Text(
            'Transfer Pembayaran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/qris_payment.png',
                height: 180,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.qr_code_2_rounded,
                  size: 180,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nominal: Rp $nominal',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reference ID: $_referenceId',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          _btn(
            title: _isLoading ? 'Memproses...' : 'SAYA SUDAH BAYAR',
            icon: Icons.check,
            color: Colors.blueAccent,
            onTap: _isLoading ? null : _submitData,
          ),
        ],
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
          color: color.withValues(alpha: 0.2), // Updated to Flutter 3.33 standards
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
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
