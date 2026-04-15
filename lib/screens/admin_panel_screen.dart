import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentView = 0; // 0:Menu, 1:Verif, 2:Upload, 3:UserList, 4:PdfBank

  final FirebaseService _fs = FirebaseService();
  final SupabaseService _ss = SupabaseService();
  final TextEditingController _titleController = TextEditingController();
  final Set<String> _loadingApprovals = {};

  String _selectedRole = 'Rol 10';
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    String title = "ADMIN CENTER";
    if (_currentView == 1) title = "VERIFIKASI";
    if (_currentView == 2) title = "UPLOAD BARU";
    if (_currentView == 3) title = "DAFTAR USER";
    if (_currentView == 4) title = "BANK PDF";

    return PremiumScaffold(
      title: title,
      leading: _currentView != 0
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => setState(() => _currentView = 0),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case 1:
        return _buildVerificationList();
      case 2:
        return _buildUploadForm();
      case 3:
        return _buildUserManagement();
      case 4:
        return _buildPdfBank();
      case 5:
        return _buildVerseBank();
      default:
        return _buildMainMenu();
    }
  }

  Widget _buildMainMenu() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _menu(Icons.how_to_reg_rounded, "Verifikasi", Colors.orangeAccent, 1),
        _menu(Icons.people_alt_rounded, "User List", Colors.greenAccent, 3),
        _menu(Icons.auto_awesome, "Smart Parser\n(Verse)", Colors.blueAccent, 0, route: '/admin-upload'),
        _menu(Icons.upload_file_rounded, "Classic PDF\nUpload", Colors.lightBlue, 2),
        _menu(Icons.folder_special_rounded, "Bank Soal\nVerse", Colors.purpleAccent, 5),
        _menu(Icons.picture_as_pdf_rounded, "Bank Soal\nPDF", Colors.redAccent, 4),
      ],
    );
  }

  Widget _menu(IconData icon, String label, Color color, int view, {String? route}) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          setState(() => _currentView = view);
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(
            child: Text(
              "Antrean kosong.",
              style: TextStyle(color: Colors.white54),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final isApproving = _loadingApprovals.contains(id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        data['name'] ?? 'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        data['role'] ?? '-',
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                _launchWhatsApp(data['name'], data['whatsapp']),
                            child: const Text(
                              "Chat WA",
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isApproving
                                ? null
                                : () => _handleApprove(
                                    id,
                                    data['name'],
                                    data['whatsapp'],
                                  ),
                            child: const Text("Approve"),
                          ),
                        ),
                      ],
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

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Informasi Materi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GlassTextField(
              controller: _titleController,
              hintText: "Judul Materi (PDF)",
              prefixIcon: Icons.title_rounded,
            ),
            const SizedBox(height: 20),
            const Text(
              "Target Role:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF0D0F22),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: ['Rol 10', 'Rol 11', 'Rol 12']
                  .map((String v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 40),
            if (_isUploading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  "Pilih & Simpan PDF",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _pickAndUploadPdf,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var user = docs[index].data() as Map<String, dynamic>;
            bool isBlack = user['isBlacklisted'] ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(
                    user['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${user['role']} | ${user['whatsapp']}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isBlack
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isBlack ? Colors.redAccent : Colors.greenAccent,
                    ),
                    onPressed: () =>
                        _fs.toggleBlacklist(docs[index].id, !isBlack),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPdfBank() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getAllPdfsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var pdf = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    pdf['title'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    pdf['role'] ?? '',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white24,
                    ),
                    onPressed: () => _fs.deletePdf(docs[index].id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVerseBank() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getAllSmartMaterialsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var verse = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(
                    Icons.auto_awesome,
                    color: Colors.purpleAccent,
                  ),
                  title: Text(
                    "${verse['subject'] ?? 'Campuran'} - Soal ${verse['id'] ?? 0}",
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "${verse['role'] ?? '-'} | ${verse['class_group'] ?? '-'}",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white24,
                    ),
                    onPressed: () => _fs.deleteSmartMaterial(docs[index].id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleApprove(String docId, String name, String phone) async {
    setState(() => _loadingApprovals.add(docId));
    final code = await _fs.approveUser(docId);
    setState(() => _loadingApprovals.remove(docId));
    if (code != null && mounted) _showSuccessDialog(name, phone, code);
  }

  void _showSuccessDialog(String name, String phone, String code) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F22),
        title: const Text('Approved!', style: TextStyle(color: Colors.white)),
        content: Text(
          'Kode Akses $name: $code',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _launchWhatsApp(name, phone, code: code);
            },
            child: const Text("Kirim WA"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPdf() async {
    if (_titleController.text.isEmpty) return;
    fp.FilePickerResult? res = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (res != null) {
      setState(() => _isUploading = true);
      String? url = await _ss.uploadPdf(
        File(res.files.single.path!),
        res.files.single.name,
      );
      if (url != null) {
        await _fs.addPdfRecord(_titleController.text, _selectedRole, url);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Materi Berhasil Diupload!'),
            ),
          );
        _titleController.clear();
      }
      setState(() => _isUploading = false);
    }
  }

  Future<void> _launchWhatsApp(
    String name,
    String phone, {
    String? code,
  }) async {
    String formattedPhone = phone.startsWith('0')
        ? '62${phone.substring(1)}'
        : phone;
    String message = code != null
        ? "Halo $name, Kode Akses Veltrik Anda: *$code*"
        : "Halo $name, ada yang bisa Admin bantu?";
    final Uri url = Uri.parse(
      "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
