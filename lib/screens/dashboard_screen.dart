import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';
import 'admin_panel_screen.dart';
import 'pdf_viewer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _fs = FirebaseService();
  Future<List<Map<String, dynamic>>>? _pdfsFuture;

  String? _accessCode;
  String? _pendingId;
  String _name = 'User';
  String _role = 'Guest';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    SharedPreferences p = await SharedPreferences.getInstance();

    // Ambil data session dari memori HP
    _accessCode = p.getString('accessCode');
    _pendingId = p.getString('pendingDocId');

    if (_accessCode != null) {
      final u = await _fs.verifyAccessCode(_accessCode!);

      if (u != null) {
        // --- PROTEKSI BLACKLIST ---
        if (u['isBlacklisted'] == true) {
          await p.clear(); // Hapus session di HP
          if (mounted) {
            _showBlacklistDialog();
            Navigator.pushReplacementNamed(context, '/welcome');
          }
          return;
        }

        setState(() {
          _name = u['name'] ?? 'User';
          _role = u['role'] ?? 'Unknown';
          // Load PDF hanya untuk siswa (bukan Admin)
          if (_role.toLowerCase() != 'admin') {
            _pdfsFuture = _fs.getPdfsByRole(_role);
          }
        });
      }
    }

    setState(() => _isLoading = false);
  }

  void _showBlacklistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Akses Ditolak",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Akun Anda telah dinonaktifkan oleh Admin karena melanggar peraturan Veltrik.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const PremiumScaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );

    // 1. JIKA ADMIN -> LANGSUNG KE ADMIN CENTER
    if (_role.toLowerCase() == 'admin') {
      return const AdminPanelScreen();
    }

    // 2. JIKA USER AKTIF -> KE PERPUSTAKAAN PDF
    if (_accessCode != null) return _buildLibrary();

    // 3. JIKA BARU DAFTAR -> KE STATUS VERIFIKASI
    if (_pendingId != null) return _buildPendingStatus();

    // 4. JIKA TAMU -> KE GUEST MODE
    return _buildGuestView();
  }

  // ==========================================
  // VIEW: PERPUSTAKAAN SISWA (ROL 10/11/12)
  // ==========================================
  Widget _buildLibrary() {
    return PremiumScaffold(
      title: 'VELTRIK HUB',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: _logout,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUserHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              'Materi Belajar Anda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildPdfGrid()),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.blueAccent,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Siswa $_role',
                  style: TextStyle(
                    color: Colors.blueAccent.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pdfsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final pdfs = snapshot.data ?? [];

        if (pdfs.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada materi untuk kelas Anda.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: pdfs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pdf = pdfs[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      title: pdf['title'] ?? 'PDF',
                      url: pdf['url'] ?? '',
                    ),
                  ),
                );
              },
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        pdf['title'] ?? 'Materi Tanpa Judul',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white24,
                      size: 14,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW: STATUS TUNGGU (AUTO-MAGIC UPDATE)
  // ==========================================
  Widget _buildPendingStatus() {
    return PremiumScaffold(
      title: 'STATUS VERIFIKASI',
      body: StreamBuilder<DocumentSnapshot>(
        stream: _fs.streamUserStatus(_pendingId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          bool approved = data['isApproved'] ?? false;
          String code = data['accessCode'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      Icon(
                        approved
                            ? Icons.verified_user_rounded
                            : Icons.hourglass_empty,
                        size: 80,
                        color: approved
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        approved ? 'Akses Terbuka!' : 'Sedang Diverifikasi',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        approved
                            ? 'Salin kode akses di bawah ini untuk login.'
                            : 'Admin sedang mengecek pembayaran Anda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                if (approved) ...[
                  const SizedBox(height: 32),
                  const Text(
                    "KODE AKSES ANDA:",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      'Ke Halaman Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                TextButton(
                  onPressed: _logout,
                  child: const Text(
                    'Batalkan & Keluar',
                    style: TextStyle(color: Colors.white24),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // VIEW: GUEST MODE
  // ==========================================
  Widget _buildGuestView() {
    return PremiumScaffold(
      title: 'VELTRIK GUEST',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 100,
                color: Colors.white10,
              ),
              const SizedBox(height: 24),
              const Text(
                "Akses Terbatas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Silakan masuk menggunakan kode akses atau lakukan pendaftaran materi baru.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(200, 50),
                ),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/welcome'),
                child: const Text("Kembali ke Awal"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() async {
    SharedPreferences p = await SharedPreferences.getInstance();
    await p.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
  }
}
