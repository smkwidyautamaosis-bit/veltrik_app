import 'package:flutter/material.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';
import 'registration_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'PILIH ROLE',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'Identifikasi Diri Anda',
              style: TextStyle(
                color: Colors.blueAccent.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan pilih tipe akses yang sesuai dengan tingkat pendidikan atau jabatan Anda saat ini.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Daftar Role dengan GlassCard
            _buildRoleCard(
              context,
              role: 'Rol 10',
              description: 'Akses dasar untuk kurikulum tingkat 10',
              icon: Icons.filter_1_rounded,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              role: 'Rol 11',
              description: 'Akses menengah untuk kurikulum tingkat 11',
              icon: Icons.filter_2_rounded,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              role: 'Rol 12',
              description: 'Akses penuh untuk kurikulum tingkat 12',
              icon: Icons.filter_3_rounded,
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Veltrik Security System v2.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String role,
    required String description,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationScreen(role: role),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Icon dengan Glow tipis
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
