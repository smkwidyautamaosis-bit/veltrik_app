import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String url;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String _watermarkText = 'Veltrik User';

  @override
  void initState() {
    super.initState();
    _initSecurity();
  }

  Future<void> _initSecurity() async {
    // Aktifkan anti-screenshot & screen record
    await ScreenProtector.preventScreenshotOn();
    
    // Ambil data untuk watermark
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessCode = prefs.getString('accessCode');
    if (accessCode != null && accessCode.isNotEmpty) {
      if (mounted) {
        setState(() {
          _watermarkText = accessCode;
        });
      }
    }
  }

  @override
  void dispose() {
    // Matikan proteksi saat keluar halaman untuk mengembalikan HP ke mode normal
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F22), // Gen-Z Dark Theme Color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. PDF Viewer with Rounded Premium Corners
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: SfPdfViewer.network(
              widget.url,
              canShowScrollHead: false,
              canShowScrollStatus: false,
            ),
          ),
          
          // 2. Transparan Watermark Layer (IgnorePointer mencegah interaksi blokir scroll)
          IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 30, // Cukup untuk memenuhi layar HP
                  itemBuilder: (context, index) {
                    return Transform.rotate(
                      angle: -pi / 6, // Miring secara estetik
                      child: Center(
                        child: Text(
                          _watermarkText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            // Transparansi minimalis modern .withValues
                            color: Colors.grey.withValues(alpha: 0.2), 
                          ),
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
}
