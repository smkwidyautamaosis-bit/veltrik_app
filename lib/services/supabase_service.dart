import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // TODO: Isi variabel di bawah ini dengan kredensial project Supabase Anda

  static const String supabaseUrl = 'https://tafcmbhlghwkjnkkrjni.supabase.co';

  static const String supabaseAnonKey =
      'sb_publishable_rSILXIv63GRGLy53egHx-A_rxj0DEWe';

  Future<String?> uploadPdf(File file, String fileName) async {
    try {
      final String filePath =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await Supabase.instance.client.storage
          .from('pdfs')
          .upload(filePath, file);

      final String publicUrl = Supabase.instance.client.storage
          .from('pdfs')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Supabase upload error: $e');

      return null;
    }
  }
}
