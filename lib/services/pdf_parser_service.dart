import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfParserService {
  /// Membaca file PDF dan mengembalikan Map data berisi 'metadata' dan 'questions'
  Future<Map<String, dynamic>> parsePdfToSmartMaterials(File file) async {
    final bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final String text = PdfTextExtractor(document).extractText();
    document.dispose();

    return _extractToMap(text);
  }

  Map<String, dynamic> _extractToMap(String rawText) {
    String normalizedText = rawText.replaceAll('\r\n', '\n');

    // Ekstrak Metadata (Mata Pelajaran dan Kelas - Rombel)
    String subjectText = "Materi Campuran";
    String classGroupText = "Tidak Diketahui";

    // Toleransi spasial yang baik: Mata Pelajaran : [nama]
    final subjectMatch = RegExp(r'Mata\s*Pelajaran\s*(?::|-)?\s*(.+)', caseSensitive: false).firstMatch(normalizedText);
    if (subjectMatch != null) {
      subjectText = subjectMatch.group(1)?.trim() ?? subjectText;
    }

    final classMatch = RegExp(r'Kelas.*?Rombel\s*(?::|-)?\s*(.+)', caseSensitive: false).firstMatch(normalizedText);
    if (classMatch != null) {
      classGroupText = classMatch.group(1)?.trim() ?? classGroupText;
    }

    List<Map<String, dynamic>> questionsList = [];
    final chunks = normalizedText.split(RegExp(r'(?:^|\n)\s*(?=\d+\.\s)'));
    final optionPattern = RegExp(r'(?:^|\n)\s*([✓*]?)\s*([A-D])\.\s+([^\n]+)', caseSensitive: false);

    for (String chunk in chunks) {
      if (chunk.trim().isEmpty) continue;

      final qMatch = RegExp(r'^\s*(\d+)\.\s+([\s\S]+?)(?=\n\s*[✓*]?\s*[A-D]\.)', caseSensitive: false).firstMatch(chunk);
      if (qMatch == null) continue;

      int id = int.tryParse(qMatch.group(1) ?? '0') ?? 0;
      String questionText = qMatch.group(2)?.trim() ?? '';
      
      questionText = questionText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

      Map<String, String> options = {};
      String correctAnswer = '';
      
      final optMatches = optionPattern.allMatches(chunk);
      for (var m in optMatches) {
        String check = m.group(1)?.trim() ?? '';
        String letter = m.group(2)?.toUpperCase() ?? '';
        String optText = m.group(3)?.trim() ?? '';

        if (check.contains('✓') || check.contains('*') || optText.contains('✓')) {
           correctAnswer = letter;
           optText = optText.replaceAll('✓', '').replaceAll('*', '').trim();
        }
        options[letter] = optText;
      }

      if (options.isNotEmpty) {
        questionsList.add({
          "id": id,
          "question": questionText,
          "options": options,
          "correctAnswer": correctAnswer,
        });
      }
    }
    
    return {
      "metadata": {
        "subject": subjectText,
        "class_group": classGroupText,
      },
      "questions": questionsList,
    };
  }
}
