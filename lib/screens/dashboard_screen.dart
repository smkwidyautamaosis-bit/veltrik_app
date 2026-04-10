import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import 'pdf_viewer_screen.dart';
import 'admin_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _pdfsFuture;
  
  bool _isLoading = true;
  bool _isGuest = true;
  String _name = 'Guest';
  String _role = 'Guest';

  @override
  void initState() {
    super.initState();
    _resolveLoginState();
  }

  Future<void> _resolveLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessCode = prefs.getString('accessCode');

    if (accessCode != null && accessCode.isNotEmpty) {
      final userData = await _firebaseService.verifyAccessCode(accessCode);
      if (userData != null && (userData['isApproved'] ?? false)) {
        if (mounted) {
          setState(() {
            _name = userData['name'] ?? 'User';
            _role = userData['role'] ?? 'Unknown';
            _isGuest = false;
            _pdfsFuture = _firebaseService.getPdfsByRole(_role);
            _isLoading = false;
          });
        }
        return;
      }
    }
    
    // Fallback to Guest
    if (mounted) {
      setState(() {
        _isGuest = true;
        _name = 'Tamu';
        _role = 'Guest Catalog';
        _pdfsFuture = _firebaseService.getAllPdfs();
        _isLoading = false;
      });
    }
  }

  void _showPaywallModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Icon(Icons.lock_outline, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Materi Eksklusif',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan masuk dengan kode akses Anda untuk membuka kunci materi PDF ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Sudah Punya Kode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blueAccent),
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/role_selection');
                  },
                  child: const Text('Belum Punya Akses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veltrik Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isGuest && _role.toLowerCase() == 'admin')
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              },
            ),
          if (!_isGuest)
            IconButton(
               icon: const Icon(Icons.exit_to_app),
               tooltip: 'Keluar',
               onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.remove('accessCode');
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/welcome');
               },
            )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _isGuest ? _buildGuestBanner() : _buildWelcomeHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              _isGuest ? 'Katalog Materi Veltrik' : 'Dokumen Anda',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _buildPdfList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, $_name!', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
            ),
            child: Text(_role, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1c1b33), // Deep blue/Indigo 
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        border: Border(bottom: BorderSide(color: Colors.indigoAccent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.explore, color: Colors.indigoAccent, size: 28),
              SizedBox(width: 8),
              Text('Selamat Datang.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Eksplorasi etalase materi kami. Untuk membuka dokumen, Anda memerlukan kode akses eksklusif.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigoAccent,
                    side: const BorderSide(color: Colors.indigoAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/role_selection'),
                  child: const Text('Minta Akses', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPdfList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pdfsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan memuat data', style: TextStyle(color: Colors.redAccent)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                const Text('Tidak ada dokumen PDF tersedia saat ini.', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        final pdfs = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(24.0),
          itemCount: pdfs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final pdf = pdfs[index];
            return _buildPdfCard(
              title: pdf['title'] ?? 'Dokumen Tanpa Judul',
              url: pdf['url'] ?? '',
              roleTag: pdf['role'] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _buildPdfCard({required String title, required String url, required String roleTag}) {
    return InkWell(
      onTap: () {
        if (_isGuest) {
          _showPaywallModal(context);
        } else if (url.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PdfViewerScreen(title: title, url: url)),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isGuest ? Colors.grey.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_isGuest ? Icons.lock : Icons.picture_as_pdf, color: _isGuest ? Colors.grey : Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  if (_isGuest && roleTag.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Eksklusif $roleTag', style: const TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            Icon(_isGuest ? Icons.keyboard_arrow_right : Icons.download_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
