import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> verifyAccessCode(String code) async {
    try {
      print('Mencari di users untuk kode: $code');
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('accessCode', isEqualTo: code)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Terjadi error koneksi / verifikasi: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPdfsByRole(String role) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('pdfs')
          .where('role', isEqualTo: role)
          .get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getPdfsByRole: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllPdfs() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('pdfs').get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getAllPdfs: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .snapshots();
  }

  Future<bool> approveUser(String documentId) async {
    try {
      await _firestore.collection('users').doc(documentId).update({
        'isApproved': true,
        'status': 'approved',
      });
      return true;
    } catch (e) {
      print('Error approveUser: $e');
      return false;
    }
  }

  Future<bool> submitRegistration(
    String name,
    String phone,
    String role,
  ) async {
    try {
      await _firestore.collection('users').add({
        'name': name,
        'whatsapp': phone,
        'role': role,
        'isApproved': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Terjadi error registrasi: $e');
      return false;
    }
  }

  Future<bool> addPdfRecord(String title, String role, String url) async {
    try {
      await _firestore.collection('pdfs').add({
        'title': title,
        'role': role,
        'url': url,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Firebase addPdf error: $e');
      return false;
    }
  }
}
