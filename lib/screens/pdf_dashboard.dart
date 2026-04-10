import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfDashboardScreen extends StatelessWidget {
  const PdfDashboardScreen({super.key});

  // Example dummy PDF URL
  final String pdfUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E), // Dark app bar
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
