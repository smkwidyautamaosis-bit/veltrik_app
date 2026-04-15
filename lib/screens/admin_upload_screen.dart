import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_parser_service.dart';
import '../services/supabase_service.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/glass_card.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final PdfParserService _parserService = PdfParserService();
  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Map<String, dynamic>> _parsedMaterials = [];
  Map<String, dynamic> _parsedMetadata = {};
  
  bool _isParsing = false;
  bool _isUploading = false;
  String _previewFileName = "";
  String _selectedRole = 'Rol 10';

  bool get _isUploadValid {
    if (_parsedMaterials.isEmpty) return false;
    return !_parsedMaterials.any((m) => (m['correctAnswer']?.toString() ?? '').isEmpty);
  }

  Future<void> _pickAndParsePdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      setState(() {
        _isParsing = true;
        _previewFileName = result.files.single.name;
        _parsedMaterials = [];
        _parsedMetadata = {};
      });

      try {
        final Map<String, dynamic> parsedResult = await _parserService.parsePdfToSmartMaterials(file);
        
        setState(() {
          _parsedMetadata = parsedResult['metadata'] ?? {};
          _parsedMaterials = parsedResult['questions'] ?? [];
        });

        if (_parsedMaterials.isEmpty && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Gagal menemukan format soal di PDF ini.')),
           );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error parsing: $e')),
           );
        }
      } finally {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  Future<void> _pickImageForQuestion(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, // Sesuai kesepakatan: 60% compression agar ngebut!
    );
    
    if (image != null) {
      setState(() {
        _parsedMaterials[index]['imageFile'] = File(image.path);
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _parsedMaterials[index].remove('imageFile');
    });
  }

  Future<void> _uploadToFirestore() async {
    if (_parsedMaterials.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection('smart_materials');

      String subject = _parsedMetadata['subject'] ?? "Materi Campuran";
      String classGroup = _parsedMetadata['class_group'] ?? "Tidak Diketahui";

      // Lakukan loop secara sinkron berurutan (await) untuk proses Upload Gambar (jika ada) ke Supabase.
      for (int i = 0; i < _parsedMaterials.length; i++) {
        var material = _parsedMaterials[i];
        String? imageUrl;
        
        if (material['imageFile'] != null) {
           File imgFile = material['imageFile'];
           String imgName = "soal_${material['id']}.jpg";
           imageUrl = await _supabaseService.uploadImage(imgFile, imgName);
        }

        final docRef = collection.doc(); 
        
        // Buat salinan metadata upload
        Map<String, dynamic> docData = {
          'id': material['id'],
          'question': material['question'],
          'options': material['options'],
          'correctAnswer': material['correctAnswer'],
          'sourceFile': _previewFileName,
          'role': _selectedRole,
          'subject': subject,
          'class_group': classGroup,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (imageUrl != null) {
          docData['imageUrl'] = imageUrl;
        }

        batch.set(docRef, docData);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menyimpan materi ke Database!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _parsedMaterials.clear();
          _parsedMetadata.clear();
          _previewFileName = "";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal upload: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: "AUTO PARSER PDF",
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   const Text(
                    "Upload Materi (PDF)",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                     "Ubah PDF otomatis menjadi Smart Material interaktif.",
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _isParsing || _isUploading ? null : _pickAndParsePdf,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isParsing 
                              ? const SizedBox(
                                  width: 20, height: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            _isParsing ? "Memproses PDF..." : "Pilih & Parse PDF",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_previewFileName.isNotEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 24.0),
               child: Align(
                 alignment: Alignment.centerLeft,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       "Preview: $_previewFileName (${_parsedMaterials.length} Soal)",
                       style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       "Mata Pelajaran: ${_parsedMetadata['subject'] ?? '-'}",
                       style: const TextStyle(color: Colors.white70),
                     ),
                     Text(
                       "Kelas/Rombel: ${_parsedMetadata['class_group'] ?? '-'}",
                       style: const TextStyle(color: Colors.white70),
                     ),
                   ],
                 ),
               ),
             ),

          Expanded(
            child: _parsedMaterials.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada data untuk dipreview.",
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _parsedMaterials.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildPreviewCard(index, _parsedMaterials[index]),
                      );
                    },
                  ),
          ),
          
          if (_parsedMaterials.isNotEmpty)
             Padding(
               padding: const EdgeInsets.all(24.0),
               child: InkWell(
                  onTap: _isUploading || !_isUploadValid ? null : _uploadToFirestore,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: !_isUploadValid 
                            ? [Colors.grey.shade800, Colors.grey.shade900]
                            : [Colors.green.shade600, Colors.greenAccent.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         if (_isUploadValid)
                           BoxShadow(
                             color: Colors.greenAccent.withValues(alpha: 0.3),
                             blurRadius: 15,
                             offset: const Offset(0, 5),
                           ),
                      ],
                    ),
                    child: _isUploading
                        ? const Center(
                            child: SizedBox(
                                width: 22, height: 22, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                !_isUploadValid 
                                    ? "LENGKAPI KUNCI JAWABAN" 
                                    : "KIRIM KE FIRESTORE\n(Termasuk Gambar Soal)",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
               ),
             )
        ],
      ),
    );
  }

  Widget _buildPreviewCard(int index, Map<String, dynamic> data) {
    Map<String, String> ops = data['options'] as Map<String, String>;
    String cAnswer = data['correctAnswer'];
    File? imgFile = data['imageFile'];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Expanded(
                 child: Text(
                   "Soal ${data['id']}: ${data['question']}",
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 ),
               ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image Preview and Actions
          if (imgFile != null) ...[
             Stack(
               children: [
                 ClipRRect(
                   borderRadius: BorderRadius.circular(8),
                   child: Image.file(
                     imgFile,
                     height: 120,
                     width: double.infinity,
                     fit: BoxFit.cover,
                   ),
                 ),
                 Positioned(
                   top: 8,
                   right: 8,
                   child: InkWell(
                     onTap: () => _removeImage(index),
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: const BoxDecoration(
                         color: Colors.black54,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
          ] else ...[
             Align(
               alignment: Alignment.centerLeft,
               child: TextButton.icon(
                 onPressed: () => _pickImageForQuestion(index),
                 icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.cyanAccent, size: 20),
                 label: const Text("Add Image", style: TextStyle(color: Colors.cyanAccent)),
                 style: TextButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                   backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 ),
               ),
             ),
             const SizedBox(height: 12),
          ],

          ...ops.entries.map((e) {
            bool isBenar = (e.key == cAnswer);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${e.key}. ", style: TextStyle(color: isBenar ? Colors.greenAccent : Colors.white54, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(e.value, style: TextStyle(color: isBenar ? Colors.white : Colors.white54, fontSize: 13)),
                  ),
                  if (isBenar)
                    const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          if (cAnswer.isEmpty) ...[
             Container(
               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
               decoration: BoxDecoration(
                 color: Colors.redAccent.withValues(alpha: 0.2),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.redAccent),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: const [
                   Icon(Icons.warning_rounded, color: Colors.redAccent, size: 16),
                   SizedBox(width: 8),
                   Text(
                     "Kunci jawaban belum divalidasi!", 
                     style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
                   ),
                 ]
               ),
             ),
             const SizedBox(height: 12),
          ],
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
               children: ['A','B','C','D'].map((letter) {
                 bool isSelected = cAnswer == letter;
                 return Padding(
                   padding: const EdgeInsets.only(right: 8.0),
                   child: ChoiceChip(
                     label: Text(
                       letter, 
                       style: TextStyle(
                         color: isSelected ? Colors.black : Colors.greenAccent,
                         fontWeight: FontWeight.bold,
                       )
                     ),
                     selected: isSelected,
                     selectedColor: Colors.greenAccent,
                     backgroundColor: Colors.white.withValues(alpha: 0.05),
                     side: BorderSide(
                       color: isSelected ? Colors.greenAccent : Colors.white24,
                     ),
                     onSelected: (selected) {
                       if (selected) {
                         setState(() {
                           _parsedMaterials[index]['correctAnswer'] = letter;
                         });
                       } else if (!selected && isSelected) {
                         // Izinkan membatalkan kunci (menghilangkan)
                         setState(() {
                           _parsedMaterials[index]['correctAnswer'] = '';
                         });
                       }
                     },
                   ),
                 );
               }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
