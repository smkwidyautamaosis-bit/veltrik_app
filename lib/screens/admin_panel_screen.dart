import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final SupabaseService _supabaseService = SupabaseService();
  final Set<String> _loadingApprovals = {};

  final TextEditingController _titleController = TextEditingController();
  String _selectedRole = 'Rol 10';
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _approveUser(String docId) async {
    setState(() {
      _loadingApprovals.add(docId);
    });

    final success = await _firebaseService.approveUser(docId);
    
    if (mounted) {
      setState(() {
         _loadingApprovals.remove(docId);
      });
      if (success) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User berhasil diapprove!')));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal melakukan approve.')));
      }
    }
  }

  Future<void> _launchWhatsApp(String name, String phone) async {
    final msg = "Halo $name, saya admin Veltrik. Bisa kirimkan bukti pembayarannya?";
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    
    final Uri url = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(msg)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka WhatsApp')));
      }
    }
  }

  Future<void> _pickAndUploadPdf() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul materi harus diisi')));
      return;
    }

    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        
        int sizeInBytes = file.lengthSync();
        if (sizeInBytes > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran file maksimal 5MB')));
          }
          return;
        }

        setState(() {
          _isUploading = true;
          _uploadProgress = 0.1;
        });

        String titleStr = _titleController.text.trim();
        String roleStr = _selectedRole;

        String? publicUrl = await _supabaseService.uploadPdf(file, result.files.single.name);
        
        setState(() {
          _uploadProgress = 0.8;
        });

        if (publicUrl != null) {
          bool dbOk = await _firebaseService.addPdfRecord(titleStr, roleStr, publicUrl);
          if (dbOk) {
            setState(() {
              _uploadProgress = 1.0;
              _titleController.clear();
              _selectedRole = 'Rol 10';
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File PDF berhasil di-upload!')));
            }
          } else {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan record di database')));
          }
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal upload ke server')));
        }
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Widget _buildUploadForm() {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.blueAccent, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tambah Materi Baru', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Judul Materi',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: ['Rol 10', 'Rol 11', 'Rol 12'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress, color: Colors.blueAccent),
                  const SizedBox(height: 8),
                  Text('Mengupload... ${(_uploadProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
                ]
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Pilih & Upload PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _pickAndUploadPdf,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
      ),
      body: Column(
        children: [
          _buildUploadForm(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getPendingUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                }
                if (snapshot.hasError) {
                   return const Center(child: Text('Terjadi kesalahan memuat data', style: TextStyle(color: Colors.white)));
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.6)),
                         const SizedBox(height: 16),
                         const Text(
                           'Semua aman, Bos!\nTidak ada antrean verifikasi.',
                           textAlign: TextAlign.center,
                           style: TextStyle(color: Colors.white70, fontSize: 18),
                         ),
                       ],
                     ),
                   );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final name = data['name'] ?? 'No Name';
                    final role = data['role'] ?? 'Unknown';
                    final whatsapp = data['whatsapp'] ?? '-';
                    
                    Timestamp? ts = data['createdAt'] as Timestamp?;
                    String timeStr = ts != null ? _formatTimestamp(ts.toDate()) : 'Waktu tidak tersedia';
                    
                    final isApproving = _loadingApprovals.contains(doc.id);

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))
                                  ),
                                  child: Text(role, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone_android, size: 16, color: Colors.white54),
                                const SizedBox(width: 8),
                                Text(whatsapp, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.white54),
                                const SizedBox(width: 8),
                                Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('Chat WA'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _launchWhatsApp(name, whatsapp),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: isApproving 
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : const Icon(Icons.check, size: 18),
                                    label: Text(isApproving ? 'Proses...' : 'Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: isApproving ? null : () => _approveUser(doc.id),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
     return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
