import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- MANAJEMEN USER ---
  // Menampilkan user yang MENUNGGU verifikasi
  Stream<QuerySnapshot> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .snapshots();
  }

  // Menampilkan SEMUA user untuk daftar blacklist
  Stream<QuerySnapshot> getAllUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> toggleBlacklist(String docId, bool status) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'isBlacklisted': status,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- MANAJEMEN PDF ---
  Stream<QuerySnapshot> getAllPdfsStream() {
    return _firestore
        .collection('pdfs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> deletePdf(String docId) async {
    try {
      await _firestore.collection('pdfs').doc(docId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- FUNGSI AUTH & STATUS ---
  Stream<DocumentSnapshot> streamUserStatus(String docId) {
    return _firestore.collection('users').doc(docId).snapshots();
  }

  Future<Map<String, dynamic>?> verifyAccessCode(String code) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('accessCode', isEqualTo: code)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPdfsByRole(String role) async {
    try {
      QuerySnapshot q = await _firestore
          .collection('pdfs')
          .where('role', isEqualTo: role)
          .get();
      return q.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllPdfs() async {
    try {
      QuerySnapshot q = await _firestore.collection('pdfs').get();
      return q.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> approveUser(String documentId) async {
    try {
      String newCode = "VTK-${Random().nextInt(9000) + 1000}";
      await _firestore.collection('users').doc(documentId).update({
        'isApproved': true,
        'status': 'approved',
        'accessCode': newCode,
      });
      return newCode;
    } catch (e) {
      return null;
    }
  }

  Future<String?> submitRegistration(
    String name,
    String phone,
    String role,
  ) async {
    try {
      DocumentReference doc = await _firestore.collection('users').add({
        'name': name,
        'whatsapp': phone,
        'role': role,
        'isApproved': false,
        'isBlacklisted': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'accessCode': '',
      });
      return doc.id;
    } catch (e) {
      return null;
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
      return false;
    }
  }
}
