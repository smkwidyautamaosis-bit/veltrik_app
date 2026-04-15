import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';

class SmartMaterialScreen extends StatefulWidget {
  final String subject;

  const SmartMaterialScreen({super.key, required this.subject});

  @override
  State<SmartMaterialScreen> createState() => _SmartMaterialScreenState();
}

class _SmartMaterialScreenState extends State<SmartMaterialScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _userRole = "";

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? 'Guest';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: widget.subject.toUpperCase(),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // Search Bar Interaktif
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05), // Sesuai standar v3.33
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari soal, jawaban, atau kata kunci...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.blueAccent.withValues(alpha: 0.8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
          ),

          // Real-Time Data Fetching dengan StreamBuilder
          Expanded(
            child: _userRole.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('smart_materials')
                        .where('role', isEqualTo: _userRole) 
                        .where('subject', isEqualTo: widget.subject) 
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Gagal memuat materi: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada materi untuk kelas Anda.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      // Menerjemahkan dan mapping data dari Firestore
                      List<Map<String, dynamic>> allData = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                      
                      // Mengurutkan nomor soal (id) agar berurutan secara logis
                      allData.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));

                      // Menyelipkan logic Sinkronisasi Fitur Search Bar
                      List<Map<String, dynamic>> filteredData = allData.where((item) {
                        if (_searchQuery.isEmpty) return true;
                        
                        final qMatches = item['question'].toString().toLowerCase().contains(_searchQuery);
                        bool optionMatches = false;
                        if (item['options'] != null) {
                          final options = Map<String, dynamic>.from(item['options']);
                          // Filter berdasarkan kunci jawaban Pilihan Ganda (A-D)
                          optionMatches = options.values.any((val) => val.toString().toLowerCase().contains(_searchQuery));
                        }

                        return qMatches || optionMatches;
                      }).toList();

                      // Jika daftar menjadi kosong setelah filter search diisi
                      if (filteredData.isEmpty && _searchQuery.isNotEmpty) {
                         return const Center(
                           child: Text(
                             'Materi tidak ditemukan sesuai kata kunci.',
                             style: TextStyle(color: Colors.white54),
                           ),
                         );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildQuizCard(filteredData[index]),
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

  // Tampilan Card ala Gen-Z dengan Glassmorphism
  Widget _buildQuizCard(Map<String, dynamic> data) {
    final options = Map<String, dynamic>.from(data['options'] ?? {});
    final correct = data['correctAnswer'];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nomor Soal + Pertanyaan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data['id'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['question'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
             const SizedBox(height: 16),
             ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: CachedNetworkImage(
                 imageUrl: data['imageUrl'],
                 width: double.infinity,
                 fit: BoxFit.cover,
                 placeholder: (context, url) => Container(
                   height: 150,
                   color: Colors.white.withValues(alpha: 0.05),
                   child: const Center(
                     child: CircularProgressIndicator(color: Colors.cyanAccent),
                   ),
                 ),
                 errorWidget: (context, url, error) => Container(
                   height: 100,
                   color: Colors.white.withValues(alpha: 0.05),
                   child: const Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.broken_image_rounded, color: Colors.white54, size: 30),
                       SizedBox(height: 8),
                       Text("Gagal memuat gambar", style: TextStyle(color: Colors.white54, fontSize: 12)),
                     ],
                   ),
                 ),
               ),
             ),
          ],
          
          const SizedBox(height: 16),
          
          // List Pilihan Jawaban
          ...options.entries.map((entry) {
            final isCorrect = entry.key == correct;
            return Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? Colors.greenAccent.withValues(alpha: 0.1) 
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect 
                      ? Colors.greenAccent.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${entry.key}.',
                    style: TextStyle(
                      color: isCorrect ? Colors.greenAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        color: isCorrect ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
